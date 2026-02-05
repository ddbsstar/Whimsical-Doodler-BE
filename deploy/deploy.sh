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
apt-get install -y curl git nginx certbot python3-certbot-nginx docker.io docker-compose

# 启动 Docker
systemctl start docker
systemctl enable docker

# ==========================================
# 步骤 2: 配置环境变量
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

echo -e "${GREEN}✅ 环境变量已配置${NC}"

# ==========================================
# 步骤 3: 克隆或更新代码
# ==========================================
echo -e "${YELLOW}📥 获取代码...${NC}"
if [ -d "/app" ]; then
    cd /app
    git pull
else
    read -p "请输入 Git 仓库地址 (或直接按 Enter 使用当前目录): " REPO_URL
    if [ -n "$REPO_URL" ]; then
        git clone $REPO_URL /app
        cd /app
    fi
fi

# ==========================================
# 步骤 4: 构建和启动
# ==========================================
echo -e "${YELLOW}🐳 启动 Docker 容器...${NC}"
docker-compose up -d --build

echo -e "${GREEN}✅ 容器已启动${NC}"

# ==========================================
# 步骤 5: 配置 Nginx 和 SSL
# ==========================================
echo -e "${YELLOW}🌐 配置 Nginx...${NC}"
cp deploy/nginx.conf /etc/nginx/sites-available/$DOMAIN.conf
sed -i "s/your-domain.com/$DOMAIN/g" /etc/nginx/sites-available/$DOMAIN.conf
ln -sf /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t

# ==========================================
# 步骤 6: 获取 SSL 证书
# ==========================================
echo -e "${YELLOW}🔒 获取 SSL 证书...${NC}"
read -p "请输入您的邮箱 (用于 Let's Encrypt): " EMAIL

certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive

# ==========================================
# 步骤 7: 完成
# ==========================================
echo -e "${GREEN}
╔════════════════════════════════════════════════╗
║            部署完成！ ✅                        ║
╠════════════════════════════════════════════════╣
║  API 地址: https://$DOMAIN/api/v1            ║
║  健康检查: https://$DOMAIN/health            ║
╠════════════════════════════════════════════════╣
║  常用命令:                                    ║
║    查看日志: docker-compose logs -f app       ║
║    重启服务: docker-compose restart app       ║
║    更新代码: git pull && docker-compose up -d ║
╚════════════════════════════════════════════════╝
${NC}"

# 自动续期 SSL
echo "0 0 * * * root certbot renew --quiet" >> /etc/crontab

echo -e "${YELLOW}📅 SSL 证书自动续期已配置${NC}"
