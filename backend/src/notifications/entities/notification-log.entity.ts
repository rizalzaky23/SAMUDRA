import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { User } from '../../users/entities/user.entity';
import { Earthquake } from '../../earthquakes/entities/earthquake.entity';

@Entity('notifications_log')
export class NotificationLog {
  @ApiProperty()
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({ required: false, nullable: true })
  @Column({ name: 'user_id', nullable: true })
  userId?: string | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'user_id' })
  user?: User | null;

  @ApiProperty({ required: false, nullable: true })
  @Column({ name: 'earthquake_id', nullable: true })
  earthquakeId?: string | null;

  @ManyToOne(() => Earthquake, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'earthquake_id' })
  earthquake?: Earthquake | null;

  @ApiProperty()
  @Column({ length: 50 })
  status: string;

  @ApiProperty()
  @Column({ nullable: true })
  message: string;

  @ApiProperty()
  @CreateDateColumn({ name: 'sent_at' })
  sentAt: Date;
}
