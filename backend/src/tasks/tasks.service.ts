import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { EarthquakesService } from '../earthquakes/earthquakes.service';

@Injectable()
export class TasksService implements OnModuleInit {
  private readonly logger = new Logger(TasksService.name);

  constructor(private readonly earthquakesService: EarthquakesService) {}

  async onModuleInit() {
    this.logger.debug('Fetching BMKG data on startup...');
    await this.earthquakesService.fetchAndSaveLatestEarthquake();
  }

  @Cron("0 */2 * * * *")
  async handleCron() {
    this.logger.debug('Running BMKG Earthquake fetch cron job...');
    await this.earthquakesService.fetchAndSaveLatestEarthquake();
  }
}
