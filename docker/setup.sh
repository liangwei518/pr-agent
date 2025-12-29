#!/bin/bash

# PR-Agent GitLab Webhook 快速设置脚本
# 使用方法: ./setup.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛠️  PR-Agent GitLab Webhook 快速设置${NC}"
echo "=============================================="

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装，请先安装 Docker${NC}"
    exit 1
fi

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose 未安装，请先安装 Docker Compose${NC}"
    exit 1
fi

# 检查镜像
if ! docker image inspect pg-llms-gitlab-webhook:latest >/dev/null 2>&1; then
    echo -e "${RED}❌ 镜像 pg-llms-gitlab-webhook:latest 不存在${NC}"
    echo -e "${YELLOW}请先构建镜像:${NC}"
    echo "docker build --target gitlab_webhook -f docker/Dockerfile -t pg-llms-gitlab-webhook:latest ."
    exit 1
fi

echo -e "${GREEN}✅ 前置检查通过${NC}"
echo ""
# 创建 .env 文件
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env 文件已存在${NC}"
    read -p "是否要重新配置? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "跳过配置，使用现有 .env 文件"
        exit 0
    fi
fi

echo -e "${BLUE}📝 配置环境变量${NC}"
echo "请输入以下配置信息："
echo ""

# OpenAI Key
read -p "🔑 DeepSeek API Key: " DEEPSEEK__KEY
if [ -z "$DEEPSEEK__KEY" ]; then
    echo -e "${RED}❌ DeepSeek API Key 不能为空${NC}"
    exit 1
fi


# GitLab Token
read -p "🎫 GitLab Personal Access Token: " GITLAB_TOKEN
if [ -z "$GITLAB_TOKEN" ]; then
    echo -e "${RED}❌ GitLab Token 不能为空${NC}"
    exit 1
fi

# Webhook Secret
echo ""
echo -e "${YELLOW}💡 Webhook Secret 用于验证请求安全性${NC}"
read -p "🔐 Webhook Secret (留空自动生成): " WEBHOOK_SECRET
if [ -z "$WEBHOOK_SECRET" ]; then
    WEBHOOK_SECRET=$(openssl rand -base64 32 2>/dev/null || echo "$(date +%s)-$(shuf -i 1000-9999 -n 1)")
    echo -e "${GREEN}🔑 自动生成 Secret: $WEBHOOK_SECRET${NC}"
fi

# 写入 .env 文件
cat > .env << EOF
# PR-Agent GitLab Webhook 配置文件
# 生成时间: $(date)

# =================================
# 🔑 基础配置
# =================================

# DeepSeek 配置
DEEPSEEK__KEY=$DEEPSEEK__KEY

# GitLab 配置
GITLAB__PERSONAL_ACCESS_TOKEN=$GITLAB_TOKEN
GITLAB__SHARED_SECRET=$WEBHOOK_SECRET

# =================================
# ⚙️ 应用配置
# =================================

# 应用基础设置
# CONFIG__APP_NAME=PR-Agent-GitLab-Webhook
# CONFIG__VERBOSITY_LEVEL=1

# # 日志配置
# LOGGING__LEVEL=INFO
# LOGGING__FORMAT=JSON

# # GitLab 自动命令配置
# GITLAB__PR_COMMANDS=["describe", "review"]
# GITLAB__PUSH_COMMANDS=["review"]
# GITLAB__HANDLE_PUSH_TRIGGER=true

# # 安全和过滤配置
# CONFIG__DISABLE_AUTO_FEEDBACK=false
# CONFIG__IGNORE_PR_AUTHORS=[]
# CONFIG__IGNORE_PR_TITLE=[]
# CONFIG__IGNORE_PR_LABELS=[]
# CONFIG__IGNORE_PR_SOURCE_BRANCHES=[]
# CONFIG__IGNORE_PR_TARGET_BRANCHES=[]

# # PR 处理配置
# PR_REVIEWER__PERSISTENT_COMMENT=true
# PR_REVIEWER__REQUIRE_SCORE_REVIEW=false
# PR_REVIEWER__REQUIRE_TESTS_REVIEW=false
# PR_REVIEWER__REQUIRE_ESTIMATE_EFFORT_TO_REVIEW=true

# # AI 模型配置
# CONFIG__MODEL=gpt-4
# CONFIG__FALLBACK_MODELS=["gpt-3.5-turbo"]
EOF

echo ""
echo -e "${GREEN}✅ 配置文件已创建${NC}"
echo ""

# 显示配置摘要
echo -e "${BLUE}📋 配置摘要${NC}"
echo "=================================="
echo "GitLab URL: $GITLAB_URL"
echo "Webhook Secret: $WEBHOOK_SECRET"
echo "配置文件: .env"
echo ""

# 获取主机IP (兼容 macOS 和 Linux)
get_host_ip() {
    # 尝试多种方法获取主机IP
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
WEBHOOK_URL="http://$HOST_IP:3000/webhook"

echo -e "${YELLOW}📝 GitLab Webhook 配置指南${NC}"
echo "=================================="
echo "1. 进入你的 GitLab 项目"
echo "2. 导航到: Settings → Webhooks"
echo "3. 添加新的 webhook:"
echo "   - URL: $WEBHOOK_URL"
echo "   - Secret Token: $WEBHOOK_SECRET"
echo "   - 触发器: ✅ Push events, ✅ Merge request events, ✅ Comments"
echo "4. 点击 'Add webhook'"
echo ""

# 询问是否立即启动
read -p "🚀 是否现在启动服务? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}💡 稍后运行 ./start.sh 启动服务${NC}"
else
    echo -e "${GREEN}🚀 启动服务...${NC}"
    ./start.sh
fi

echo ""
echo -e "${GREEN}🎉 设置完成！${NC}"
echo -e "${YELLOW}💡 提示:${NC}"
echo "- 查看日志: docker-compose logs -f gitlab-webhook"
echo "- 健康检查: ./health-check.sh"
echo "- 停止服务: ./stop.sh" 