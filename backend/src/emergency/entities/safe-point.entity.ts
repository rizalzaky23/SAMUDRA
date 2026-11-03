import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { User } from '../../users/entities/user.entity';

@Entity('safe_points')
export class SafePoint {
  @ApiProperty()
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty()
  @Column({ length: 255 })
  name: string;

  @ApiProperty({ required: false, nullable: true })
  @Column({ type: 'text', nullable: true })
  subtitle?: string;

  @ApiProperty()
  @Column({ type: 'decimal', precision: 10, scale: 7 })
  latitude: number;

  @ApiProperty()
  @Column({ type: 'decimal', precision: 10, scale: 7 })
  longitude: number;

  @ApiProperty({ default: '⛺' })
  @Column({ length: 50, default: '⛺' })
  icon: string;

  @ApiProperty({ required: false, nullable: true })
  @Column({ type: 'int', nullable: true })
  capacity?: number;

  @ApiProperty({ required: false, nullable: true })
  @Column({ name: 'author_id', nullable: true })
  authorId?: string | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'author_id' })
  author?: User | null;

  @ApiProperty()
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @ApiProperty()
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
