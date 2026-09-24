import { Controller, Get, Param, Query } from '@nestjs/common';
import { EarthquakesService } from './earthquakes.service';

@Controller('earthquakes')
export class EarthquakesController {
  constructor(private readonly earthquakesService: EarthquakesService) {}

  @Get('latest')
  async getLatestEarthquake() {
    return this.earthquakesService.getLatestEarthquake();
  }

  @Get('risk')
  async getRisk(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
  ) {
    const earthquake = await this.earthquakesService.getLatestEarthquake();
    if (!lat || !lng) {
      return { error: 'lat and lng query parameters are required' };
    }
    return this.earthquakesService.calculateRisk(
      earthquake,
      parseFloat(lat),
      parseFloat(lng),
    );
  }
}
