# Whimsical Doodler 后端项目

## 项目简介
NestJS + MySQL + TypeORM 用户注册登录系统

## 技术栈
- NestJS 11.x
- TypeORM + MySQL
- JWT 认证 (passport-jwt)
- class-validator 数据验证

## 快速开始

```bash
# 安装依赖
npm install

# 开发环境启动
npm run start:dev

# 构建生产版本
npm run build

# 生产环境启动
npm run start:prod
```

## 数据库配置
编辑 `.env.development.local`:
```
DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=123456
DB_DATABASE=whimsical_doodler
JWT_SECRET=your-secret-key
```

## API 接口

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | /api/v1/users/register | 注册 | 否 |
| POST | /api/v1/users/login | 登录 | 否 |
| GET | /api/v1/users/profile | 用户信息 | JWT |

## 安全提示
- 生产环境务必修改 JWT_SECRET（至少32位）
- 生产环境配置 CORS_ORIGINS
- 禁止在代码中硬编码密码
