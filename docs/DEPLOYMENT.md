# 部署指南

本项目使用 Docker 容器化部署，支持开发环境和生产环境。

## 目录结构

```
Whimsical-Doodler-BE/
├── src/                     # 源代码
├── dist/                    # 构建产物
├── test/                    # 测试文件
├── Dockerfile              # Docker 构建文件
├── docker-compose.dev.yml  # 开发环境配置
├── docker-compose.prod.yml # 生产环境配置
├── .env.development.local  # 开发环境变量
├── .env.production.local   # 生产环境变量（需创建）
└── deploy/
    ├── deploy.sh           # 一键部署脚本
    └── nginx.conf          # Nginx 配置
```

## 环境配置

### 开发环境

1. 复制环境变量模板：
   ```bash
   cp .env.development.local.example .env.development.local
   ```

2. 编辑配置：
   ```bash
   nano .env.development.local
   ```

3. 启动服务：
   ```bash
   docker-compose -f docker-compose.dev.yml up -d
   ```

4. 访问：`http://localhost:3000/api/v1`

### 生产环境

1. 创建环境变量文件：
   ```bash
   cat > .env.production.local <<EOF
   DB_PASSWORD=你的数据库密码
   JWT_SECRET=你的密钥（至少32位字符）
   CORS_ORIGINS=https://你的前端域名
   EOF
   ```

2. 启动服务：
   ```bash
   docker-compose -f docker-compose.prod.yml up -d --build
   ```

3. 访问：`http://你的服务器IP/api/v1`

## 快速启动

### 本地开发

```bash
# 安装依赖
npm install

# 开发模式启动（热重载）
npm run start:dev

# 或使用 Docker
docker-compose -f docker-compose.dev.yml up -d
```

### 服务器部署

#### 方式一：一键部署（推荐）

```bash
# 1. 上传项目到服务器
scp -r . root@你的服务器IP:/app

# 2. SSH 登录服务器
ssh root@你的服务器IP

# 3. 执行部署脚本
cd /app
chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

#### 方式二：手动部署

```bash
# 1. SSH 登录服务器
ssh root@你的服务器IP

# 2. 克隆或上传项目
git clone 你的仓库地址 /app
cd /app

# 3. 创建环境变量
cat > .env.production.local <<EOF
DB_PASSWORD=你的数据库密码
JWT_SECRET=你的密钥（至少32位）
CORS_ORIGINS=https://你的域名
EOF

# 4. 构建并启动
docker-compose -f docker-compose.prod.yml up -d --build
```

#### 方式三：GitHub Actions 自动部署

配置 GitHub Secrets 后，合并到 master 分支自动部署：

| Secret 名称 | 值 |
|------------|-----|
| `SERVER_HOST` | 服务器 IP |
| `SERVER_PORT` | `22` |
| `SERVER_USERNAME` | 服务器用户名 |
| `SSH_PRIVATE_KEY` | SSH 私钥 |
| `SERVER_PATH` | `/app` |

## Docker Compose 命令

| 命令 | 说明 |
|------|------|
| `docker-compose -f docker-compose.dev.yml up -d` | 启动开发环境 |
| `docker-compose -f docker-compose.prod.yml up -d` | 启动生产环境 |
| `docker-compose -f docker-compose.prod.yml down` | 停止服务 |
| `docker-compose -f docker-compose.prod.yml down -v` | 停止并删除数据卷 |
| `docker-compose -f docker-compose.prod.yml restart` | 重启服务 |
| `docker-compose -f docker-compose.prod.yml logs -f` | 查看日志 |

## 查看状态

```bash
# 查看容器状态
docker-compose -f docker-compose.prod.yml ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f app

# 进入容器
docker-compose -f docker-compose.prod.yml exec app sh
docker-compose -f docker-compose.prod.yml exec db mysql -uroot -p
```

## 环境变量说明

| 变量 | 说明 | 必需 |
|------|------|------|
| `DB_PASSWORD` | MySQL root 密码 | ✅ |
| `JWT_SECRET` | JWT 密钥（至少32位） | ✅ |
| `CORS_ORIGINS` | CORS 允许的域名 | ✅ |

## 常见问题

### 1. 容器启动失败

```bash
# 查看错误日志
docker-compose -f docker-compose.prod.yml logs app
```

### 2. 数据库连接失败

```bash
# 检查数据库状态
docker-compose -f docker-compose.prod.yml ps db

# 查看数据库日志
docker-compose -f docker-compose.prod.yml logs db

# 重置数据库
docker-compose -f docker-compose.prod.yml down -v
docker-compose -f docker-compose.prod.yml up -d
```

### 3. 端口被占用

```bash
# 查看端口占用
netstat -tlnp | grep 3000

# 修改端口
# 编辑 docker-compose.prod.yml 中的 ports: "3000:3000"
```

### 4. 更新代码后重新部署

```bash
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

### 5. 清空所有数据重新开始

```bash
docker-compose -f docker-compose.prod.yml down -v
docker-compose -f docker-compose.prod.yml up -d --build
```

## API 接口

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/api/v1/users/register` | 用户注册 | 否 |
| POST | `/api/v1/users/login` | 用户登录 | 否 |
| GET | `/api/v1/users/profile` | 获取用户信息 | JWT |

## 技术栈

- **NestJS 11.x** - 后端框架
- **TypeORM + MySQL 8.0** - ORM 和数据库
- **Passport + JWT** - 认证
- **Docker + Nginx** - 容器化和反向代理
