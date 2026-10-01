import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

  // Security Headers (Helmet)
  app.use(helmet());

  // CORS Security: Giới hạn domain truy cập
  const allowedOrigins = configService
    .get<string>('ALLOWED_ORIGINS')
    ?.split(',') || ['http://localhost:3000', 'http://localhost:8080'];
  app.enableCors({
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  const prefix = configService.get<string>('API_PREFIX') || 'api/v1';
  app.setGlobalPrefix(prefix);

  // Validation Pipe Toàn Cục
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // Tự Động Sinh Tài Liệu Swagger API
  const swaggerConfig = new DocumentBuilder()
    .setTitle('WEARSY Mobile App Backend API')
    .setDescription(
      'RESTful API Specifications for WEARSY Smart Wardrobe & AI Engine',
    )
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup(`${prefix}/docs`, app, document);

  const port = configService.get<number>('PORT') || 3000;
  await app.listen(port);
  console.log(
    `🚀 WEARSY Backend is running on: http://localhost:${port}/${prefix}`,
  );
  console.log(
    `📚 Swagger Docs available at: http://localhost:${port}/${prefix}/docs`,
  );
}
bootstrap();
