import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { GlobalExceptionFilter } from './global-exception.filter';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 安全中间件 - 设置多种 HTTP 安全头
  app.use(helmet());

  // CORS 配置 - 生产环境必须设置允许的域名
  const allowedOrigins = process.env.CORS_ORIGINS?.split(',') || [];
  app.enableCors({
    origin: allowedOrigins.length > 0 ? allowedOrigins : false,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  // 请求速率限制 - 防止 DDoS 和暴力破解
  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15分钟窗口
    max: 100, // 每个IP最多100个请求
    message: { statusCode: 429, message: '请求过于频繁，请稍后再试' },
    standardHeaders: true,
    legacyHeaders: false,
  });
  app.use(limiter);

  // 全局验证管道
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // 剔除不在 DTO 中的属性
      forbidNonWhitelisted: true, // 禁止非白名单属性
      transform: true, // 自动转换类型
    }),
  );

  // 全局异常过滤器 - 生产环境隐藏详细错误
  app.useGlobalFilters(new GlobalExceptionFilter());

  // API 前缀
  app.setGlobalPrefix('api/v1');

  const port = process.env.PORT || 3000;
  await app.listen(port);

  console.log(`🚀 Application is running on: http://localhost:${port}`);
  console.log(`📦 Environment: ${process.env.NODE_ENV || 'development'}`);
}

bootstrap();
