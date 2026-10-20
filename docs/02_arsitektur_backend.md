# 02 — Arsitektur Backend (NestJS)

## Framework & Pattern

- **NestJS** dengan TypeScript
- **Pattern**: Controller → Service → Repository (TypeORM)
- **Database**: PostgreSQL via TypeORM
- **Auth**: JWT (access 15m + refresh 7d) + Passport Google OAuth
- **Validasi**: `class-validator` + `ValidationPipe` global
- **Docs**: Swagger di `/api/docs`

---

## Alur Request

```
Client Request
    │
    ▼
JwtAuthGuard (global, skip jika @Public())
    │
    ▼
RolesGuard (cek @Roles() metadata)
    │
    ▼
Controller → Service → TypeORM Repository → PostgreSQL
    │
    ▼
Response
```

---

## Modul-Modul Utama

### `AuthModule`
File utama: `src/auth/`

| File | Fungsi |
|------|--------|
| `auth.controller.ts` | Endpoint: register, login, refresh, guest, google OAuth, google/token |
| `auth.service.ts` | Logika: hash password, verifikasi JWT, loginWithGoogle, loginWithGoogleIdToken |
| `jwt.strategy.ts` | Validasi JWT Bearer token → inject `user` ke `req` |
| `google.strategy.ts` | Passport Google OAuth callback |
| `jwt-auth.guard.ts` | Guard global — skip jika route punya `@Public()` |
| `roles.guard.ts` | Guard role — cek metadata `@Roles()` vs `user.role` dari JWT |

**Dekorator penting:**
- `@Public()` — bebas dari JWT guard
- `@CurrentUser()` — inject `User` entity dari JWT payload
- `@Roles(UserRole.ADMIN)` — wajib role tertentu

### `UsersModule`
File utama: `src/users/`

| File | Fungsi |
|------|--------|
| `users.service.ts` | findById, findByEmail, create, update, updateFcmToken, findAll |
| `users.controller.ts` | GET /users/profile, PATCH /users/profile, GET /users (admin only) |
| `user.entity.ts` | Tabel `users` — lihat [04_database_schema.md](./04_database_schema.md) |

### `EarthquakesModule`
File utama: `src/earthquakes/`

| File | Fungsi |
|------|--------|
| `earthquakes.service.ts` | Fetch XML BMKG → parse → simpan ke DB |
| `earthquakes.controller.ts` | GET /earthquakes/latest, GET /earthquakes/history |
| `tasks/tasks.module.ts` | Cron job: `fetchAndSaveLatestEarthquake()` setiap 60 detik |

---

## Sistem Autentikasi

### Login Email/Password
```
POST /api/auth/login  { email, password }
    → UsersService.findByEmail()
    → bcrypt.compare()
    → generateTokens(user) → { accessToken, refreshToken, user }
```

### Login Google (Mobile Flutter)
```
Flutter: google_sign_in.signIn() → idToken
    → POST /api/auth/google/token  { idToken }
    → OAuth2Client.verifyIdToken()
    → UsersService.findOrCreate()
    → generateTokens(user) → { accessToken, refreshToken, user }
```

### Login Google (Web)
```
GET /api/auth/google → redirect ke Google
    → Google callback → GET /api/auth/google/callback
    → redirect ke frontend dengan ?accessToken=...&refreshToken=...
```

### JWT Payload
```json
{ "sub": "uuid-user", "email": "user@email.com", "role": "user" }
```

---

## Environment Variables Kritis Backend

Lihat detail di [07_env_variables.md](./07_env_variables.md).

| Var | Kegunaan |
|-----|----------|
| `JWT_SECRET` | Sign access token |
| `JWT_REFRESH_SECRET` | Sign refresh token |
| `GOOGLE_CLIENT_ID` | Verify idToken dari mobile |
| `DB_HOST/PORT/NAME/USER/PASSWORD` | Koneksi PostgreSQL |
| `DB_SYNC=true` | TypeORM auto-sync schema (development only!) |
