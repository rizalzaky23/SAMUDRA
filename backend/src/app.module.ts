import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { DatabaseModule } from './database/database.module';
import { TasksModule } from './tasks/tasks.module';
import { EarthquakesModule } from './earthquakes/earthquakes.module';
import { ArticlesModule } from './articles/articles.module';
import { EmergencyModule } from './emergency/emergency.module';

import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';

@Module({
  controllers: [AppController],
  imports: [
    ScheduleModule.forRoot(),
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST', 'localhost'),
        port: configService.get<number>('DB_PORT', 5432),
        database: configService.get<string>('DB_NAME', 'samudra_db'),
        username: configService.get<string>('DB_USER', 'samudra_user'),
        password: configService.get<string>('DB_PASSWORD', 'samudra_password'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        migrations: [__dirname + '/database/migrations/*{.ts,.js}'],
        synchronize: configService.get<string>('DB_SYNC') === 'true' || configService.get<string>('NODE_ENV') === 'development',
        logging: configService.get<string>('NODE_ENV') === 'development',
      }),
    }),
    AuthModule,
    UsersModule,
    DatabaseModule,
    TasksModule,
    EarthquakesModule,
    ArticlesModule,
    EmergencyModule,
  ],
})
export class AppModule {}

