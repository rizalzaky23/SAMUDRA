# 05 — API Endpoints

> Base URL: `https://samudra.rizalzaky.cloud/api` (production)
> Base URL dev: `http://localhost:3000/api`
> Swagger UI: `BASE_URL/docs`

## Legend Role

| Simbol | Arti |
|--------|------|
| 🌐 | Public (tanpa token) |
| 🔑 | Login (user / admin / super_admin) |
| 🛡️ | Admin atau Super Admin |
| 👑 | Super Admin saja |

---

## Auth (`/api/auth`)

| Method | Path | Role | Deskripsi |
|--------|------|------|-----------|
| `POST` | `/auth/register` | 🌐 | Daftar akun baru (`name`, `email`, `password`, `phone?`) |
| `POST` | `/auth/login` | 🌐 | Login email+password → `{ accessToken, refreshToken, user }` |
| `POST` | `/auth/refresh` | 🌐 | Refresh access token dari `refreshToken` |
| `GET`  | `/auth/guest` | 🌐 | Akses tamu (tanpa akun) |
| `GET`  | `/auth/google` | 🌐 | Mulai Google OAuth Web flow |
| `GET`  | `/auth/google/callback` | 🌐 | Callback dari Google OAuth |
| `POST` | `/auth/google/token` | 🌐 | Flutter: kirim `idToken` → dapat JWT |
| `GET`  | `/auth/me` | 🔑 | Data user yang sedang login |

---

## Users (`/api/users`)

| Method | Path | Role | Deskripsi |
|--------|------|------|-----------|
| `GET`  | `/users/profile` | 🔑 | Ambil profil sendiri |
| `PATCH`| `/users/profile` | 🔑 | Update nama / HP / fcmToken |
| `GET`  | `/users` | 🛡️ | Daftar semua user |
| `PATCH`| `/users/:id/role` | 👑 | Ubah role user (misal jadikan admin) |

---

## Earthquakes (`/api/earthquakes`)

| Method | Path | Role | Deskripsi |
|--------|------|------|-----------|
| `GET`  | `/earthquakes/latest` | 🌐 | Data gempa terbaru dari BMKG |
| `GET`  | `/earthquakes/history` | 🌐 | Riwayat gempa (paginasi) |

---

## Articles (`/api/articles`)

> Module ini direncanakan. Endpoint akan tersedia setelah implementasi admin.

| Method | Path | Role | Deskripsi |
|--------|------|------|-----------|
| `GET`  | `/articles` | 🌐 | Daftar artikel published |
| `GET`  | `/articles/:id` | 🌐 | Detail artikel |
| `POST` | `/articles` | 🛡️ | Buat artikel baru |
| `PATCH`| `/articles/:id` | 🛡️ | Update artikel (author / super_admin) |
| `DELETE`| `/articles/:id` | 🛡️ | Hapus artikel |

---

## Mitigasi (`/api/mitigasi`)

> Direncanakan. Konten langkah mitigasi mandiri.

| Method | Path | Role | Deskripsi |
|--------|------|------|-----------|
| `GET`  | `/mitigasi` | 🌐 | Semua langkah mitigasi |
| `POST` | `/mitigasi` | 🛡️ | Tambah langkah |
| `PATCH`| `/mitigasi/:id` | 🛡️ | Update langkah |
| `DELETE`| `/mitigasi/:id` | 🛡️ | Hapus langkah |

---

## Peralatan Siaga (`/api/peralatan`)

> Direncanakan. Konten peralatan siaga bencana.

| Method | Path | Role | Deskripsi |
|--------|------|------|-----------|
| `GET`  | `/peralatan` | 🌐 | Semua item peralatan |
| `POST` | `/peralatan` | 🛡️ | Tambah item |
| `PATCH`| `/peralatan/:id` | 🛡️ | Update item |
| `DELETE`| `/peralatan/:id` | 🛡️ | Hapus item |

---

## Notifications (`/api/notifications`)

| Method | Path | Role | Deskripsi |
|--------|------|------|-----------|
| `GET`  | `/notifications/status` | 🌐 | Cek status integrasi Firebase (ACTIVE/DRY_RUN) |
| `GET`  | `/notifications/logs` | 🌐/🔑 | Riwayat notifikasi (publik + user personal, admin melihat semua) |
| `POST` | `/notifications/test` | 🔑 | Kirim notifikasi uji coba ke akun sendiri |
| `POST` | `/notifications/broadcast` | 🛡️ | Broadcast notifikasi ke seluruh pengguna atau topik |

---

## Format Response Standar

### Sukses
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "user": {
    "id": "uuid",
    "name": "Nama",
    "email": "email@contoh.com",
    "role": "user",
    "isActive": true
  }
}
```

### Error
```json
{
  "statusCode": 401,
  "message": "Email atau password salah",
  "error": "Unauthorized"
}
```
