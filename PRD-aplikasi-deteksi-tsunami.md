# Product Requirements Document (PRD)
# Aplikasi Deteksi Tsunami

**Versi:** 1.0
**Tanggal:** September 2026
**Platform:** Android & Web
**Status:** Draft

---

## 1. Ringkasan Produk (Overview)

Aplikasi deteksi tsunami adalah aplikasi lintas platform (Android & Web) yang menyajikan informasi gempa bumi secara real-time dari **BMKG**, menganalisis potensi tsunami berdasarkan lokasi pengguna, memberikan panduan evakuasi ke lokasi aman, serta menyediakan konten edukasi kebencanaan melalui fitur **blog**.

## 2. Latar Belakang & Tujuan

### 2.1 Latar Belakang
Indonesia berada di wilayah Cincin Api Pasifik dengan risiko gempa dan tsunami tinggi. Informasi resmi dari BMKG sering kali tidak sampai secara cepat dan kontekstual (berdasarkan lokasi) kepada masyarakat, sehingga dibutuhkan aplikasi yang dapat menerjemahkan data mentah BMKG menjadi peringatan yang actionable.

### 2.2 Tujuan Produk
- Menyediakan informasi gempa & potensi tsunami secara real-time dan akurat.
- Memberi tahu pengguna apakah lokasinya berisiko terdampak tsunami.
- Memandu pengguna ke lokasi aman terdekat secara cepat.
- Meningkatkan literasi mitigasi bencana melalui konten blog/edukasi.

### 2.3 Target Pengguna
- Masyarakat umum di wilayah pesisir/rawan gempa.
- Relawan & petugas BPBD/SAR.
- Wisatawan di daerah pesisir.
- Admin/editor konten (untuk mengelola blog edukasi).

---

## 3. Tech Stack

| Layer | Teknologi |
|---|---|
| Frontend (Mobile & Web) | Flutter (single codebase, `flutter_web` untuk web) |
| Backend / API | Node.js (Express/NestJS) |
| Database | PostgreSQL |
| Penyimpanan Media (gambar/dokumen blog) | AWS S3 (atau kompatibel S3, misal MinIO) |
| Sumber Data Gempa | API BMKG |
| Peta | Google Maps API / OpenStreetMap (`flutter_map`) |
| Notifikasi | Firebase Cloud Messaging (FCM) |
| Autentikasi | JWT + OAuth (Google Sign-In) |
| Hosting Backend | VPS/Cloud (misal AWS EC2 / DigitalOcean) |
| CI/CD | GitHub Actions |

---

## 4. Ruang Lingkup Fitur (Scope)

### 4.1 Modul Inti (Core — dari spesifikasi sebelumnya)
1. Autentikasi (login, register, guest mode, lupa password)
2. Dashboard data gempa real-time (BMKG)
3. Deteksi potensi tsunami berdasarkan lokasi pengguna
4. Peta interaktif (lokasi user, episentrum, zona risiko)
5. Rute evakuasi ke lokasi aman
6. Notifikasi & peringatan dini (push notification, background service)
7. Riwayat gempa
8. Kontak darurat
9. Pengaturan aplikasi
10. Profil pengguna

### 4.2 Modul Baru — Blog Edukasi
1. Halaman daftar artikel (list blog) dengan thumbnail dari S3
2. Halaman detail artikel (rich text + gambar)
3. Kategori/tag artikel (mitigasi bencana, edukasi tsunami, berita, dsb.)
4. Pencarian artikel
5. Panel admin/CMS untuk membuat, edit, hapus artikel (role: admin/editor)
6. Upload gambar/dokumen artikel ke S3
7. Komentar/like pada artikel (opsional — fase 2)
8. Bookmark/simpan artikel favorit pengguna

### 4.3 Di Luar Ruang Lingkup (Out of Scope — v1)
- iOS native (fokus awal Android & Web)
- Live chat / forum diskusi antar pengguna
- Prediksi gempa (aplikasi hanya mendeteksi & menganalisis potensi tsunami dari data gempa yang sudah terjadi, bukan memprediksi kapan gempa akan terjadi)

---

## 5. Functional Requirements

| ID | Modul | Requirement |
|---|---|---|
| FR-01 | Auth | Pengguna dapat mendaftar/login via email atau Google |
| FR-02 | Auth | Pengguna dapat menggunakan aplikasi sebagai guest tanpa akun (kecuali fitur blog admin) |
| FR-03 | Gempa | Sistem menarik data gempa terbaru dari API BMKG setiap interval tertentu (polling/cron job) |
| FR-04 | Deteksi | Sistem menghitung jarak lokasi pengguna ke episentrum menggunakan formula Haversine |
| FR-05 | Deteksi | Sistem menampilkan status risiko: Aman / Waspada / Siaga / Awas |
| FR-06 | Peta | Sistem menampilkan peta dengan marker lokasi user, episentrum, dan zona potensi tsunami |
| FR-07 | Evakuasi | Sistem menghitung & menampilkan rute ke titik evakuasi terdekat |
| FR-08 | Notifikasi | Sistem mengirim push notification saat status risiko pengguna berubah menjadi Siaga/Awas |
| FR-09 | Blog | Admin dapat membuat, mengedit, menghapus artikel melalui panel CMS |
| FR-10 | Blog | Gambar/media artikel diunggah dan disimpan di S3, URL disimpan di PostgreSQL |
| FR-11 | Blog | Pengguna dapat membaca, mencari, dan memfilter artikel berdasarkan kategori |
| FR-12 | Riwayat | Sistem menyimpan dan menampilkan histori gempa yang pernah tercatat |
| FR-13 | Darurat | Pengguna dapat melakukan panggilan cepat ke kontak darurat (BPBD/SAR) |

