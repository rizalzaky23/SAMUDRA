import { IsString, IsEnum, IsOptional, MaxLength, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { ArticleCategory, ArticleStatus } from '../entities/article.entity';

export class CreateArticleDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title: string;

  @ApiProperty({ type: String })
  @IsString()
  @IsNotEmpty()
  content: string;

  @ApiProperty({ enum: ArticleCategory, required: false })
  @IsOptional()
  @IsEnum(ArticleCategory)
  category?: ArticleCategory;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  coverImageUrl?: string;

  @ApiProperty({ enum: ArticleStatus, required: false })
  @IsOptional()
  @IsEnum(ArticleStatus)
  status?: ArticleStatus;
}

export class UpdateArticleDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  title?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiProperty({ enum: ArticleCategory, required: false })
  @IsOptional()
  @IsEnum(ArticleCategory)
  category?: ArticleCategory;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  coverImageUrl?: string;

  @ApiProperty({ enum: ArticleStatus, required: false })
  @IsOptional()
  @IsEnum(ArticleStatus)
  status?: ArticleStatus;
}
