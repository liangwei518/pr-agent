#!/bin/bash

# PR-Agent GitLab Webhook 启动脚本
# 使用方法: ./start.sh

set -e

echo "🚀 启动 PR-Agent GitLab Webhook 服务..."

# 检查必要文件
if [ ! -f ".env" ]; then
    echo "❌ 错误: .env 文件不存在!"
    echo "请先配置 .env 文件中的必要参数。"
    exit 1
fi

# 检查镜像是否存在
if ! docker image inspect pg-llms-gitlab-webhook:latest >/dev/null 2>&1; then
    echo "❌ 错误: 镜像 pg-llms-gitlab-webhook:latest 不存在!"
    echo "请先构建镜像: docker build --target gitlab_webhook -f docker/Dockerfile -t pg-llms-gitlab-webhook:latest ."
    exit 1
fi

# 创建必要的目录
mkdir -p logs config

# 停止现有容器（如果存在）
echo "🛑 停止现有容器..."
docker-compose down 2>/dev/null || true

# 启动服务
echo "▶️  启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
if docker-compose ps | grep -q "Up"; then
    echo "✅ 服务启动成功!"
    
    # 获取容器IP
    CONTAINER_IP=$(docker inspect pr-agent-gitlab-webhook | grep -E '"IPAddress"' | head -1 | sed 's/.*"IPAddress": "\([^"]*\)".*/\1/')
    
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
    
    echo ""
    echo "📋 服务信息:"
    echo "   容器名称: pr-agent-gitlab-webhook"
    echo "   容器IP:   $CONTAINER_IP"
    echo "   主机IP:   $HOST_IP"
    echo "   访问地址: http://$HOST_IP:3000"
    echo "   Webhook:  http://$HOST_IP:3000/webhook"
    echo ""
    echo "📝 配置 GitLab Webhook:"
    echo "   1. 进入 GitLab 项目设置 → Webhooks"
    echo "   2. URL: http://$HOST_IP:3000/webhook"
    echo "   3. Secret Token: (使用 .env 中的 GITLAB__SHARED_SECRET)"
    echo "   4. 触发器: Push events, Merge request events, Comments"
    echo ""
    echo "🔍 查看日志: docker-compose logs -f gitlab-webhook"
    echo "🛑 停止服务: ./stop.sh"
else
    echo "❌ 服务启动失败!"
    echo "查看错误日志: docker-compose logs gitlab-webhook"
    exit 1
fi 