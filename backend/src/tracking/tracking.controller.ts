import { Controller, Post, Get, Body, Param, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { TrackingService } from './tracking.service';
import { UpdateTrackingDto, StopTrackingDto } from './dto/tracking.dto';
import { Public } from '../auth/decorators/public.decorator';

@ApiTags('Live Tracking')
@Controller('tracking')
export class TrackingController {
  constructor(private readonly trackingService: TrackingService) {}

  @Public()
  @Post('update')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update atau mulai sesi koordinat live tracking (dari mobile)' })
  @ApiResponse({ status: 200, description: 'Koordinat berhasil diperbarui' })
  updateLocation(@Body() dto: UpdateTrackingDto) {
    return this.trackingService.updateSession(dto);
  }

  @Public()
  @Get(':sessionId')
  @ApiOperation({ summary: 'Ambil status dan koordinat live tracking terkini (publik untuk web keluarga)' })
  @ApiResponse({ status: 200, description: 'Data live tracking berhasil diambil' })
  @ApiResponse({ status: 404, description: 'Sesi tidak ditemukan atau telah berakhir' })
  getSession(@Param('sessionId') sessionId: string) {
    return this.trackingService.getSession(sessionId);
  }

  @Public()
  @Post('stop')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Hentikan sesi live tracking darurat' })
  stopSession(@Body() dto: StopTrackingDto) {
    return this.trackingService.stopSession(dto.sessionId);
  }
}
