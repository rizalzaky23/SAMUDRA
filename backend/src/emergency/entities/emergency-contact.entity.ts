import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

export enum ContactType {
  BPBD = 'BPBD',
  SAR = 'SAR',
  POLISI = 'Polisi',
  PMI = 'PMI',
  RUMAH_SAKIT = 'Rumah Sakit',
}

@Entity('emergency_contacts')
export class EmergencyContact {
  @ApiProperty()
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty()
  @Column({ length: 255 })
  name: string;

  @ApiProperty()
  @Column({ length: 20 })
  phone: string;

  @ApiProperty({ enum: ContactType })
  @Column({ type: 'enum', enum: ContactType })
  type: ContactType;

  @ApiProperty()
  @Column({ length: 255, nullable: true })
  region: string;

  @ApiProperty()
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
