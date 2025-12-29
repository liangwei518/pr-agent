#!/bin/bash

# PR-Agent GitLab Webhook 健康检查脚本
# 使用方法: ./health-check.sh

# 获取主机IP (兼容 macOS 和 Linux)
get_host_ip() {
    local ip=""
    
    # 方法1: 使用 ifconfig (macOS/Linux通用)
    if command -v ifconfig >/dev/null 2>&1; then
        ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | sed 's/addr://')
    fi
    
    # 方法2: 使用 ip 命令 (Linux)
    if [ -z "$ip" ] && command -v ip >/dev/null 2>&1; then
        ip=$(ip route get 1 2>/dev/null | awk '{print $NF; exit}')
    fi
    
    # 方法3: 使用 hostname -I (Linux)
    if [ -z "$ip" ] && hostname -I >/dev/null 2>&1; then
        ip=$(hostname -I | awk '{print $1}')
    fi
    
    # 方法4: 使用网络连接测试
    if [ -z "$ip" ]; then
        ip=$(python3 -c "import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(('8.8.8.8', 80)); print(s.getsockname()[0]); s.close()" 2>/dev/null || echo "")
    fi
    
    # 如果都失败了，使用 localhost
    if [ -z "$ip" ]; then
        ip="localhost"
    fi
    
    echo "$ip"
}

HOST_IP=$(get_host_ip)
WEBHOOK_URL="http://$HOST_IP:3000"
LOG_FILE="./logs/health-check.log"

# 创建日志目录
mkdir -p logs

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_service() {
    echo -e "${YELLOW}🔍 检查服务状态...${NC}"
    
    # 检查容器是否运行
    if ! docker ps | grep -q "pr-agent-gitlab-webhook"; then
        echo -e "${RED}❌ 容器未运行${NC}"
        return 1
    fi
    
    # 检查HTTP响应
    if curl -s -f "$WEBHOOK_URL/" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 服务正常运行${NC}"
        log_message "服务健康检查通过"
        return 0
    else
        echo -e "${RED}❌ 服务无响应${NC}"
        log_message "服务健康检查失败"
        return 1
    fi
}

show_service_info() {
    echo ""
    echo -e "${YELLOW}📋 服务信息:${NC}"
    echo "   访问地址: $WEBHOOK_URL"
    echo "   Webhook:  $WEBHOOK_URL/webhook"
    echo ""
    
    echo -e "${YELLOW}📊 容器状态:${NC}"
    docker ps --filter "name=pr-agent-gitlab-webhook" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo -e "${YELLOW}📈 资源使用:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" pr-agent-gitlab-webhook 2>/dev/null || echo "无法获取资源信息"
}

test_webhook() {
    echo -e "${YELLOW}🧪 测试 Webhook 端点...${NC}"
    
    RESPONSE=$(curl -s -w "%{http_code}" -X POST "$WEBHOOK_URL/webhook" \
        -H "Content-Type: application/json" \
        -H "X-Gitlab-Token: test" \
        -d '{"object_kind": "test"}' 2>/dev/null || echo "000")
    
    if [[ "$RESPONSE" == *"401"* ]]; then
        echo -e "${GREEN}✅ Webhook 端点正常 (401 Unauthorized - 预期响应)${NC}"
    elif [[ "$RESPONSE" == *"200"* ]]; then
        echo -e "${GREEN}✅ Webhook 端点正常 (200 OK)${NC}"
    else
        echo -e "${RED}❌ Webhook 端点异常 (响应码: $RESPONSE)${NC}"
    fi
}

# 主逻辑
case "${1:-check}" in
    "check")
        check_service
        ;;
    "info")
        show_service_info
        ;;
    "test")
        test_webhook
        ;;
    "full")
        check_service
        show_service_info
        test_webhook
        ;;
    "monitor")
        echo -e "${YELLOW}🔄 开始持续监控 (按 Ctrl+C 停止)...${NC}"
        while true; do
            if check_service; then
                sleep 60
            else
                echo -e "${YELLOW}🔄 尝试重启服务...${NC}"
                docker-compose restart gitlab-webhook
                sleep 30
            fi
        done
        ;;
    *)
        echo "使用方法: $0 [check|info|test|full|monitor]"
        echo "  check   - 检查服务状态 (默认)"
        echo "  info    - 显示服务信息"
        echo "  test    - 测试 webhook 端点"
        echo "  full    - 完整检查"
        echo "  monitor - 持续监控并自动重启"
        exit 1
        ;;
esac 