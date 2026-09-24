import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Earthquake } from '../earthquakes/entities/earthquake.entity';
import { EvacuationPoint } from '../evacuation/entities/evacuation-point.entity';
import { Article } from '../articles/entities/article.entity';
import { EmergencyContact } from '../emergency/entities/emergency-contact.entity';
import { NotificationLog } from '../notifications/entities/notification-log.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Earthquake,
      EvacuationPoint,
      Article,
      EmergencyContact,
      NotificationLog,
    ]),
  ],
  exports: [TypeOrmModule],
})
export class DatabaseModule {}
