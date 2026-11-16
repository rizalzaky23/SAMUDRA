import { IsString, IsNotEmpty, IsNumber, IsOptional, IsIn } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateTrackingDto {
  @ApiProperty({ description: 'ID unik sesi pelacakan darurat' })
  @IsString()
  @IsNotEmpty()
  sessionId: string;

  @ApiPropertyOptional({ description: 'Nama pengguna yang sedang dilacak' })
  @IsString()
  @IsOptional()
  userName?: string;

  @ApiPropertyOptional({ description: 'Nomor telepon pengguna' })
  @IsString()
  @IsOptional()
  userPhone?: string;

  @ApiProperty({ description: 'Koordinat Latitude' })
  @IsNumber()
  latitude: number;

  @ApiProperty({ description: 'Koordinat Longitude' })
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ description: 'Level baterai HP pengguna (0-100)' })
  @IsNumber()
  @IsOptional()
  batteryLevel?: number;

  @ApiPropertyOptional({ description: 'Kecepatan pergerakan (m/s atau km/h)' })
  @IsNumber()
  @IsOptional()
  speed?: number;

  @ApiPropertyOptional({ description: 'Arah kompas / heading (derajat 0-360)' })
  @IsNumber()
  @IsOptional()
  heading?: number;

  @ApiPropertyOptional({ enum: ['active', 'stopped'], description: 'Status sesi live tracking' })
  @IsIn(['active', 'stopped'])
  @IsOptional()
  status?: 'active' | 'stopped';
}

export class StopTrackingDto {
  @ApiProperty({ description: 'ID unik sesi pelacakan darurat' })
  @IsString()
  @IsNotEmpty()
  sessionId: string;
}
