# 07 — Environment Variables

## Backend (`backend/.env`)

```bash
# ─── App ───────────────────────────────────────────────────────────────────────
NODE_ENV=development       # 'development' | 'production'
PORT=3000                  # Port server NestJS

# ─── Database PostgreSQL ────────────────────────────────────────────────────────
DB_HOST=localhost
DB_PORT=5432
DB_NAME=samudra_db
DB_USER=samudra_user
DB_PASSWORD=samudra_password
DB_SYNC=true               # true = TypeORM auto-sync schema (DEV ONLY!)
                           # HARUS false di production → pakai migration

# ─── JWT ───────────────────────────────────────────────────────────────────────
JWT_SECRET=ganti_ini_dengan_string_acak_panjang
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=ganti_ini_juga_berbeda_dari_jwt_secret
JWT_REFRESH_EXPIRES_IN=7d

# ─── Google OAuth ──────────────────────────────────────────────────────────────
GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxx
GOOGLE_CALLBACK_URL=http://localhost:3000/api/auth/google/callback
GOOGLE_AUTH_SUCCESS_REDIRECT=https://admin.samudra.buzz/auth/callback

# ─── Cloudflare R2 (Media / Object Storage) ──────────────────────────────────
CF_R2_ACCOUNT_ID=
CF_R2_ACCESS_KEY_ID=
CF_R2_SECRET_ACCESS_KEY=
CF_R2_BUCKET_NAME=samudra
CF_R2_PUBLIC_URL=https://cdn.samudra.buzz

# ─── AWS S3 (opsional legacy) ────────────────────────────────────────────────
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=ap-southeast-1
AWS_S3_BUCKET=samudra-media

# ─── Firebase Cloud Messaging ──────────────────────────────────────────────────
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=

# ─── BMKG ──────────────────────────────────────────────────────────────────────
BMKG_API_BASE_URL=https://data.bmkg.go.id/DataMKG/TEWS
BMKG_POLLING_INTERVAL_MS=60000   # interval polling dalam ms

# ─── Google Maps ───────────────────────────────────────────────────────────────
GOOGLE_MAPS_API_KEY=
```

---

## Frontend (`frontend/.env`)

```bash
# URL backend API
API_BASE_URL=https://samudra.rizalzaky.cloud/api

# Google OAuth — dari Google Cloud Console
# Web Client ID (untuk login Google di Web)
GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com

# Server Client ID (untuk verifikasi idToken dari mobile Flutter)
GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com

# Google Maps
GOOGLE_MAPS_API_KEY=xxxx
```

---

## Checklist Setup Environment Baru

### Backend
- [ ] Copy `backend/.env.example` → `backend/.env`
- [ ] Isi semua nilai di atas
- [ ] Pastikan PostgreSQL berjalan (atau jalankan `docker-compose up -d db`)
- [ ] Jalankan `npm run start:dev`

### Frontend
- [ ] Copy `frontend/.env.example` → `frontend/.env`
- [ ] Isi `API_BASE_URL` (arahkan ke backend lokal atau production)
- [ ] Isi `GOOGLE_CLIENT_ID` dan `GOOGLE_SERVER_CLIENT_ID`
- [ ] Daftarkan SHA-1 fingerprint lokal kamu ke Google Cloud Console / Firebase
  - Cara ambil SHA-1: `~/.android/debug.keystore` → `keytool -list -v ...`
  - Atau minta teammate share `debug.keystore` miliknya

---

## Catatan Penting

> [!CAUTION]
> File `.env` **TIDAK boleh di-commit** ke Git. Sudah ada di `.gitignore`.

> [!WARNING]
> `DB_SYNC=true` berbahaya di production — bisa mengubah skema DB secara otomatis saat deploy.

> [!TIP]
> Untuk production, gunakan GitHub Secrets. Lihat `.github/workflows/deploy.yml` untuk cara injeksi env ke server.
