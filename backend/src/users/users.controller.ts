import {
  Controller,
  Get,
  Patch,
  Body,
  UseGuards,
  Param,
  Query,
  ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { IsEnum, IsString, IsOptional, MaxLength, IsIn } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User, UserRole } from './entities/user.entity';

class UpdateProfileDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  phone?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  fcmToken?: string;
}

class UpdateRoleDto {
  @ApiProperty({ enum: ['admin', 'user'], description: 'Role baru untuk user' })
  @IsEnum(['admin', 'user'])
  role: 'admin' | 'user';
}

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Ambil profil user yang login' })
  getProfile(@CurrentUser() user: User) {
    const { passwordHash, ...safe } = user as any;
    return safe;
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Update profil user' })
  async updateProfile(@CurrentUser() user: User, @Body() dto: UpdateProfileDto) {
    return this.usersService.update(user.id, dto);
  }

  @Get()
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: '[Admin] Daftar semua user (paginasi)' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  findAll(@Query('page') page = 1, @Query('limit') limit = 20) {
    return this.usersService.findAllPaginated(+page, +limit);
  }

  @Patch(':id/role')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: '[Super Admin] Ubah role user (admin/user)' })
  async updateRole(
    @Param('id') id: string,
    @Body() dto: UpdateRoleDto,
    @CurrentUser() currentUser: User,
  ) {
    // Super admin tidak bisa menurunkan diri sendiri
    if (id === currentUser.id) {
      throw new ForbiddenException('Tidak bisa mengubah role akun sendiri');
    }
    return this.usersService.updateRole(id, dto.role as UserRole);
  }
}
