import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Article, ArticleStatus } from './entities/article.entity';
import { User, UserRole } from '../users/entities/user.entity';
import { CreateArticleDto, UpdateArticleDto } from './dto/article.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { StorageService } from '../storage/storage.service';

@Injectable()
export class ArticlesService {
  constructor(
    @InjectRepository(Article)
    private articlesRepo: Repository<Article>,
    private notificationsService: NotificationsService,
    private storageService: StorageService,
  ) {}

  private generateSlug(title: string): string {
    return title
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .trim()
      .replace(/\s+/g, '-')
      .concat('-', Date.now().toString());
  }

  async findAll(category?: string, status = ArticleStatus.PUBLISHED) {
    const where: any = { status };
    if (category) where.category = category;
    return this.articlesRepo.find({
      where,
      order: { publishedAt: 'DESC', createdAt: 'DESC' },
      relations: { author: true },
    });
  }

  async findAllForAdmin() {
    return this.articlesRepo.find({
      order: { createdAt: 'DESC' },
      relations: { author: true },
    });
  }

  async findById(id: string): Promise<Article> {
    const article = await this.articlesRepo.findOne({
      where: { id },
      relations: { author: true },
    });
    if (!article) throw new NotFoundException('Artikel tidak ditemukan');
    return article;
  }

  async create(dto: CreateArticleDto, author: User): Promise<Article> {
    const isPublished = dto.status === ArticleStatus.PUBLISHED;
    const images = dto.images ?? [];
    const coverImageUrl =
      dto.coverImageUrl || (images.length > 0 ? images[0] : undefined);

    const article = this.articlesRepo.create({
      title: dto.title,
      slug: this.generateSlug(dto.title),
      content: dto.content,
      category: dto.category,
      coverImageUrl: coverImageUrl,
      images: images,
      status: dto.status ?? ArticleStatus.DRAFT,
      authorId: author.id,
      publishedAt: isPublished ? new Date() : undefined,
    });
    const saved = await this.articlesRepo.save(article);

    // Kirim notifikasi jika artikel langsung dipublikasikan oleh admin
    if (isPublished) {
      await this.notificationsService.sendNewArticleNotification(saved);
    }

    return saved;
  }

  async update(id: string, dto: UpdateArticleDto, currentUser: User): Promise<Article> {
    const article = await this.findById(id);
    const wasPublished = article.status === ArticleStatus.PUBLISHED;

    // Hanya author atau super_admin yang bisa update
    if (article.authorId !== currentUser.id && currentUser.role !== UserRole.SUPER_ADMIN) {
      throw new ForbiddenException('Hanya penulis atau super admin yang bisa mengubah artikel ini');
    }

    if (dto.title) {
      article.slug = this.generateSlug(dto.title);
      article.title = dto.title;
    }
    if (dto.content !== undefined) article.content = dto.content;
    if (dto.category !== undefined) article.category = dto.category;
    if (dto.coverImageUrl !== undefined) article.coverImageUrl = dto.coverImageUrl;
    if (dto.images !== undefined) {
      article.images = dto.images;
      if (!article.coverImageUrl && dto.images.length > 0) {
        article.coverImageUrl = dto.images[0];
      }
    }
    if (dto.status !== undefined) {
      if (dto.status === ArticleStatus.PUBLISHED && !article.publishedAt) {
        article.publishedAt = new Date();
      }
      article.status = dto.status;
    }

    const updated = await this.articlesRepo.save(article);

    // Kirim notifikasi jika artikel diubah dari DRAFT menjadi PUBLISHED
    if (!wasPublished && updated.status === ArticleStatus.PUBLISHED) {
      await this.notificationsService.sendNewArticleNotification(updated);
    }

    return updated;
  }

  /**
   * Upload lebih dari 1 gambar sekaligus langsung ke artikel tertentu
   */
  async uploadArticleImages(
    id: string,
    files: Express.Multer.File[],
    currentUser: User,
  ): Promise<{ article: Article; uploadedUrls: string[] }> {
    const article = await this.findById(id);

    if (article.authorId !== currentUser.id && currentUser.role !== UserRole.SUPER_ADMIN) {
      throw new ForbiddenException('Hanya penulis atau super admin yang bisa mengubah artikel ini');
    }

    if (!files || files.length === 0) {
      throw new BadRequestException('Tidak ada file gambar yang diunggah');
    }

    const uploaded = await this.storageService.uploadMultipleFiles(files, 'articles');
    const newUrls = uploaded.map((item) => item.url);

    article.images = [...(article.images || []), ...newUrls];
    if (!article.coverImageUrl && article.images.length > 0) {
      article.coverImageUrl = article.images[0];
    }

    const saved = await this.articlesRepo.save(article);
    return {
      article: saved,
      uploadedUrls: newUrls,
    };
  }

  /**
   * Hapus satu gambar dari galeri artikel
   */
  async removeArticleImage(
    id: string,
    imageUrl: string,
    currentUser: User,
  ): Promise<Article> {
    const article = await this.findById(id);

    if (article.authorId !== currentUser.id && currentUser.role !== UserRole.SUPER_ADMIN) {
      throw new ForbiddenException('Hanya penulis atau super admin yang bisa mengubah artikel ini');
    }

    article.images = (article.images || []).filter((url) => url !== imageUrl);
    if (article.coverImageUrl === imageUrl) {
      article.coverImageUrl = article.images.length > 0 ? article.images[0] : '';
    }

    await this.storageService.deleteFile(imageUrl);
    return this.articlesRepo.save(article);
  }

  async remove(id: string, currentUser: User): Promise<{ message: string }> {
    const article = await this.findById(id);

    if (article.authorId !== currentUser.id && currentUser.role !== UserRole.SUPER_ADMIN) {
      throw new ForbiddenException('Hanya penulis atau super admin yang bisa menghapus artikel ini');
    }

    await this.articlesRepo.remove(article);
    return { message: 'Artikel berhasil dihapus' };
  }

  async incrementReadCount(id: string): Promise<void> {
    await this.articlesRepo.increment({ id }, 'readCount', 1);
  }
}
