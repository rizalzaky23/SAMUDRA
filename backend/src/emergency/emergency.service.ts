import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MitigasiStep } from './entities/mitigasi-step.entity';
import { PeralatanSiaga } from './entities/peralatan-siaga.entity';
import { User } from '../users/entities/user.entity';

import { IsString, IsNotEmpty, IsOptional, IsNumber } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

// ─── DTOs ─────────────────────────────────────────────────────────────────────

export class CreateMitigasiDto {
  @ApiProperty()
  @IsNumber()
  @Type(() => Number)
  stepNumber: number;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  iconName?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class UpdateMitigasiDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  stepNumber?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  iconName?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class CreatePeralatanDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ required: false, default: 'Umum' })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({ required: false, default: 0 })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  priority?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  iconName?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class UpdatePeralatanDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  priority?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  iconName?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  imageUrl?: string;
}

// ─── Service ──────────────────────────────────────────────────────────────────

@Injectable()
export class EmergencyService {
  constructor(
    @InjectRepository(MitigasiStep)
    private mitigasiRepo: Repository<MitigasiStep>,
    @InjectRepository(PeralatanSiaga)
    private peralatanRepo: Repository<PeralatanSiaga>,
  ) {}

  // Mitigasi
  async getAllMitigasi(): Promise<MitigasiStep[]> {
    return this.mitigasiRepo.find({ order: { stepNumber: 'ASC' } });
  }

  async createMitigasi(dto: CreateMitigasiDto, author: User): Promise<MitigasiStep> {
    const step = this.mitigasiRepo.create({ ...dto, authorId: author.id });
    return this.mitigasiRepo.save(step);
  }

  async updateMitigasi(id: string, dto: UpdateMitigasiDto): Promise<MitigasiStep> {
    const step = await this.mitigasiRepo.findOne({ where: { id } });
    if (!step) throw new NotFoundException('Langkah mitigasi tidak ditemukan');
    Object.assign(step, dto);
    return this.mitigasiRepo.save(step);
  }

  async deleteMitigasi(id: string): Promise<{ message: string }> {
    const step = await this.mitigasiRepo.findOne({ where: { id } });
    if (!step) throw new NotFoundException('Langkah mitigasi tidak ditemukan');
    await this.mitigasiRepo.remove(step);
    return { message: 'Langkah mitigasi berhasil dihapus' };
  }

  // Peralatan
  async getAllPeralatan(): Promise<PeralatanSiaga[]> {
    return this.peralatanRepo.find({ order: { priority: 'ASC', name: 'ASC' } });
  }

  async createPeralatan(dto: CreatePeralatanDto, author: User): Promise<PeralatanSiaga> {
    const item = this.peralatanRepo.create({
      ...dto,
      category: dto.category?.trim() || 'Umum',
      authorId: author.id,
    });
    return this.peralatanRepo.save(item);
  }

  async updatePeralatan(id: string, dto: UpdatePeralatanDto): Promise<PeralatanSiaga> {
    const item = await this.peralatanRepo.findOne({ where: { id } });
    if (!item) throw new NotFoundException('Peralatan tidak ditemukan');
    Object.assign(item, dto);
    return this.peralatanRepo.save(item);
  }

  async deletePeralatan(id: string): Promise<{ message: string }> {
    const item = await this.peralatanRepo.findOne({ where: { id } });
    if (!item) throw new NotFoundException('Peralatan tidak ditemukan');
    await this.peralatanRepo.remove(item);
    return { message: 'Peralatan berhasil dihapus' };
  }
}
