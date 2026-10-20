# 📚 SAMUDRA — Dokumentasi Proyek

> Folder ini berisi dokumentasi teknis agar pengembang baru **tidak perlu membaca seluruh source code** sebelum bisa berkontribusi.

## Daftar Dokumen

| File | Isi |
|------|-----|
| [01_struktur_proyek.md](./01_struktur_proyek.md) | Struktur folder lengkap backend & frontend |
| [02_arsitektur_backend.md](./02_arsitektur_backend.md) | Arsitektur NestJS, modul, entity, guard, flow auth |
| [03_arsitektur_frontend.md](./03_arsitektur_frontend.md) | Arsitektur Flutter, Riverpod, routing, layar |
| [04_database_schema.md](./04_database_schema.md) | Schema PostgreSQL, semua tabel & kolom penting |
| [05_api_endpoints.md](./05_api_endpoints.md) | Semua REST API endpoint beserta role yang diizinkan |
| [06_sistem_role.md](./06_sistem_role.md) | Sistem role (user / admin / super_admin) & cara kerjanya |
| [07_env_variables.md](./07_env_variables.md) | Semua environment variable yang dibutuhkan |
| [08_changelog.md](./08_changelog.md) | Log perubahan kode beserta file yang diubah |

## Stack Teknologi

| Layer | Teknologi |
|-------|-----------|
| Backend | NestJS (TypeScript), TypeORM, PostgreSQL |
| Frontend | Flutter (Dart), Riverpod, GoRouter |
| Auth | JWT + Google OAuth (Web & Mobile) |
| Deployment | Docker, SSH deploy via GitHub Actions |
| Notifikasi | Firebase Cloud Messaging (FCM) |
| Gempa | BMKG XML API (polling 60 detik) |
