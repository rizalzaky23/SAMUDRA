# 01 — Struktur Proyek SAMUDRA

## Root Folder

```
SAMUDRA/
├── backend/          # NestJS API server
├── frontend/         # Flutter mobile & web app
├── docs/             # Dokumentasi teknis (folder ini)
├── .github/
│   └── workflows/
│       └── deploy.yml   # CI/CD: auto deploy ke VPS via SSH saat push ke main
├── PRD-aplikasi-deteksi-tsunami.md
└── AGENTS.md         # Instruksi untuk AI coding agent (NgodingPakeAI)
```

---

## Backend (`backend/`)

```
backend/
├── src/
│   ├── app.module.ts         # Root module, inisialisasi TypeORM + semua module
│   ├── main.ts               # Entry point: port, CORS, ValidationPipe, Swagger
│   ├── app.controller.ts     # Health check endpoint GET /
│   │
│   ├── auth/                 # Modul autentikasi
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── auth.module.ts
│   │   ├── decorators/
│   │   │   ├── current-user.decorator.ts  # @CurrentUser() — inject user dari JWT
│   │   │   ├── public.decorator.ts        # @Public() — skip JWT guard
│   │   │   └── roles.decorator.ts         # @Roles(UserRole.ADMIN) — set metadata role
│   │   ├── dto/
│   │   │   └── auth.dto.ts               # RegisterDto, LoginDto, RefreshTokenDto
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts         # Guard global JWT
│   │   │   ├── google-auth.guard.ts      # Guard Passport Google OAuth
│   │   │   └── roles.guard.ts            # Guard cek role dari metadata
│   │   └── strategies/
│   │       ├── jwt.strategy.ts           # Verify JWT → inject user ke req
│   │       └── google.strategy.ts        # Google OAuth strategy
│   │
│   ├── users/                # Modul manajemen user
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   ├── users.module.ts
│   │   └── entities/
│   │       ├── user.entity.ts            # Tabel: users
│   │       └── user-location.entity.ts   # Tabel: user_locations
│   │
│   ├── articles/             # Modul artikel edukasi (entity saja, belum ada controller)
│   │   └── entities/
│   │       └── article.entity.ts         # Tabel: articles
│   │
│   ├── earthquakes/          # Modul data gempa dari BMKG
│   │   ├── earthquakes.controller.ts
│   │   ├── earthquakes.service.ts        # Polling BMKG XML, parse, simpan ke DB
│   │   ├── earthquakes.module.ts
│   │   └── entities/
│   │       └── earthquake.entity.ts      # Tabel: earthquakes
│   │
│   ├── emergency/            # Entitas darurat (konten siaga)
│   │   └── entities/         # (belum ada controller — placeholder)
│   │
│   ├── evacuation/           # Entitas jalur evakuasi
│   │   └── entities/
│   │
│   ├── notifications/        # FCM push notification
│   │   └── entities/
│   │
│   ├── tasks/                # Scheduled tasks (cron)
│   │   └── tasks.module.ts   # Cron polling BMKG setiap 60 detik
│   │
│   └── database/
│       └── database.module.ts   # Koneksi DB via TypeORM (lihat app.module.ts)
│
├── .env                      # Environment variables (JANGAN commit!)
├── .env.example              # Template env
├── Dockerfile                # Multi-stage build
├── docker-compose.yml        # Local dev: postgres + backend
├── package.json
└── tsconfig.json
```

---

## Frontend (`frontend/`)

```
frontend/
├── lib/
│   ├── main.dart             # Entry point Flutter, inisialisasi dotenv, Riverpod
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart      # URL API, storage keys, threshold risiko
│   │   ├── providers/
│   │   │   └── settings_provider.dart  # Riverpod: pengaturan app (lokasi, notif, dll)
│   │   ├── router/
│   │   │   └── app_router.dart         # GoRouter: semua rute + redirect auth guard
│   │   ├── theme/
│   │   │   └── app_theme.dart          # AppColors, AppTextStyles, ThemeData global
│   │   └── network/                    # (placeholder Dio interceptor)
│   │
│   ├── features/             # Satu folder per fitur
│   │   ├── auth/
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart  # AuthState, AuthNotifier, authStateProvider
│   │   │   └── screens/
│   │   │       ├── splash_screen.dart
│   │   │       ├── login_screen.dart
│   │   │       └── register_screen.dart
│   │   │
│   │   ├── home/
│   │   │   └── screens/
│   │   │       └── home_screen.dart    # Layar utama: header gempa, info status, quick action
│   │   │
│   │   ├── earthquake/
│   │   │   ├── models/                 # EarthquakeModel
│   │   │   ├── providers/
│   │   │   │   └── earthquake_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── history_screen.dart
│   │   │   ├── services/               # BMKG service (HTTP)
│   │   │   └── widgets/
│   │   │
│   │   ├── map/
│   │   │   ├── models/
│   │   │   │   └── safe_point_model.dart      # Model titik aman / evakuasi
│   │   │   ├── providers/
│   │   │   │   └── safe_points_provider.dart  # State & CRUD titik aman peta
│   │   │   └── screens/
│   │   │       └── map_screen.dart            # Peta rute evakuasi live & tambah titik aman (admin)
│   │   │
│   │   ├── emergency/
│   │   │   ├── providers/
│   │   │   └── screens/
│   │   │       └── emergency_screen.dart  # Kontak darurat, bagikan lokasi
│   │   │
│   │   ├── evacuation/                 # (placeholder)
│   │   │
│   │   ├── blog/                       # Artikel edukasi (providers & screens kosong)
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   │
│   │   ├── dashboard/                  # (placeholder)
│   │   ├── notifications/              # Fitur riwayat notifikasi & alert
│   │   │   ├── models/
│   │   │   │   └── notification_model.dart # Model notifikasi
│   │   │   ├── providers/
│   │   │   │   └── notifications_provider.dart # State riwayat notifikasi
│   │   │   └── screens/
│   │   │       └── notification_screen.dart # Layar riwayat notifikasi & peringatan
│   │   │
│   │   ├── admin/                      # Manajemen Admin & Super Admin
│   │   │   ├── providers/
│   │   │   │   └── admin_provider.dart
│   │   │   └── screens/
│   │   │       ├── admin_dashboard_screen.dart    # Menu utama admin panel
│   │   │       ├── admin_articles_screen.dart     # Kelola artikel edukasi
│   │   │       ├── admin_mitigasi_screen.dart     # Kelola langkah mitigasi
│   │   │       ├── admin_peralatan_screen.dart    # Kelola peralatan siaga
│   │   │       ├── admin_safe_points_screen.dart  # Kelola titik aman peta
│   │   │       └── admin_users_screen.dart        # Kelola pengguna & role
│   │   │
│   │   └── profile/
│   │       ├── providers/
│   │       └── screens/
│   │           └── profile_screen.dart # Profil user, pengaturan, logout
│   │
│   └── shared/
│       ├── models/
│       │   └── user_model.dart         # Model User Flutter (id, name, email, role, ...)
│       └── widgets/
│           └── main_scaffold.dart      # Bottom nav bar (Beranda/Peta/Riwayat/Darurat/Profil)
│
├── android/                  # Native Android config
├── .env                      # Env Flutter (API_BASE_URL, GOOGLE_CLIENT_ID, dll)
└── pubspec.yaml              # Dependencies Flutter
```
