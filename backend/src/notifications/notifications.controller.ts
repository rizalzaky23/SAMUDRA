import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { SendNotificationDto } from './dto/send-notification.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Public } from '../auth/decorators/public.decorator';
import { User, UserRole } from '../users/entities/user.entity';

@ApiTags('Notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get('status')
  @ApiOperation({ summary: 'Cek status integrasi Firebase Cloud Messaging' })
  getStatus() {
    return {
      firebaseConfigured: this.notificationsService.isReady,
      mode: this.notificationsService.isReady ? 'ACTIVE' : 'DRY_RUN',
      message: this.notificationsService.isReady
        ? 'Firebase Cloud Messaging siap digunakan'
        : 'Firebase belum terkonfigurasi. Berjalan dalam mode simulasi (DRY-RUN).',
    };
  }

  @Post('test')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Kirim notifikasi uji coba (test) ke akun sendiri atau token tertentu' })
  async sendTest(
    @CurrentUser() user: User,
    @Body() dto: SendNotificationDto,
  ) {
    const targetToken = dto.token || user.fcmToken;
    if (!targetToken) {
      return {
        success: false,
        message: 'FCM Token belum tersedia. Berikan `token` di request body atau daftarkan fcmToken di akun profil Anda.',
      };
    }

    return this.notificationsService.sendToToken(
      targetToken,
      {
        title: dto.title || '🔔 Tes Notifikasi SAMUDRA',
        body: dto.body || 'Ini adalah notifikasi uji coba dari sistem SAMUDRA.',
        data: dto.data,
      },
      user.id,
    );
  }

  @Post('broadcast')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: '[Admin] Kirim broadcast notifikasi ke topic atau seluruh pengguna' })
  async broadcast(@Body() dto: SendNotificationDto) {
    const topic = dto.topic || 'earthquakes';
    return this.notificationsService.sendToTopic(topic, {
      title: dto.title,
      body: dto.body,
      data: dto.data,
    });
  }

  @Public()
  @UseGuards(JwtAuthGuard)
  @Get('logs')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Ambil riwayat pengiriman notifikasi' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getLogs(@CurrentUser() user?: User, @Query('limit') limit = 30) {
    // Admin bisa melihat semua log, user biasa/tamu melihat log publik & personal
    const userId =
      user?.role === UserRole.ADMIN || user?.role === UserRole.SUPER_ADMIN
        ? undefined
        : user?.id;

    return this.notificationsService.getLogs(userId, +limit);
  }
}
