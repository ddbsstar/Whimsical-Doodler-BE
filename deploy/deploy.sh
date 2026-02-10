#!/bin/bash

# ==========================================
# Whimsical Doodler 一键部署脚本
# 支持 Ubuntu/Debian
# ==========================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 开始部署 Whimsical Doodler 后端${NC}"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# ==========================================
# 步骤 1: 安装必要软件
# ==========================================
echo -e "${YELLOW}📦 安装必要软件...${NC}"
apt-get update

# 卸载冲突的旧版本
apt-get remove -y containerd docker.io docker-compose 2>/dev/null || true

# 安装 Docker 依赖
apt-get install -y ca-certificates curl gnupg lsb-release

# 添加 Docker 官方 GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null

# 添加 Docker 仓库
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动 Docker
systemctl start docker
systemctl enable docker

echo -e "${GREEN}✅ Docker 已安装${NC}"

# 验证安装
echo -e "${YELLOW}🔍 验证安装...${NC}"
docker --version
docker compose version

# ==========================================
# 步骤 2: 克隆或更新代码
# ==========================================
echo -e "${YELLOW}📥 获取代码...${NC}"
if [ -d "/app" ]; then
    cd /app
    echo "更新现有代码..."
    git pull
else
    read -p "请输入 Git 仓库地址: " REPO_URL
    if [ -n "$REPO_URL" ]; then
        git clone $REPO_URL /app
        cd /app
    else
        echo -e "${RED}请提供仓库地址${NC}"
        exit 1
    fi
fi

# ==========================================
# 步骤 3: 配置环境变量
# ==========================================
echo -e "${YELLOW}⚙️ 配置环境变量...${NC}"

read -p "请输入域名 (例如: api.example.com): " DOMAIN
read -p "请输入数据库密码: " DB_PASSWORD
read -p "请输入 JWT 密钥 (至少32位): " JWT_SECRET

# 创建 .env.production.local
cat > .env.production.local <<EOF
DB_PASSWORD=$DB_PASSWORD
JWT_SECRET=$JWT_SECRET
CORS_ORIGINS=https://$DOMAIN
EOF

# 更新 nginx.conf 中的域名
sed -i "s/your-domain.com/$DOMAIN/g" deploy/nginx.conf

echo -e "${GREEN}✅ 环境变量已配置${NC}"

# ==========================================
# 步骤 4: 构建和启动
# ==========================================
echo -e "${YELLOW}🐳 构建并启动 Docker 容器...${NC}"
docker-compose -f docker-compose.prod.yml up -d --build

echo -e "${GREEN}✅ 容器已启动${NC}"

# ==========================================
# 步骤 5: 安装 Nginx 和 SSL（可选）
# ==========================================
echo -e "${YELLOW}🌐 配置 Nginx 和 SSL（可选）...${NC}"
read -p "是否配置 Nginx 和 SSL? (y/n): " CONFIGURE_NGINX

if [ "$CONFIGURE_NGINX" = "y" ] || [ "$CONFIGURE_NGINX" = "Y" ]; then
    read -p "请输入您的邮箱 (用于 Let's Encrypt): " EMAIL

    # 安装 Nginx
    apt-get install -y nginx certbot python3-certbot-nginx

    # 配置 Nginx 反向代理
    cat > /etc/nginx/sites-available/$DOMAIN.conf <<NGINX_EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX_EOF

    ln -sf /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t

    # 获取 SSL 证书
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive

    # 自动续期
    echo "0 0 * * * root certbot renew --quiet" >> /etc/crontab

    echo -e "${GREEN}✅ SSL 证书已配置${NC}"
fi

# ==========================================
# 完成
# ==========================================
echo -e "${GREEN}
╔════════════════════════════════════════════════╗
║            部署完成！ ✅                        ║
╠════════════════════════════════════════════════╣
║  API 地址: http://$DOMAIN/api/v1             ║
║  健康检查: http://$DOMAIN/health             ║
╠════════════════════════════════════════════════╣
║  常用命令:                                    ║
║    查看日志: docker-compose -f docker-compose.prod.yml logs -f
║    重启服务: docker-compose -f docker-compose.prod.yml restart
║    更新代码: git pull && docker-compose -f docker-compose.prod.yml up -d --build
╚════════════════════════════════════════════════╝
${NC}"
