import { Module } from '@nestjs/common';
import { TasksService } from './tasks.service';

import { EarthquakesModule } from '../earthquakes/earthquakes.module';

@Module({
  imports: [EarthquakesModule],
  providers: [TasksService]
})
export class TasksModule {}
