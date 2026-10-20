# 04 — Database Schema (PostgreSQL)

> TypeORM digunakan sebagai ORM. Semua entity ada di folder `entities/` di masing-masing modul.
> 
> ⚠️ `DB_SYNC=true` di development → TypeORM auto-create/alter tabel sesuai entity.
> Di production, gunakan migration.

---

## Tabel: `users`

Entity: `src/users/entities/user.entity.ts`

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | UUID (PK) | Auto-generated |
| `name` | VARCHAR(100) | Nama lengkap |
| `email` | VARCHAR(255) UNIQUE | Email login |
| `password_hash` | TEXT, nullable | Null jika login via Google |
| `role` | ENUM | `user` / `admin` / `super_admin` (default: `user`) |
| `phone` | VARCHAR(20), nullable | Nomor HP |
| `google_id` | TEXT, nullable | Google sub ID |
| `avatar_url` | TEXT, nullable | URL foto profil |
| `is_active` | BOOLEAN | Default `true` |
| `fcm_token` | TEXT, nullable | Firebase push token |
| `created_at` | TIMESTAMPTZ | Auto |
| `updated_at` | TIMESTAMPTZ | Auto |

**Note:** `role` enum sebelumnya: `user`, `admin`, `editor`.
Setelah update sistem role: `user`, `admin`, `super_admin`.

---

## Tabel: `user_locations`

Entity: `src/users/entities/user-location.entity.ts`

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | UUID (PK) | |
| `user_id` | UUID (FK → users.id) | |
| `latitude` | FLOAT | |
| `longitude` | FLOAT | |
| `recorded_at` | TIMESTAMPTZ | |

---

## Tabel: `articles`

Entity: `src/articles/entities/article.entity.ts`

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | UUID (PK) | |
| `title` | VARCHAR(255) | |
| `slug` | VARCHAR(255) UNIQUE | URL-friendly title |
| `content` | TEXT | Isi artikel (markdown/html) |
| `category` | ENUM | `mitigasi_bencana` / `edukasi_tsunami` / `berita` / `tips_keselamatan` |
| `cover_image_url` | TEXT, nullable | |
| `author_id` | UUID (FK → users.id) | |
| `status` | ENUM | `draft` / `published` |
| `published_at` | TIMESTAMPTZ, nullable | |
| `read_count` | INTEGER | Default 0 |
| `created_at` | TIMESTAMPTZ | Auto |
| `updated_at` | TIMESTAMPTZ | Auto |

---

## Tabel: `earthquakes`

Entity: `src/earthquakes/entities/earthquake.entity.ts`

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | UUID (PK) | |
| `magnitude` | FLOAT | Skala Richter |
| `depth` | FLOAT | Kedalaman (km) |
| `latitude` | FLOAT | |
| `longitude` | FLOAT | |
| `location` | TEXT | Deskripsi lokasi dari BMKG |
| `potential_tsunami` | BOOLEAN | Flag potensi tsunami |
| `occurred_at` | TIMESTAMPTZ | Waktu kejadian |
| `created_at` | TIMESTAMPTZ | Auto |

---

## Tabel yang direncanakan (future)

Setelah implementasi admin:

### `mitigasi_steps` (Langkah Mitigasi Mandiri)
| Kolom | Tipe |
|-------|------|
| `id` | UUID (PK) |
| `step_number` | INTEGER |
| `title` | VARCHAR(255) |
| `description` | TEXT |
| `icon_name` | VARCHAR(100), nullable |
| `author_id` | UUID (FK → users.id) |
| `created_at` | TIMESTAMPTZ |
| `updated_at` | TIMESTAMPTZ |

### `peralatan_siaga` (Peralatan Siaga Bencana)
| Kolom | Tipe |
|-------|------|
| `id` | UUID (PK) |
| `name` | VARCHAR(255) |
| `category` | VARCHAR(100) |
| `description` | TEXT |
| `priority` | INTEGER |
| `author_id` | UUID (FK → users.id) |
| `created_at` | TIMESTAMPTZ |
| `updated_at` | TIMESTAMPTZ |

---

## Relasi Antar Tabel

```
users ─────────────────── articles (author_id)
users ─────────────────── user_locations (user_id)
users ─────────────────── mitigasi_steps (author_id)
users ─────────────────── peralatan_siaga (author_id)
```
