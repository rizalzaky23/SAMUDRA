import { Module } from '@nestjs/common';
import { EarthquakesService } from './earthquakes.service';
import { EarthquakesController } from './earthquakes.controller';
import { HttpModule } from '@nestjs/axios';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Earthquake } from './entities/earthquake.entity';

import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    HttpModule,
    TypeOrmModule.forFeature([Earthquake]),
    NotificationsModule,
  ],
  controllers: [EarthquakesController],
  providers: [EarthquakesService],
  exports: [EarthquakesService]
})
export class EarthquakesModule {}
