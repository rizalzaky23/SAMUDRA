import { Injectable, ExecutionContext, BadRequestException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';

/**
 * Guard khusus Google OAuth.
 * Menangani error jika Google credentials belum dikonfigurasi di .env.
 */
@Injectable()
export class GoogleAuthGuard extends AuthGuard('google') {
  constructor(private configService: ConfigService) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const clientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    const clientSecret = this.configService.get<string>('GOOGLE_CLIENT_SECRET');

    if (
      !clientId ||
      clientId === 'your_google_client_id' ||
      !clientSecret ||
      clientSecret === 'your_google_client_secret'
    ) {
      throw new BadRequestException(
        'Google OAuth belum dikonfigurasi. Isi GOOGLE_CLIENT_ID dan GOOGLE_CLIENT_SECRET di file .env',
      );
    }

    return super.canActivate(context);
  }
}
