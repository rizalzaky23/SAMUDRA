import { Injectable, NotFoundException } from '@nestjs/common';
import { UpdateTrackingDto } from './dto/tracking.dto';

export interface TrackingPoint {
  latitude: number;
  longitude: number;
  timestamp: number;
}

export interface TrackingSession {
  sessionId: string;
  userName?: string;
  userPhone?: string;
  latitude: number;
  longitude: number;
  batteryLevel?: number;
  speed?: number;
  heading?: number;
  status: 'active' | 'stopped';
  startedAt: number;
  updatedAt: number;
  expiresAt: number;
  history: TrackingPoint[];
}

const SESSION_TTL_MS = 2 * 60 * 60 * 1000; // 2 Jam sesi darurat
const MAX_HISTORY_POINTS = 60; // Simpan 60 titik terakhir untuk jejak rute

@Injectable()
export class TrackingService {
  private sessions = new Map<string, TrackingSession>();

  constructor() {
    // Jalankan pembersihan sesi kadaluarsa setiap 10 menit
    setInterval(() => this.cleanupExpiredSessions(), 10 * 60 * 1000);
  }

  updateSession(dto: UpdateTrackingDto): TrackingSession {
    const now = Date.now();
    let session = this.sessions.get(dto.sessionId);

    const newPoint: TrackingPoint = {
      latitude: dto.latitude,
      longitude: dto.longitude,
      timestamp: now,
    };

    if (session) {
      // Perbarui sesi yang sudah berjalan
      session.latitude = dto.latitude;
      session.longitude = dto.longitude;
      session.updatedAt = now;
      session.expiresAt = now + SESSION_TTL_MS;

      if (dto.userName) session.userName = dto.userName;
      if (dto.userPhone) session.userPhone = dto.userPhone;
      if (dto.batteryLevel !== undefined) session.batteryLevel = dto.batteryLevel;
      if (dto.speed !== undefined) session.speed = dto.speed;
      if (dto.heading !== undefined) session.heading = dto.heading;
      if (dto.status) session.status = dto.status;

      // Tambahkan titik baru ke riwayat pergerakan
      session.history.push(newPoint);
      if (session.history.length > MAX_HISTORY_POINTS) {
        session.history.shift(); // Hapus titik terlama agar hemat RAM
      }
    } else {
      // Buat sesi darurat baru
      session = {
        sessionId: dto.sessionId,
        userName: dto.userName || 'Pengguna SAMUDRA',
        userPhone: dto.userPhone,
        latitude: dto.latitude,
        longitude: dto.longitude,
        batteryLevel: dto.batteryLevel,
        speed: dto.speed,
        heading: dto.heading,
        status: dto.status || 'active',
        startedAt: now,
        updatedAt: now,
        expiresAt: now + SESSION_TTL_MS,
        history: [newPoint],
      };
      this.sessions.set(dto.sessionId, session);
    }

    return session;
  }

  getSession(sessionId: string): TrackingSession {
    const session = this.sessions.get(sessionId);
    if (!session) {
      throw new NotFoundException('Sesi pelacakan tidak ditemukan atau telah berakhir.');
    }

    if (Date.now() > session.expiresAt) {
      this.sessions.delete(sessionId);
      throw new NotFoundException('Sesi pelacakan telah kadaluarsa.');
    }

    return session;
  }

  stopSession(sessionId: string): TrackingSession {
    const session = this.sessions.get(sessionId);
    if (!session) {
      throw new NotFoundException('Sesi pelacakan tidak ditemukan.');
    }

    session.status = 'stopped';
    session.updatedAt = Date.now();
    return session;
  }

  private cleanupExpiredSessions(): void {
    const now = Date.now();
    for (const [id, session] of this.sessions.entries()) {
      if (now > session.expiresAt) {
        this.sessions.delete(id);
      }
    }
  }
}

