import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

@Entity('earthquakes')
export class Earthquake {
  @ApiProperty()
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty()
  @Column({ name: 'bmkg_ref_id', unique: true, nullable: true })
  bmkgRefId: string;

  @ApiProperty()
  @Column({ type: 'decimal', precision: 4, scale: 1 })
  magnitude: number;

  @ApiProperty()
  @Column({ name: 'depth_km', type: 'decimal', precision: 7, scale: 2 })
  depthKm: number;

  @ApiProperty()
  @Column({ type: 'decimal', precision: 10, scale: 7 })
  latitude: number;

  @ApiProperty()
  @Column({ type: 'decimal', precision: 10, scale: 7 })
  longitude: number;

  @ApiProperty()
  @Column({ length: 255, nullable: true })
  region: string;

  @ApiProperty()
  @Column({ name: 'potential_tsunami', default: false })
  potentialTsunami: boolean;

  @ApiProperty()
  @Column({ name: 'occurred_at', type: 'timestamptz' })
  occurredAt: Date;

  @ApiProperty()
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
