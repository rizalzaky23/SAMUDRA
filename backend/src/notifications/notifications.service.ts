import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { getApps, initializeApp, cert, App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import * as fs from 'fs';
import * as path from 'path';
import { NotificationLog } from './entities/notification-log.entity';
import { User } from '../users/entities/user.entity';
import { Earthquake } from '../earthquakes/entities/earthquake.entity';
import { Article } from '../articles/entities/article.entity';

@Injectable()
export class NotificationsService implements OnModuleInit {
  private readonly logger = new Logger(NotificationsService.name);
  private firebaseApp: App | null = null;
  private isConfigured = false;

  constructor(
    private readonly configService: ConfigService,
    @InjectRepository(NotificationLog)
    private readonly notificationLogRepo: Repository<NotificationLog>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Earthquake)
    private readonly earthquakeRepo: Repository<Earthquake>,
  ) {}

  onModuleInit() {
    this.initFirebase();
  }

  private initFirebase() {
    try {
      const existingApps = getApps();
      if (existingApps.length > 0) {
        this.firebaseApp = existingApps[0];
        this.isConfigured = true;
        this.logger.log('Firebase Admin SDK already initialized.');
        return;
      }

      // Prioritas 1: File service-account.json
      const credPath =
        this.configService.get<string>('FIREBASE_CREDENTIALS_PATH') ||
        path.join(process.cwd(), 'firebase-service-account.json');

      if (fs.existsSync(credPath)) {
        this.firebaseApp = initializeApp({
          credential: cert(credPath),
        });
        this.isConfigured = true;
        this.logger.log(`Firebase Admin initialized from file: ${credPath}`);
        return;
      }

      // Prioritas 2: Environment variables
      const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
      const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');
      let privateKey = this.configService.get<string>('FIREBASE_PRIVATE_KEY');

      if (projectId && clientEmail && privateKey && !projectId.startsWith('your_')) {
        privateKey = privateKey.replace(/\\n/g, '\n');

        this.firebaseApp = initializeApp({
          credential: cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
        this.isConfigured = true;
        this.logger.log(`Firebase Admin initialized for project: ${projectId}`);
        return;
      }

      this.logger.warn(
        '⚠️ Firebase Admin credentials not found. Push notification service is currently running in DRY-RUN mode. Set FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY or place firebase-service-account.json to activate real notifications.',
      );
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin SDK:', error);
      this.isConfigured = false;
    }
  }

  get isReady(): boolean {
    return this.isConfigured && this.firebaseApp !== null;
  }

  /**
   * Kirim notifikasi ke spesifik token FCM
   */
  async sendToToken(
    token: string,
    payload: { title: string; body: string; data?: Record<string, string> },
    userId?: string,
    earthquakeId?: string,
  ) {
    this.logger.log(`Sending notification to token ${token.slice(0, 10)}...`);

    if (!this.isReady || !this.firebaseApp) {
      this.logger.warn(`[DRY-RUN] Would send notification: "${payload.title}" - "${payload.body}" to token: ${token}`);
      return this.recordLog(
        userId,
        earthquakeId,
        'DRY_RUN',
        `${payload.title}: ${payload.body}`,
        payload.title,
        payload.body,
        payload.data?.type || 'direct',
        payload.data,
      );
    }

    try {
      const response = await getMessaging(this.firebaseApp).send({
        token,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data || {},
        android: {
          priority: 'high',
          notification: {
            channelId: 'samudra_alerts',
            sound: 'default',
            priority: 'high',
          },
        },
      });

      await this.recordLog(
        userId,
        earthquakeId,
        'SUCCESS',
        `${payload.title}: ${payload.body}`,
        payload.title,
        payload.body,
        payload.data?.type || 'direct',
        payload.data,
      );
      return { success: true, messageId: response };
    } catch (error: any) {
      this.logger.error(`Failed to send FCM to token: ${error.message}`);
      await this.recordLog(
        userId,
        earthquakeId,
        'FAILED',
        `Error: ${error.message}`,
        payload.title,
        payload.body,
        payload.data?.type || 'direct',
        payload.data,
      );

      if (
        userId &&
        (error.code === 'messaging/registration-token-not-registered' ||
          error.code === 'messaging/invalid-registration-token')
      ) {
        await this.userRepo.update(userId, { fcmToken: null as any });
        this.logger.warn(`Removed invalid FCM token for user ${userId}`);
      }

      return { success: false, error: error.message };
    }
  }

  /**
   * Kirim notifikasi ke FCM Topic
   */
  async sendToTopic(
    topic: string,
    payload: { title: string; body: string; data?: Record<string, string> },
    earthquakeId?: string,
  ) {
    this.logger.log(`Sending notification to topic: "${topic}"`);

    if (!this.isReady || !this.firebaseApp) {
      this.logger.warn(`[DRY-RUN] Would send to topic ${topic}: "${payload.title}" - "${payload.body}"`);
      return this.recordLog(
        undefined,
        earthquakeId,
        'DRY_RUN',
        `${payload.title}: ${payload.body}`,
        payload.title,
        payload.body,
        payload.data?.type || topic,
        payload.data,
      );
    }

    try {
      const response = await getMessaging(this.firebaseApp).send({
        topic,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data || {},
        android: {
          priority: 'high',
          notification: {
            channelId: 'samudra_alerts',
            sound: 'default',
            priority: 'high',
          },
        },
      });

      await this.recordLog(
        undefined,
        earthquakeId,
        'SUCCESS',
        `${payload.title}: ${payload.body}`,
        payload.title,
        payload.body,
        payload.data?.type || topic,
        payload.data,
      );
      return { success: true, messageId: response };
    } catch (error: any) {
      this.logger.error(`Failed to send FCM to topic ${topic}: ${error.message}`);
      await this.recordLog(
        undefined,
        earthquakeId,
        'FAILED',
        `Error: ${error.message}`,
        payload.title,
        payload.body,
        payload.data?.type || topic,
        payload.data,
      );
      return { success: false, error: error.message };
    }
  }

  /**
   * 1 & 2: Alert Gempa:
   * - Gempa yang memiliki potensi tsunami (Condition 1)
   * - Gempa terdekat dari lokasi user (Condition 2)
   */
  async sendEarthquakeAlert(earthquake: Earthquake) {
    const isTsunami = Boolean(earthquake.potentialTsunami);

    // --------------------------------------------------------------------
    // KONDISI 1: Gempa yang memiliki potensi tsunami
    // --------------------------------------------------------------------
    if (isTsunami) {
      const tsunamiTitle = `🚨 PERINGATAN DINI TSUNAMI (M ${earthquake.magnitude})`;
      const tsunamiBody = `Wilayah ${earthquake.region}. BMKG menyatakan gempa ini BERPOTENSI TSUNAMI! Segera menuju zona evakuasi lebih tinggi.`;

      const tsunamiData: Record<string, string> = {
        type: 'tsunami_alert',
        earthquakeId: earthquake.id || '',
        magnitude: earthquake.magnitude.toString(),
        depthKm: earthquake.depthKm.toString(),
        latitude: earthquake.latitude.toString(),
        longitude: earthquake.longitude.toString(),
        potentialTsunami: 'true',
        region: earthquake.region || '',
        occurredAt: earthquake.occurredAt ? earthquake.occurredAt.toISOString() : new Date().toISOString(),
      };

      // Broadcast ke topic 'tsunami_alerts' dan 'earthquakes'
      await this.sendToTopic('tsunami_alerts', { title: tsunamiTitle, body: tsunamiBody, data: tsunamiData }, earthquake.id);
      await this.sendToTopic('earthquakes', { title: tsunamiTitle, body: tsunamiBody, data: tsunamiData }, earthquake.id);

      // Kirim multicast ke semua user yang terdaftar
      await this.multicastToAllUsers(tsunamiTitle, tsunamiBody, tsunamiData, earthquake.id);
    }

    // --------------------------------------------------------------------
    // KONDISI 2: Gempa terdekat dari lokasi user
    // --------------------------------------------------------------------
    await this.notifyNearbyUsers(earthquake);
  }

  /**
   * Cek jarak user terhadap episentrum gempa, dan kirim notifikasi khusus jika dekat
   */
  private async notifyNearbyUsers(earthquake: Earthquake) {
    const usersWithLocation = await this.userRepo
      .createQueryBuilder('user')
      .where('user.fcmToken IS NOT NULL AND user.fcmToken != :empty', { empty: '' })
      .andWhere('user.latitude IS NOT NULL AND user.longitude IS NOT NULL')
      .select(['user.id', 'user.fcmToken', 'user.latitude', 'user.longitude', 'user.name'])
      .getMany();

    if (usersWithLocation.length === 0) return;

    this.logger.log(`Checking earthquake distance for ${usersWithLocation.length} users with coordinates...`);

    for (const user of usersWithLocation) {
      if (!user.latitude || !user.longitude || !user.fcmToken) continue;

      const userLat = Number(user.latitude);
      const userLng = Number(user.longitude);
      const distanceKm = this.haversineDistance(userLat, userLng, earthquake.latitude, earthquake.longitude);

      // Kriteria radius dekat:
      // - Jika gempa potensi tsunami: radius terdampak s.d. 300 km
      // - Jika M >= 6.0: radius s.d. 200 km
      // - Jika M >= 5.0: radius s.d. 120 km
      // - Jika M < 5.0: radius s.d. 50 km
      let isNearby = false;
      if (earthquake.potentialTsunami && distanceKm <= 300) {
        isNearby = true;
      } else if (earthquake.magnitude >= 6.0 && distanceKm <= 200) {
        isNearby = true;
      } else if (earthquake.magnitude >= 5.0 && distanceKm <= 120) {
        isNearby = true;
      } else if (distanceKm <= 50) {
        isNearby = true;
      }

      if (isNearby) {
        const roundedDist = Math.round(distanceKm);
        const title = earthquake.potentialTsunami
          ? `🚨 TSUNAMI DEKAT POSISI ANDA (${roundedDist} km)`
          : `⚠️ GEMPA TERDEKAT DARI LOKASI ANDA (${roundedDist} km)`;

        const body = `Gempa M ${earthquake.magnitude} terdeteksi berjarak sekitar ${roundedDist} km dari lokasi Anda (${earthquake.region}). Tetap waspada!`;

        const dataPayload: Record<string, string> = {
          type: 'nearby_earthquake',
          earthquakeId: earthquake.id || '',
          distanceKm: roundedDist.toString(),
          magnitude: earthquake.magnitude.toString(),
          region: earthquake.region || '',
          latitude: earthquake.latitude.toString(),
          longitude: earthquake.longitude.toString(),
          potentialTsunami: earthquake.potentialTsunami ? 'true' : 'false',
        };

        // Kirim langsung ke token perangkat user tersebut
        await this.sendToToken(
          user.fcmToken,
          { title, body, data: dataPayload },
          user.id,
          earthquake.id,
        );
      }
    }
  }

  /**
   * 3: KONDISI 3: Notifikasi ketika admin membuat/mempublikasikan artikel edukasi baru
   */
  async sendNewArticleNotification(article: Article) {
    this.logger.log(`Sending notification for new article: "${article.title}"`);

    const title = `📚 Artikel Edukasi Baru: ${article.title}`;
    const body = `Pelajari informasi mitigasi & kesiapsiagaan bencana terbaru: "${article.title}". Ketuk untuk membaca!`;

    const dataPayload: Record<string, string> = {
      type: 'new_article',
      articleId: article.id,
      slug: article.slug,
      title: article.title,
      category: article.category || 'edukasi',
    };

    // 1. Kirim ke topic 'articles' (untuk pengguna yang subscribe topic artikel)
    await this.sendToTopic('articles', { title, body, data: dataPayload });

    // 2. Multicast ke seluruh user terdaftar
    await this.multicastToAllUsers(title, body, dataPayload);
  }

  /**
   * Helper kirim notifikasi massal ke seluruh user terdaftar
   */
  private async multicastToAllUsers(
    title: string,
    body: string,
    data: Record<string, string>,
    earthquakeId?: string,
  ) {
    const usersWithTokens = await this.userRepo
      .createQueryBuilder('user')
      .where('user.fcmToken IS NOT NULL AND user.fcmToken != :empty', { empty: '' })
      .select(['user.id', 'user.fcmToken'])
      .getMany();

    if (usersWithTokens.length === 0) return;

    if (!this.isReady || !this.firebaseApp) {
      this.logger.warn(`[DRY-RUN] Multicast to ${usersWithTokens.length} users: "${title}"`);
      await this.recordLog(undefined, earthquakeId, 'DRY_RUN', `Dry-run multicast to ${usersWithTokens.length} users: ${title}`);
      return;
    }

    const tokens = usersWithTokens.map((u) => u.fcmToken);
    const chunkSize = 500;

    for (let i = 0; i < tokens.length; i += chunkSize) {
      const chunk = tokens.slice(i, i + chunkSize);
      try {
        await getMessaging(this.firebaseApp).sendEachForMulticast({
          tokens: chunk,
          notification: { title, body },
          data,
          android: {
            priority: 'high',
            notification: {
              channelId: 'samudra_alerts',
              sound: 'default',
            },
          },
        });
      } catch (err: any) {
        this.logger.error(`Multicast batch error: ${err.message}`);
      }
    }
  }

  /**
   * Formula Haversine untuk menghitung jarak antara 2 koordinat (dalam km)
   */
  private haversineDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Radius bumi dalam km
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  /**
   * Catat history pengiriman notifikasi
   */
  private async recordLog(
    userId?: string | null,
    earthquakeId?: string | null,
    status = 'SENT',
    message?: string,
    title?: string,
    body?: string,
    type?: string,
    data?: Record<string, any>,
  ): Promise<NotificationLog | null> {
    try {
      const formattedMessage = message || (title ? `${title}: ${body}` : 'Notification');
      const log = new NotificationLog();
      log.userId = userId ?? null;
      log.earthquakeId = earthquakeId ?? null;
      log.status = status;
      log.message = formattedMessage;
      log.title = title ?? undefined;
      log.body = body ?? undefined;
      log.type = type ?? undefined;
      log.payloadData = data ? JSON.stringify(data) : undefined;
      log.sentAt = new Date();
      return await this.notificationLogRepo.save(log);
    } catch (e: any) {
      this.logger.warn(`Could not save notification log: ${e.message}`);
      return null;
    }
  }

  async getLogs(userId?: string, limit = 50) {
    const qb = this.notificationLogRepo
      .createQueryBuilder('log')
      .leftJoinAndSelect('log.earthquake', 'earthquake')
      .orderBy('log.sentAt', 'DESC')
      .take(limit);

    if (userId) {
      qb.where('log.userId = :userId OR log.userId IS NULL', { userId });
    }

    let logs = await qb.getMany();

    // Jika log masih kosong (misal instalasi baru), populate dari data gempa terkini
    if (logs.length === 0) {
      try {
        const earthquakes = await this.earthquakeRepo.find({
          order: { occurredAt: 'DESC' },
          take: 5,
        });

        for (const eq of earthquakes) {
          const isTsunami = Boolean(eq.potentialTsunami);
          const title = isTsunami
            ? `🚨 PERINGATAN DINI TSUNAMI (M ${eq.magnitude})`
            : `⚠️ Gempa Bumi M ${eq.magnitude} - ${eq.region}`;
          const body = isTsunami
            ? `Wilayah ${eq.region}. BMKG menyatakan gempa berpotensi tsunami. Segera evakuasi ke tempat tinggi!`
            : `Gempa kedalaman ${eq.depthKm} km terjadi di wilayah ${eq.region}. Tidak berpotensi tsunami.`;

          const savedLog = await this.recordLog(
            null,
            eq.id,
            'SUCCESS',
            `${title}: ${body}`,
            title,
            body,
            isTsunami ? 'tsunami_alert' : 'earthquake',
            {
              magnitude: eq.magnitude?.toString(),
              depthKm: eq.depthKm?.toString(),
              region: eq.region,
              potentialTsunami: isTsunami ? 'true' : 'false',
            },
          );
          if (savedLog) {
            savedLog.earthquake = eq;
            logs.push(savedLog);
          }
        }
      } catch (err: any) {
        this.logger.warn(`Could not seed initial notification logs: ${err.message}`);
      }
    }

    return logs;
  }
}
