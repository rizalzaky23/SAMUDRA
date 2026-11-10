import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT', 3000);

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // CORS
  const allowedOrigins: (string | RegExp)[] = [
    'https://samudra.buzz',
    'https://admin.samudra.buzz',
    'http://localhost:3000',
    'http://localhost:3001',
    /^http:\/\/localhost(:\d+)?$/,
    /^http:\/\/127\.0\.0\.1(:\d+)?$/,
  ];

  const envOrigins = configService.get<string>('CORS_ALLOWED_ORIGINS');
  if (envOrigins) {
    envOrigins
      .split(',')
      .map((o) => o.trim())
      .forEach((o) => {
        if (o && !allowedOrigins.includes(o)) {
          allowedOrigins.push(o);
        }
      });
  }

  app.enableCors({
    origin: allowedOrigins,
    credentials: true,
  });

  // Redirect root / to /api
  app.use((req: any, res: any, next: any) => {
    if (req.path === '/' || req.path === '') {
      return res.redirect('/api');
    }
    next();
  });

  // Global prefix
  app.setGlobalPrefix('api');

  // Swagger docs
  const config = new DocumentBuilder()
    .setTitle('SAMUDRA API')
    .setDescription('Aplikasi Deteksi Tsunami — API Documentation')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);
  console.log(`📖 Swagger docs enabled at /api/docs`);

  await app.listen(port);
  console.log(`🚀 SAMUDRA backend running on http://localhost:${port}/api`);
}
bootstrap();
