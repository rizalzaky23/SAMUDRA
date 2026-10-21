import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';
import * as path from 'path';

@Injectable()
export class StorageService {
  private readonly s3: S3Client;
  private readonly bucket: string;
  private readonly publicUrl: string;

  constructor(private config: ConfigService) {
    const accountId = this.config.getOrThrow<string>('CF_R2_ACCOUNT_ID');
    const accessKeyId = this.config.getOrThrow<string>('CF_R2_ACCESS_KEY_ID');
    const secretAccessKey = this.config.getOrThrow<string>('CF_R2_SECRET_ACCESS_KEY');
    this.bucket = this.config.getOrThrow<string>('CF_R2_BUCKET_NAME');
    this.publicUrl = this.config.getOrThrow<string>('CF_R2_PUBLIC_URL');

    this.s3 = new S3Client({
      region: 'auto',
      endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId,
        secretAccessKey,
      },
    });
  }

  /**
   * Upload file buffer ke Cloudflare R2.
   * @param file    - File dari Multer (Express.Multer.File)
   * @param folder  - Sub-folder di dalam bucket, mis: 'articles', 'mitigasi', 'peralatan'
   * @returns       - URL publik file yang berhasil diupload
   */
  async uploadFile(file: Express.Multer.File, folder: string): Promise<string> {
    let ext = path.extname(file.originalname || '').toLowerCase();
    if (!ext) {
      if (file.mimetype.includes('jpeg') || file.mimetype.includes('jpg')) ext = '.jpg';
      else if (file.mimetype.includes('png')) ext = '.png';
      else if (file.mimetype.includes('webp')) ext = '.webp';
      else if (file.mimetype.includes('gif')) ext = '.gif';
      else ext = '.png';
    }
    const key = `${folder}/${uuidv4()}${ext}`;

    try {
      await this.s3.send(
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: key,
          Body: file.buffer,
          ContentType: file.mimetype,
          // Jadikan publik (R2 public bucket)
          // Jika bucket belum publik, gunakan presigned URL atau aktifkan custom domain
        }),
      );
    } catch (err) {
      console.error('[StorageService] Upload gagal:', err);
      throw new InternalServerErrorException('Gagal mengupload file ke storage');
    }

    // Return URL publik: bisa berupa custom domain atau R2.dev subdomain
    return `${this.publicUrl.replace(/\/$/, '')}/${key}`;
  }

  /**
   * Hapus file dari Cloudflare R2 berdasarkan key atau full URL.
   */
  async deleteFile(keyOrUrl: string): Promise<void> {
    // Ekstrak key dari URL jika yang diberikan adalah full URL
    const key = keyOrUrl.startsWith('http')
      ? keyOrUrl.replace(`${this.publicUrl.replace(/\/$/, '')}/`, '')
      : keyOrUrl;

    try {
      await this.s3.send(
        new DeleteObjectCommand({
          Bucket: this.bucket,
          Key: key,
        }),
      );
    } catch (err) {
      console.error('[StorageService] Hapus gagal:', err);
      // Tidak throw — file mungkin sudah tidak ada
    }
  }

  /**
   * Buat presigned URL untuk akses sementara (opsional, jika bucket private).
   */
  async getPresignedUrl(key: string, expiresInSeconds = 3600): Promise<string> {
    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });
    return getSignedUrl(this.s3, command, { expiresIn: expiresInSeconds });
  }
}
