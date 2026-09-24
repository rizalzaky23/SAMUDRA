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

  @ApiProperty()
  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ApiProperty()
  @Column({ name: 'earthquake_id', nullable: true })
  earthquakeId: string;

  @ManyToOne(() => Earthquake)
  @JoinColumn({ name: 'earthquake_id' })
  earthquake: Earthquake;

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
