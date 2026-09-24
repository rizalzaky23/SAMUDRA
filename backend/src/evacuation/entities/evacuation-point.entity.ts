import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

export enum EvacuationPointType {
  SHELTER = 'shelter',
  HIGH_GROUND = 'high_ground',
}

@Entity('evacuation_points')
export class EvacuationPoint {
  @ApiProperty()
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty()
  @Column({ length: 255 })
  name: string;

  @ApiProperty()
  @Column({ type: 'decimal', precision: 10, scale: 7 })
  latitude: number;

  @ApiProperty()
  @Column({ type: 'decimal', precision: 10, scale: 7 })
  longitude: number;

  @ApiProperty({ enum: EvacuationPointType })
  @Column({ type: 'enum', enum: EvacuationPointType, default: EvacuationPointType.HIGH_GROUND })
  type: EvacuationPointType;

  @ApiProperty()
  @Column({ nullable: true })
  capacity: number;

  @ApiProperty()
  @Column({ nullable: true, length: 255 })
  address: string;

  @ApiProperty()
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
