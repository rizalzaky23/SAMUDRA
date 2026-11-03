# 08 — Changelog

> Log semua perubahan penting pada codebase. Format: tanggal, file yang diubah, deskripsi singkat.

---

## [2026-11-03] — Sinkronisasi Profil Google & Riwayat Notifikasi Beranda

### Frontend

#### `lib/features/home/screens/home_screen.dart`
- **Diubah**: Mengganti avatar dummy "AR" di header beranda dengan foto akun Google pengguna (`CachedNetworkImage`) atau inisial nama dinamis dari akun pengguna yang login.
- **Diubah**: Menambahkan navigasi `context.push(AppRoutes.profile)` saat avatar ditekan.
- **Diubah**: Mengaktifkan tombol lonceng notifikasi di beranda dengan `context.push(AppRoutes.notifications)`.
- **Diubah**: Menampilkan badge indikator unread notifikasi aktif pada tombol lonceng notifikasi di beranda.

#### `lib/features/notifications/models/notification_model.dart` *(baru)*
- **Baru**: Model `NotificationModel` untuk parsing data notifikasi (tsunami alert, earthquake, artikel baru, sistem), tanggal penerimaan, dan status dibaca.

#### `lib/core/services/notification_service.dart`
- **Diubah**: Menambahkan penyimpanan riwayat notifikasi lokal ke `SharedPreferences` saat push notification diterima (foreground, background, app opened).
- **Diubah**: Menambahkan stream controller `onNewNotification` untuk update realtime UI saat notifikasi masuk.

#### `lib/features/notifications/providers/notifications_provider.dart` *(baru)*
- **Baru**: Provider Riverpod `notificationsProvider` yang menggabungkan riwayat notifikasi lokal dan sinkronisasi REST API backend (`/notifications/logs`), penghitung `unreadCount`, serta fungsi tandai dibaca dan hapus riwayat.

#### `lib/features/notifications/screens/notification_screen.dart` *(baru)*
- **Baru**: Halaman `NotificationHistoryScreen` lengkap dengan filter ("Semua", "Peringatan", "Edukasi & Info"), kartu visual alert gempa/tsunami, relative timestamp ("X menit lalu"), swipe dismiss, pull-to-refresh, dan menu tandai semua dibaca.

#### `lib/core/router/app_router.dart`
- **Diubah**: Menambahkan route `AppRoutes.notifications = '/notifications'` menuju `NotificationHistoryScreen`.

#### `lib/features/auth/providers/auth_provider.dart`
- **Diubah**: Sinkronisasi foto profil (`avatarUrl`) dan nama akun saat Google Sign-In dan auto-refresh background pada `_init()`.

### Backend

#### `src/notifications/entities/notification-log.entity.ts`
- **Diubah**: Menambahkan kolom `title`, `body`, `type`, dan `payloadData` pada entity `NotificationLog`.

#### `src/notifications/notifications.service.ts`
- **Diubah**: Memperbarui `recordLog()` untuk menyimpan judul, isi pesan, tipe alert, dan data payload secara lengkap.
- **Diubah**: Memperbarui `getLogs()` agar user reguler dapat melihat notifikasi publik (tsunami/gempa/artikel) dan notifikasi personal mereka.
- **Diubah**: Auto-seed notifikasi dari data gempa terkini jika riwayat notifikasi awal masih kosong.

#### `src/notifications/notifications.controller.ts`
- **Diubah**: Menambahkan decorator `@Public()` pada endpoint `GET /notifications/logs` sehingga dapat diakses baik oleh user login maupun tamu (guest).

#### `src/auth/auth.service.ts`
- **Diubah**: Memperbarui avatar dan nama user yang sudah ada ketika login Google menyertakan foto profil terbaru.

---

## [2026-10-20] — Penambahan Sistem Role Admin & Super Admin

### Backend

#### `src/users/entities/user.entity.ts`
- **Diubah**: Enum `UserRole` ditambah nilai `SUPER_ADMIN = 'super_admin'`
- Sebelumnya: `USER`, `ADMIN`, `EDITOR`
- Sesudahnya: `USER`, `ADMIN`, `SUPER_ADMIN`

#### `src/auth/auth.service.ts`
- **Diubah**: Method `loginWithGoogle()` dan `loginWithGoogleIdToken()`
- Tambahan: Auto-promote email `rizalzaky2302@gmail.com` ke `SUPER_ADMIN` saat login pertama kali

#### `src/users/users.service.ts`
- **Diubah**: Tambah method `updateRole(userId, role)` untuk mengubah role user
- **Diubah**: Tambah method `findAllWithPagination()` untuk super admin

