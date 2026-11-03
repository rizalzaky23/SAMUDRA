import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { OAuth2Client } from 'google-auth-library';
import { UsersService } from '../users/users.service';
import { RegisterDto, LoginDto } from './dto/auth.dto';
import { User, UserRole } from '../users/entities/user.entity';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) {
      throw new ConflictException('Email sudah terdaftar');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.usersService.create({
      name: dto.name,
      email: dto.email,
      passwordHash,
      phone: dto.phone,
    });

    return this.generateTokens(user);
  }

  async login(dto: LoginDto) {
    const user = await this.usersService.findByEmail(dto.email);
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Email atau password salah');
    }

    const isMatch = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Email atau password salah');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Akun Anda dinonaktifkan');
    }

    return this.generateTokens(user);
  }

  async loginWithGoogle(googleUser: {
    googleId: string;
    email: string;
    name: string;
    avatarUrl?: string;
  }) {
    let user = await this.usersService.findByEmail(googleUser.email);

    if (!user) {
      user = await this.usersService.create({
        name: googleUser.name,
        email: googleUser.email,
        googleId: googleUser.googleId,
        avatarUrl: googleUser.avatarUrl,
        passwordHash: null,
      });
    } else {
      const updates: any = {};
      if (!user.googleId && googleUser.googleId) {
        updates.googleId = googleUser.googleId;
      }
      if (googleUser.avatarUrl && user.avatarUrl !== googleUser.avatarUrl) {
        updates.avatarUrl = googleUser.avatarUrl;
      }
      if (googleUser.name && (!user.name || user.name === user.email.split('@')[0])) {
        updates.name = googleUser.name;
      }
      if (Object.keys(updates).length > 0) {
        user = await this.usersService.update(user.id, updates);
      }
    }

    // Auto-promote super_admin untuk email owner project
    const SUPER_ADMIN_EMAIL = 'rizalzaky2302@gmail.com';
    if (googleUser.email === SUPER_ADMIN_EMAIL && user.role === UserRole.USER) {
      user = await this.usersService.update(user.id, { role: UserRole.SUPER_ADMIN });
    }

    return this.generateTokens(user);
  }

  /**
   * Mobile-native Google Sign-In flow.
   * Flutter sends an idToken from google_sign_in → we verify it with Google → return our JWT.
   */
  async loginWithGoogleIdToken(idToken: string) {
    const clientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    const client = new OAuth2Client(clientId);

    let ticket: any;
    try {
      ticket = await client.verifyIdToken({
        idToken,
        audience: clientId,
      });
    } catch {
      throw new UnauthorizedException('idToken Google tidak valid');
    }

    const payload = ticket.getPayload();
    if (!payload?.email) {
      throw new UnauthorizedException('Email tidak ditemukan di profil Google');
    }

    return this.loginWithGoogle({
      googleId: payload.sub,
      email: payload.email,
      name: payload.name ?? payload.email.split('@')[0],
      avatarUrl: payload.picture,
    });
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });
      const user = await this.usersService.findById(payload.sub);
      if (!user || !user.isActive) {
        throw new UnauthorizedException();
      }
      return this.generateTokens(user);
    } catch {
      throw new UnauthorizedException('Refresh token tidak valid atau sudah kadaluarsa');
    }
  }

  async guestAccess() {
    return {
      accessToken: null,
      user: { role: 'guest', name: 'Tamu' },
      isGuest: true,
    };
  }

  private generateTokens(user: User) {
    const payload = { sub: user.id, email: user.email, role: user.role };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_SECRET'),
      expiresIn: this.configService.get<string>('JWT_EXPIRES_IN', '15m') as any,
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: this.configService.get<string>('JWT_REFRESH_EXPIRES_IN', '7d') as any,
    });

    const { passwordHash, ...userSafe } = user as any;

    return {
      accessToken,
      refreshToken,
      user: userSafe,
    };
  }
}
