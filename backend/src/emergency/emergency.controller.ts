import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import {
  EmergencyService,
  CreateMitigasiDto,
  UpdateMitigasiDto,
  CreatePeralatanDto,
  UpdatePeralatanDto,
} from './emergency.service';
import { Public } from '../auth/decorators/public.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole, User } from '../users/entities/user.entity';

@ApiTags('Emergency Content')
@Controller()
export class EmergencyController {
  constructor(private emergencyService: EmergencyService) {}

  // ─── Mitigasi ─────────────────────────────────────────────────────────────

  @Public()
  @Get('mitigasi')
  @ApiOperation({ summary: 'Daftar langkah mitigasi mandiri (publik)' })
  getAllMitigasi() {
    return this.emergencyService.getAllMitigasi();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Post('mitigasi')
  @ApiOperation({ summary: '[Admin] Tambah langkah mitigasi' })
  createMitigasi(@Body() dto: CreateMitigasiDto, @CurrentUser() user: User) {
    return this.emergencyService.createMitigasi(dto, user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Patch('mitigasi/:id')
  @ApiOperation({ summary: '[Admin] Update langkah mitigasi' })
  updateMitigasi(@Param('id') id: string, @Body() dto: UpdateMitigasiDto) {
    return this.emergencyService.updateMitigasi(id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Delete('mitigasi/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[Admin] Hapus langkah mitigasi' })
  deleteMitigasi(@Param('id') id: string) {
    return this.emergencyService.deleteMitigasi(id);
  }

  // ─── Peralatan ────────────────────────────────────────────────────────────

  @Public()
  @Get('peralatan')
  @ApiOperation({ summary: 'Daftar peralatan siaga bencana (publik)' })
  getAllPeralatan() {
    return this.emergencyService.getAllPeralatan();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Post('peralatan')
  @ApiOperation({ summary: '[Admin] Tambah peralatan siaga' })
  createPeralatan(@Body() dto: CreatePeralatanDto, @CurrentUser() user: User) {
    return this.emergencyService.createPeralatan(dto, user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Patch('peralatan/:id')
  @ApiOperation({ summary: '[Admin] Update peralatan siaga' })
  updatePeralatan(@Param('id') id: string, @Body() dto: UpdatePeralatanDto) {
    return this.emergencyService.updatePeralatan(id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Delete('peralatan/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[Admin] Hapus peralatan siaga' })
  deletePeralatan(@Param('id') id: string) {
    return this.emergencyService.deletePeralatan(id);
  }
}
