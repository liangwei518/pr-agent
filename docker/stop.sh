#!/bin/bash

# PR-Agent GitLab Webhook 停止脚本
# 使用方法: ./stop.sh

set -e

echo "🛑 停止 PR-Agent GitLab Webhook 服务..."

# 停止并删除容器
docker-compose down

echo "✅ 服务已停止!"

# 可选：清理日志
read -p "是否要清理日志文件? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf logs/*
    echo "🗑️  日志文件已清理"
fi 