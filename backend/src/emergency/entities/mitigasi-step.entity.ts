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

@Entity('mitigasi_steps')
export class MitigasiStep {
  @ApiProperty()
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty()
  @Column({ name: 'step_number' })
  stepNumber: number;

  @ApiProperty()
  @Column({ length: 255 })
  title: string;

  @ApiProperty()
  @Column({ type: 'text' })
  description: string;

  @ApiProperty()
  @Column({ name: 'icon_name', nullable: true, length: 100 })
  iconName: string;

  @ApiProperty({ description: 'URL gambar/ilustrasi dari Cloudflare R2', required: false })
  @Column({ name: 'image_url', nullable: true, type: 'text' })
  imageUrl: string;

  @ApiProperty()
  @Column({ name: 'author_id' })
  authorId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'author_id' })
  author: User;

  @ApiProperty()
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @ApiProperty()
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
