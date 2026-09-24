import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { User } from '../../users/entities/user.entity';

export enum ArticleStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
}

export enum ArticleCategory {
  MITIGASI = 'mitigasi_bencana',
  EDUKASI = 'edukasi_tsunami',
  BERITA = 'berita',
  TIPS = 'tips_keselamatan',
}

@Entity('articles')
export class Article {
  @ApiProperty()
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty()
  @Column({ length: 255 })
  title: string;

  @ApiProperty()
  @Column({ unique: true, length: 255 })
  slug: string;

  @ApiProperty()
  @Column({ type: 'text' })
  content: string;

  @ApiProperty({ enum: ArticleCategory })
  @Column({ type: 'enum', enum: ArticleCategory, default: ArticleCategory.EDUKASI })
  category: ArticleCategory;

  @ApiProperty()
  @Column({ name: 'cover_image_url', nullable: true })
  coverImageUrl: string;

  @ApiProperty()
  @Column({ name: 'author_id' })
  authorId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'author_id' })
  author: User;

  @ApiProperty({ enum: ArticleStatus })
  @Column({ type: 'enum', enum: ArticleStatus, default: ArticleStatus.DRAFT })
  status: ArticleStatus;

  @ApiProperty()
  @Column({ name: 'published_at', type: 'timestamptz', nullable: true })
  publishedAt: Date;

  @ApiProperty()
  @Column({ name: 'read_count', default: 0 })
  readCount: number;

  @ApiProperty()
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @ApiProperty()
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
