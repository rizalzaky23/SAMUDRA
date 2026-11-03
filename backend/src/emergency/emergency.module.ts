import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EmergencyController } from './emergency.controller';
import { EmergencyService } from './emergency.service';
import { MitigasiStep } from './entities/mitigasi-step.entity';
import { PeralatanSiaga } from './entities/peralatan-siaga.entity';
import { SafePoint } from './entities/safe-point.entity';

@Module({
  imports: [TypeOrmModule.forFeature([MitigasiStep, PeralatanSiaga, SafePoint])],
  controllers: [EmergencyController],
  providers: [EmergencyService],
  exports: [EmergencyService],
})
export class EmergencyModule {}
