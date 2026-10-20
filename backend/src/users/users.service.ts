import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';

interface CreateUserData {
  name: string;
  email: string;
  passwordHash?: string | null;
  phone?: string;
  googleId?: string;
  avatarUrl?: string;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepo: Repository<User>,
  ) {}

  async findById(id: string): Promise<User | null> {
    return this.usersRepo.findOne({ where: { id } });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepo.findOne({ where: { email } });
  }

  async create(data: CreateUserData): Promise<User> {
    const user = this.usersRepo.create({
      name: data.name,
      email: data.email,
      passwordHash: data.passwordHash ?? undefined,
      phone: data.phone,
      googleId: data.googleId,
      avatarUrl: data.avatarUrl,
    });
    return this.usersRepo.save(user);
  }

  async update(id: string, data: Partial<User>): Promise<User> {
    await this.usersRepo.update(id, data);
    const updated = await this.findById(id);
    if (!updated) throw new NotFoundException('User tidak ditemukan');
    return updated;
  }

  async updateRole(id: string, role: UserRole): Promise<User> {
    const user = await this.findById(id);
    if (!user) throw new NotFoundException('User tidak ditemukan');
    return this.update(id, { role });
  }

  async updateFcmToken(userId: string, fcmToken: string): Promise<void> {
    await this.usersRepo.update(userId, { fcmToken });
  }

  async findAll(): Promise<User[]> {
    return this.usersRepo.find({ order: { createdAt: 'DESC' } });
  }

  async findAllPaginated(page = 1, limit = 20): Promise<{ data: User[]; total: number; page: number; limit: number }> {
    const [data, total] = await this.usersRepo.findAndCount({
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { data, total, page, limit };
  }
}

