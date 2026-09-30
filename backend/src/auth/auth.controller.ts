import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Req,
  Res,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { Response } from 'express';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { RegisterDto, LoginDto, RefreshTokenDto } from './dto/auth.dto';
import { Public } from './decorators/public.decorator';
import { CurrentUser } from './decorators/current-user.decorator';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { GoogleAuthGuard } from './guards/google-auth.guard';
import { User } from '../users/entities/user.entity';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private configService: ConfigService,
  ) {}

  @Public()
  @Post('register')
  @ApiOperation({ summary: 'Daftar akun baru' })
  @ApiResponse({ status: 201, description: 'Registrasi berhasil, token dikembalikan' })
  @ApiResponse({ status: 409, description: 'Email sudah terdaftar' })
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login dengan email & password' })
  @ApiResponse({ status: 200, description: 'Login berhasil, token dikembalikan' })
  @ApiResponse({ status: 401, description: 'Email atau password salah' })
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh access token' })
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshToken(dto.refreshToken);
  }

  @Public()
  @Get('guest')
  @ApiOperation({ summary: 'Akses sebagai tamu (tanpa akun)' })
  async guestAccess() {
    return this.authService.guestAccess();
  }

  // ─── Google OAuth ────────────────────────────────────────────────────────────

  /**
   * Endpoint untuk memulai alur Google OAuth.
   * - Web: buka di browser → akan redirect ke halaman login Google
   * - Mobile (Flutter): buka via WebView atau in-app browser
   *
   * Untuk mobile, kirim state=mobile agar callback mengembalikan JSON
   * alih-alih redirect ke URL frontend.
   * Contoh: GET /api/auth/google?state=mobile  (tidak berfungsi karena Passport
   * mengelola params sendiri — gunakan cara flutter_appauth atau custom deep-link)
   */
  @Public()
  @Get('google')
  @UseGuards(GoogleAuthGuard)
  @ApiOperation({ summary: 'Mulai login dengan Google OAuth' })
  @ApiQuery({
    name: 'state',
    required: false,
    description: 'Set ke "mobile" jika dipanggil dari Flutter/Mobile untuk mendapat JSON response',
  })
  googleAuth() {
    // Passport menangani redirect ke Google secara otomatis
  }

  /**
   * Callback URL yang didaftarkan di Google Cloud Console.
   * Setelah user mengizinkan, Google redirect ke sini.
   *
   * - state=mobile → kembalikan JSON { accessToken, refreshToken, user }
   * - Selain itu  → redirect ke GOOGLE_AUTH_SUCCESS_REDIRECT dengan token di query param
   */
  @Public()
  @Get('google/callback')
  @UseGuards(GoogleAuthGuard)
  @ApiOperation({ summary: 'Google OAuth callback (otomatis dipanggil oleh Google)' })
  async googleCallback(
    @Req() req: any,
    @Res() res: Response,
    @Query('state') state?: string,
  ) {
    const tokens = await this.authService.loginWithGoogle(req.user);

    const isMobile = state === 'mobile';

    if (isMobile) {
      // Flutter/Mobile: kembalikan JSON langsung
      return res.status(HttpStatus.OK).json(tokens);
    }

    // Web: redirect ke frontend dengan token di URL query param
    const frontendUrl =
      this.configService.get<string>('GOOGLE_AUTH_SUCCESS_REDIRECT') ??
      'http://localhost:3001/auth/callback';

    const redirectUrl = new URL(frontendUrl);
    redirectUrl.searchParams.set('accessToken', tokens.accessToken);
    redirectUrl.searchParams.set('refreshToken', tokens.refreshToken);

    return res.redirect(redirectUrl.toString());
  }

  /**
   * Mobile-native endpoint for Flutter.
   * Flutter calls google_sign_in → gets idToken → POSTs here → receives our JWT.
   * No browser redirect needed.
   */
  @Public()
  @Post('google/token')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login mobile via Google idToken (Flutter / React Native)' })
  @ApiResponse({ status: 200, description: 'Token berhasil ditukar' })
  @ApiResponse({ status: 401, description: 'idToken tidak valid' })
  async googleTokenLogin(@Body() body: { idToken: string }) {
    return this.authService.loginWithGoogleIdToken(body.idToken);
  }

  // ─── Profil user ─────────────────────────────────────────────────────────────


  @UseGuards(JwtAuthGuard)
  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Ambil data user yang sedang login' })
  getMe(@CurrentUser() user: User) {
    return { user };
  }
}
