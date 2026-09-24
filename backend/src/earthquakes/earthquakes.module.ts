import { Module } from '@nestjs/common';
import { EarthquakesService } from './earthquakes.service';
import { EarthquakesController } from './earthquakes.controller';
import { HttpModule } from '@nestjs/axios';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Earthquake } from './entities/earthquake.entity';

@Module({
  imports: [
    HttpModule,
    TypeOrmModule.forFeature([Earthquake]),
  ],
  controllers: [EarthquakesController],
  providers: [EarthquakesService],
  exports: [EarthquakesService]
})
export class EarthquakesModule {}