---

## 6. Non-Functional Requirements

| Kategori | Requirement |
|---|---|
| Performa | Data gempa baru harus tampil di aplikasi maksimal 1–2 menit setelah dipublikasikan BMKG |
| Skalabilitas | Backend Node.js harus mendukung horizontal scaling (stateless API + load balancer) |
| Keamanan | Autentikasi menggunakan JWT dengan refresh token; data sensitif dienkripsi |
| Ketersediaan | Uptime backend minimal 99.5% |
| Offline Support | Data gempa & artikel terakhir tetap dapat diakses saat tidak ada koneksi internet (local cache) |
| Kompatibilitas | Aplikasi berjalan pada Android 8.0+ dan browser modern (Chrome, Firefox, Edge, Safari) |
| Aksesibilitas | Mendukung dark mode dan ukuran teks yang dapat disesuaikan |

---

## 7. Arsitektur Sistem (High-Level)

```
[Flutter App - Android/Web]
        |
        | REST API (HTTPS)
        v
[Node.js Backend (Express/NestJS)]
        |
        |------> [PostgreSQL] --> data user, gempa (cache), artikel blog, log evakuasi
        |
        |------> [AWS S3] --> penyimpanan gambar/media artikel blog
        |
        |------> [BMKG API] --> polling data gempa terbaru (cron job/scheduler)
        |
        |------> [Firebase Cloud Messaging] --> push notification
```

### Catatan Arsitektur
- Backend melakukan **polling terjadwal** (misal setiap 1 menit) ke API BMKG, menyimpan hasil ke PostgreSQL sebagai cache, lalu mengevaluasi dampak ke pengguna aktif berdasarkan lokasi terakhir yang tersimpan.
- Endpoint blog terpisah dari endpoint data gempa agar beban trafik tidak saling mengganggu.
- Upload gambar dari Flutter langsung ke S3 menggunakan **pre-signed URL** dari backend (menghindari upload file besar lewat server Node.js).

---

## 8. Skema Database (Ringkasan — PostgreSQL)

**users**
`id, name, email, password_hash, role (user/admin), phone, created_at`

**earthquakes**
`id, bmkg_ref_id, magnitude, depth_km, latitude, longitude, region, potential_tsunami (bool), occurred_at, created_at`

**user_locations**
`id, user_id, latitude, longitude, updated_at`

**evacuation_points**
`id, name, latitude, longitude, type (shelter/high_ground), capacity`

**articles (blog)**
`id, title, slug, content, category, cover_image_url (S3), author_id, status (draft/published), published_at, created_at`

**article_media**
`id, article_id, s3_url, media_type`

**notifications_log**
`id, user_id, earthquake_id, status, sent_at`

**emergency_contacts**
`id, name, phone, type (BPBD/SAR/Polisi), region`

---

## 9. API Endpoint (Contoh Utama)

| Method | Endpoint | Deskripsi |
|---|---|---|
| POST | `/api/auth/register` | Registrasi pengguna |
| POST | `/api/auth/login` | Login pengguna |
| GET | `/api/earthquakes/latest` | Ambil data gempa terbaru |
| GET | `/api/earthquakes/:id/risk?lat=&lng=` | Cek status risiko tsunami berdasarkan lokasi |
| GET | `/api/evacuation/nearest?lat=&lng=` | Cari titik evakuasi terdekat |
| GET | `/api/articles` | Daftar artikel blog |
| GET | `/api/articles/:slug` | Detail artikel |
| POST | `/api/articles` | Buat artikel baru (admin) |
| POST | `/api/media/presigned-url` | Ambil URL upload S3 untuk media artikel |
| GET | `/api/emergency-contacts` | Daftar kontak darurat |

---

## 10. Milestone & Roadmap (Usulan)

| Fase | Durasi (estimasi) | Output |
|---|---|---|
| Fase 1 — Setup & Auth | 2 minggu | Setup project Flutter + Node.js + PostgreSQL, autentikasi |
| Fase 2 — Integrasi BMKG & Deteksi | 3 minggu | Dashboard gempa, deteksi risiko lokasi |
| Fase 3 — Peta & Evakuasi | 2 minggu | Fitur peta, rute evakuasi |
| Fase 4 — Notifikasi | 1 minggu | Push notification (FCM) |
| Fase 5 — Modul Blog | 2 minggu | CMS artikel + integrasi S3 |
| Fase 6 — Testing & Deployment | 2 minggu | QA, deployment Android (Play Store) & Web |

---

## 11. Metrik Keberhasilan (Success Metrics)

- Waktu rata-rata pengiriman notifikasi setelah data gempa dipublikasikan BMKG < 2 menit
- Tingkat akurasi deteksi risiko lokasi > 90% (dibandingkan data resmi BMKG)
- Jumlah pengguna aktif bulanan (MAU)
- Engagement rate pada artikel blog (jumlah baca, waktu baca)
- Rating aplikasi di Play Store ≥ 4.3

---

## 12. Risiko & Mitigasi

| Risiko | Mitigasi |
|---|---|
| API BMKG down/lambat | Implementasi caching lokal + fallback data terakhir |
| Lokasi GPS tidak akurat | Kombinasi GPS + input manual lokasi oleh pengguna |
| Beban server saat gempa besar (spike trafik) | Auto-scaling backend, gunakan CDN untuk konten statis/S3 |
| Data BMKG terlambat dibanding kejadian nyata | Tampilkan disclaimer sumber & waktu update data |
