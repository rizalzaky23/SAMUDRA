import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MitigasiStep } from './entities/mitigasi-step.entity';
import { PeralatanSiaga } from './entities/peralatan-siaga.entity';
import { User } from '../users/entities/user.entity';

// ─── DTOs ─────────────────────────────────────────────────────────────────────

export class CreateMitigasiDto {
  stepNumber: number;
  title: string;
  description: string;
  iconName?: string;
}

export class UpdateMitigasiDto {
  stepNumber?: number;
  title?: string;
  description?: string;
  iconName?: string;
}

export class CreatePeralatanDto {
  name: string;
  category: string;
  description: string;
  priority?: number;
  iconName?: string;
}

export class UpdatePeralatanDto {
  name?: string;
  category?: string;
  description?: string;
  priority?: number;
  iconName?: string;
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
    const item = this.peralatanRepo.create({ ...dto, authorId: author.id });
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
