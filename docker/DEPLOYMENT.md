# GitLab Webhook 部署说明

## 🚀 快速开始

你已经构建好了镜像 `pg-llms-gitlab-webhook:latest`，现在只需要3步完成部署：

### 1️⃣ 运行自动设置脚本
```bash
./setup.sh
```
这个脚本会：
- ✅ 检查环境依赖
- ⚙️ 引导你配置必要的参数
- 📝 自动生成 `.env` 配置文件  
- 🚀 可选择立即启动服务

### 2️⃣ 配置 GitLab Webhook
按照脚本提示，在你的 GitLab 项目中添加 webhook：
- **URL**: `http://你的主机IP:3000/webhook`
- **Secret Token**: 脚本生成的密钥
- **触发器**: Push events, Merge request events, Comments

### 3️⃣ 完成！
服务将在端口 3000 上运行，接收来自 GitLab 的 webhook 请求。

## 🔧 管理命令

```bash
# 启动服务
./start.sh

# 停止服务  
./stop.sh

# 健康检查
./health-check.sh

# 查看日志
docker-compose logs -f gitlab-webhook
```

## 📋 需要准备的信息

运行 `./setup.sh` 时需要提供：

1. **OpenAI API Key** - 从 [OpenAI Platform](https://platform.openai.com/api-keys) 获取
2. **GitLab URL** - 你的 GitLab 实例地址（如 `https://gitlab.com`）
3. **GitLab Personal Access Token** - 在 GitLab → User Settings → Access Tokens 创建
   - 需要权限：`api`, `read_user`, `read_repository`, `write_repository`
4. **Webhook Secret** - 用于验证请求安全性（可自动生成）

## 🌐 内网访问

服务默认绑定到所有网络接口，内网用户可以通过以下地址访问：
- **健康检查**: `http://主机IP:3000/`
- **Webhook 端点**: `http://主机IP:3000/webhook`

## 🆘 如果遇到问题

1. 检查服务状态：`./health-check.sh`
2. 查看详细日志：`docker-compose logs gitlab-webhook`
3. 测试网络连接：`./health-check.sh test`

---

**就这么简单！** 🎉 从构建镜像到运行服务，只需要几分钟时间。 