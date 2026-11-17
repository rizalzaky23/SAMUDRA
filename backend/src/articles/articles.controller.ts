import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  UseInterceptors,
  UploadedFiles,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
  ApiResponse,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { memoryStorage } from 'multer';
import { ArticlesService } from './articles.service';
import { CreateArticleDto, UpdateArticleDto } from './dto/article.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Public } from '../auth/decorators/public.decorator';
import { User, UserRole } from '../users/entities/user.entity';

@ApiTags('Articles')
@Controller('articles')
export class ArticlesController {
  constructor(private articlesService: ArticlesService) {}

  // ─── Public endpoints ─────────────────────────────────────────────────────

  @Public()
  @Get()
  @ApiOperation({ summary: 'Daftar artikel published (publik)' })
  @ApiQuery({ name: 'category', required: false })
  findAll(@Query('category') category?: string) {
    return this.articlesService.findAll(category);
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Detail artikel (publik)' })
  async findOne(@Param('id') id: string) {
    const article = await this.articlesService.findById(id);
    // Increment read count
    await this.articlesService.incrementReadCount(id);
    return article;
  }

  // ─── Admin endpoints ───────────────────────────────────────────────────────

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Get('admin/all')
  @ApiOperation({ summary: '[Admin] Semua artikel termasuk draft' })
  findAllAdmin() {
    return this.articlesService.findAllForAdmin();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Post()
  @ApiOperation({ summary: '[Admin] Buat artikel baru' })
  @ApiResponse({ status: 201, description: 'Artikel berhasil dibuat' })
  create(@Body() dto: CreateArticleDto, @CurrentUser() user: User) {
    return this.articlesService.create(dto, user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Patch(':id')
  @ApiOperation({ summary: '[Admin] Update artikel (hanya author/super_admin)' })
  update(
    @Param('id') id: string,
    @Body() dto: UpdateArticleDto,
    @CurrentUser() user: User,
  ) {
    return this.articlesService.update(id, dto, user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Post(':id/images')
  @ApiOperation({ summary: '[Admin] Upload lebih dari 1 gambar ke artikel (galeri)' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        images: {
          type: 'array',
          items: { type: 'string', format: 'binary' },
          description: 'Pilih beberapa file gambar artikel sekaligus',
        },
      },
      required: ['images'],
    },
  })
  @UseInterceptors(
    FilesInterceptor('images', 20, {
      storage: memoryStorage(),
    }),
  )
  uploadImages(
    @Param('id') id: string,
    @UploadedFiles(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 50 * 1024 * 1024 }),
          new FileTypeValidator({
            fileType: /(image\/(jpeg|jpg|png|webp|gif|svg\+xml))/,
            fallbackToMimetype: true,
          } as any),
        ],
        fileIsRequired: true,
      }),
    )
    files: Express.Multer.File[],
    @CurrentUser() user: User,
  ) {
    return this.articlesService.uploadArticleImages(id, files, user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Delete(':id/images')
  @ApiOperation({ summary: '[Admin] Hapus satu gambar dari galeri artikel' })
  removeImage(
    @Param('id') id: string,
    @Body('imageUrl') imageUrl: string,
    @CurrentUser() user: User,
  ) {
    return this.articlesService.removeArticleImage(id, imageUrl, user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @ApiBearerAuth()
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '[Admin] Hapus artikel (hanya author/super_admin)' })
  remove(@Param('id') id: string, @CurrentUser() user: User) {
    return this.articlesService.remove(id, user);
  }
}
