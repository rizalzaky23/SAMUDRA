import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class SendNotificationDto {
  @ApiProperty({ description: 'Judul notifikasi', example: 'Peringatan Gempa Bumi' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ description: 'Isi pesan notifikasi', example: 'Gempa M 6.2 di wilayah Selatan Jawa' })
  @IsString()
  @IsNotEmpty()
  body: string;

  @ApiProperty({ required: false, description: 'Target token FCM perangkat' })
  @IsOptional()
  @IsString()
  token?: string;

  @ApiProperty({ required: false, description: 'Target User ID terdaftar' })
  @IsOptional()
  @IsString()
  userId?: string;

  @ApiProperty({ required: false, description: 'Target Topic FCM (default: earthquakes)', example: 'earthquakes' })
  @IsOptional()
  @IsString()
  topic?: string;

  @ApiProperty({ required: false, description: 'Payload data kustom tambahan' })
  @IsOptional()
  data?: Record<string, string>;
}
