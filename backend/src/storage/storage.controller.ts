import {
  Controller,
  Post,
  UseInterceptors,
  UploadedFile,
  UseGuards,
  Query,
  BadRequestException,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
  ApiQuery,
} from '@nestjs/swagger';
import { StorageService } from './storage.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { memoryStorage } from 'multer';

const ALLOWED_FOLDERS = ['articles', 'mitigasi', 'peralatan', 'general'] as const;
type AllowedFolder = (typeof ALLOWED_FOLDERS)[number];

@ApiTags('Storage')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@Controller('storage')
export class StorageController {
  constructor(private readonly storageService: StorageService) {}

  /**
   * Upload satu file ke Cloudflare R2.
   * Folder menentukan sub-direktori di dalam bucket.
   *
   * Gunakan ?folder=articles|mitigasi|peralatan|general
   */
  @Post('upload')
  @ApiOperation({
    summary: '[Admin] Upload file ke Cloudflare R2',
    description:
      'Upload gambar/video/dokumen. Kembalikan URL publik yang bisa langsung dipakai di field coverImageUrl, imageUrl, dll.',
  })
  @ApiQuery({
    name: 'folder',
    enum: ALLOWED_FOLDERS,
    required: false,
    description: 'Sub-folder tujuan (default: general)',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
      required: ['file'],
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(), // simpan di RAM, lalu kirim ke R2
    }),
  )
  async upload(
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          // Maksimal 50 MB
          new MaxFileSizeValidator({ maxSize: 50 * 1024 * 1024 }),
          // Izinkan gambar, video, dan PDF
          new FileTypeValidator({
            fileType: /(image\/(jpeg|jpg|png|webp|gif|svg\+xml)|video\/(mp4|webm|quicktime)|application\/pdf|application\/octet-stream)/,
            fallbackToMimetype: true,
          } as any),
        ],
      }),
    )
    file: Express.Multer.File,
    @Query('folder') folder: AllowedFolder = 'general',

  ): Promise<{ url: string; key: string; size: number; mimetype: string }> {
    if (!ALLOWED_FOLDERS.includes(folder)) {
      throw new BadRequestException(
        `Folder tidak valid. Gunakan salah satu: ${ALLOWED_FOLDERS.join(', ')}`,
      );
    }

    const url = await this.storageService.uploadFile(file, folder);
    const key = url.split('/').slice(-2).join('/'); // ambil "folder/uuid.ext"

    return {
      url,
      key,
      size: file.size,
      mimetype: file.mimetype,
    };
  }
}