#### `src/users/users.controller.ts`
- **Diubah**: Tambah endpoint `PATCH /users/:id/role` dengan guard `@Roles(UserRole.SUPER_ADMIN)`

#### `src/articles/articles.controller.ts` *(baru)*
- **Baru**: Full CRUD artikel dengan guard `@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)` untuk write operations

#### `src/articles/articles.service.ts` *(baru)*
- **Baru**: Service CRUD artikel, auto-generate slug, set publishedAt saat publish

#### `src/articles/articles.module.ts` *(baru)*
- **Baru**: Module artikel dengan TypeORM repository

#### `src/emergency/entities/mitigasi-step.entity.ts` *(baru)*
- **Baru**: Entity untuk langkah mitigasi mandiri

#### `src/emergency/entities/peralatan-siaga.entity.ts` *(baru)*
- **Baru**: Entity untuk peralatan siaga bencana

#### `src/emergency/emergency.controller.ts` *(baru)*
- **Baru**: CRUD mitigasi & peralatan (admin+ untuk write, public untuk read)

#### `src/emergency/emergency.service.ts` *(baru)*
- **Baru**: Service CRUD mitigasi & peralatan

#### `src/emergency/emergency.module.ts` *(baru)*
- **Baru**: Module emergency dengan TypeORM repository

#### `src/app.module.ts`
- **Diubah**: Import tambahan `ArticlesModule` dan `EmergencyModule`

---

### Frontend

#### `lib/shared/models/user_model.dart`
- **Diubah**: Tambah getter helper `isAdmin` dan `isSuperAdmin`
- `isAdmin` → true jika role `admin` atau `super_admin`
- `isSuperAdmin` → true jika role `super_admin`

#### `lib/features/auth/providers/auth_provider.dart`
- **Diubah**: Method `_init()` — muat `user_role` dari storage
- **Diubah**: Method `loginWithGoogle()` & `loginWithEmail()` — simpan `user_role` ke storage
- **Diubah**: Method `register()` — simpan `user_role` ke storage

#### `lib/core/router/app_router.dart`
- **Diubah**: Tambah rute baru:
  - `/admin` → `AdminDashboardScreen`
  - `/admin/articles` → `AdminArticlesScreen`
  - `/admin/mitigasi` → `AdminMitigasiScreen`
  - `/admin/peralatan` → `AdminPeralatanScreen`
  - `/admin/users` → `AdminUsersScreen` (super_admin only)

#### `lib/features/admin/` *(folder baru)*
- **Baru**: Folder fitur admin
  - `screens/admin_dashboard_screen.dart` — Dashboard panel admin & navigasi menu
  - `screens/admin_articles_screen.dart` — CRUD artikel edukasi tsunami
  - `screens/admin_mitigasi_screen.dart` — CRUD langkah mitigasi mandiri
  - `screens/admin_peralatan_screen.dart` — CRUD peralatan siaga bencana
  - `screens/admin_users_screen.dart` — Manajemen pengguna & pengangkatan admin (super_admin)
  - `providers/admin_provider.dart` — State management & Dio API calls untuk admin

#### `lib/features/profile/screens/profile_screen.dart`
- **Diubah**: Tampilan tetap normal untuk user biasa, hanya muncul section **"Panel Admin"** jika `user.isAdmin` / `user.isSuperAdmin`
- **Diubah**: "Langkah evakuasi mandiri" & "Peralatan siaga bencana" kini membuka bottom sheet interaktif yang mengambil data mitigasi dan perlengkapan dari API backend (bukan lagi placeholder "segera hadir")

---

## [Sebelum 2026-10-20] — State Awal

### Fitur yang sudah ada saat proyek dimulai

**Backend:**
- Auth (register, login email, Google OAuth Web & Mobile)
- User profile CRUD
- Earthquake data (polling BMKG XML, simpan ke DB)
- Scheduled task (cron polling 60 detik)
- Article entity (tanpa controller)
- JWT access+refresh token

**Frontend:**
- Auth (Google Sign-In, email login, register, guest mode)
- Home screen dengan header status gempa & tsunami
- Map screen
- History screen (riwayat gempa)
- Emergency screen (kontak darurat, bagikan lokasi)
- Profile screen (info user, pengaturan, logout)
- Bottom navigation (5 tab)
- Routing dengan GoRouter + redirect guard

---

## Cara Mengisi Changelog Ini

Setiap kali mengubah kode, tambahkan entri di atas dengan format:

```markdown
## [YYYY-MM-DD] — Judul Perubahan Singkat

### Backend / Frontend / Both

#### `path/ke/file.ts`
- **Baru** / **Diubah** / **Dihapus**: Deskripsi singkat apa yang berubah
```
