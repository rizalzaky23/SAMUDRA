import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MitigasiStep } from './entities/mitigasi-step.entity';
import { PeralatanSiaga } from './entities/peralatan-siaga.entity';
import { SafePoint } from './entities/safe-point.entity';
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

export class CreateSafePointDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  subtitle?: string;

  @ApiProperty()
  @IsNumber()
  @Type(() => Number)
  latitude: number;

  @ApiProperty()
  @IsNumber()
  @Type(() => Number)
  longitude: number;

  @ApiProperty({ required: false, default: '⛺' })
  @IsOptional()
  @IsString()
  icon?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  capacity?: number;
}

export class UpdateSafePointDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  subtitle?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  latitude?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  longitude?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  icon?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  capacity?: number;
}

// ─── Service ──────────────────────────────────────────────────────────────────

@Injectable()
export class EmergencyService {
  constructor(
    @InjectRepository(MitigasiStep)
    private mitigasiRepo: Repository<MitigasiStep>,
    @InjectRepository(PeralatanSiaga)
    private peralatanRepo: Repository<PeralatanSiaga>,
    @InjectRepository(SafePoint)
    private safePointRepo: Repository<SafePoint>,
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

  // ─── Safe Points (Titik Aman) ───────────────────────────────────────────────

  async getAllSafePoints(): Promise<SafePoint[]> {
    let list = await this.safePointRepo.find({
      order: { createdAt: 'ASC' },
    });

    // Inisialisasi titik aman default jika database masih kosong
    if (list.length === 0) {
      const initialPoints = [
        {
          name: 'Bukit Safe Point A',
          subtitle: 'Dataran tinggi aman (Yogyakarta)',
          latitude: -7.780,
          longitude: 110.360,
          icon: '⛺',
          capacity: 500,
        },
        {
          name: 'GOR Siaga Bencana',
          subtitle: 'Gedung pengungsian resmi (Yogyakarta)',
          latitude: -7.800,
          longitude: 110.400,
          icon: '🏛️',
          capacity: 1200,
        },
        {
          name: 'Masjid Al-Aman',
          subtitle: 'Titik kumpul evakuasi warga (Yogyakarta)',
          latitude: -7.760,
          longitude: 110.380,
          icon: '🕌',
          capacity: 400,
        },
      ];

      for (const p of initialPoints) {
        const item = this.safePointRepo.create(p);
        await this.safePointRepo.save(item);
      }

      list = await this.safePointRepo.find({ order: { createdAt: 'ASC' } });
    }

    return list;
  }

  async createSafePoint(dto: CreateSafePointDto, author: User): Promise<SafePoint> {
    const item = this.safePointRepo.create({
      ...dto,
      icon: dto.icon?.trim() || '⛺',
      authorId: author.id,
    });
    return this.safePointRepo.save(item);
  }

  async updateSafePoint(id: string, dto: UpdateSafePointDto): Promise<SafePoint> {
    const item = await this.safePointRepo.findOne({ where: { id } });
    if (!item) throw new NotFoundException('Titik aman tidak ditemukan');
    Object.assign(item, dto);
    return this.safePointRepo.save(item);
  }

  async deleteSafePoint(id: string): Promise<{ message: string }> {
    const item = await this.safePointRepo.findOne({ where: { id } });
    if (!item) throw new NotFoundException('Titik aman tidak ditemukan');
    await this.safePointRepo.remove(item);
    return { message: 'Titik aman berhasil dihapus' };
  }
}
