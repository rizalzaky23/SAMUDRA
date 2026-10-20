# 06 — Sistem Role

## Definisi Role

| Role | Nilai DB | Deskripsi |
|------|----------|-----------|
| `user` | `'user'` | Pengguna biasa — default saat daftar |
| `admin` | `'admin'` | Dapat mengelola konten (artikel, mitigasi, peralatan) |
| `super_admin` | `'super_admin'` | Admin tertinggi — dapat mengangkat admin |

---

## Super Admin Pertama

- **Email**: `rizalzaky2302@gmail.com`
- Login tetap via **Google Sign-In** seperti biasa
- Role `super_admin` diberikan otomatis oleh backend saat login pertama kali:

```typescript
// Di auth.service.ts → loginWithGoogle()
const SUPER_ADMIN_EMAIL = 'rizalzaky2302@gmail.com';
if (googleUser.email === SUPER_ADMIN_EMAIL && user.role === UserRole.USER) {
  await usersService.update(user.id, { role: UserRole.SUPER_ADMIN });
}
```

---

## Cara Mengangkat Admin

Hanya bisa dilakukan oleh `super_admin`:

```
PATCH /api/users/:id/role
Authorization: Bearer <super_admin_token>
Body: { "role": "admin" }
```

Di frontend, terdapat layar **Manajemen User** yang hanya muncul untuk `super_admin`.

---

## Guard Backend

### JwtAuthGuard (global)
- Semua endpoint butuh JWT kecuali yang punya `@Public()`
- File: `src/auth/guards/jwt-auth.guard.ts`

### RolesGuard
- Dipakai bersama `@Roles()` decorator
- Cek `user.role` dari JWT vs daftar role yang diizinkan
- File: `src/auth/guards/roles.guard.ts`

```typescript
// Contoh penggunaan di controller:
@Get()
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
getAll() { ... }
```

---

## Akses Per Fitur

### Fitur User Biasa
- Lihat dashboard gempa & tsunami
- Lihat peta evakuasi
- Lihat riwayat gempa
- Kontak darurat
- Bagikan lokasi
- Edit profil sendiri
- Baca artikel (published)

### Tambahan untuk Admin
- Buat / edit / hapus artikel edukasi
- Kelola langkah mitigasi mandiri (tambah / edit / hapus)
- Kelola peralatan siaga bencana (tambah / edit / hapus)
- Lihat daftar semua user

### Tambahan untuk Super Admin
- Semua yang admin bisa
- Angkat user menjadi admin (atau cabut admin)

---

## Frontend: Tampilan Berdasarkan Role

Di Flutter, UI admin/super_admin disembunyikan menggunakan helper di `UserModel`:

```dart
// user_model.dart
bool get isAdmin => role == 'admin' || role == 'super_admin';
bool get isSuperAdmin => role == 'super_admin';
```

**Contoh penggunaan di widget:**
```dart
final user = ref.watch(authStateProvider).user;

if (user?.isAdmin == true)
  AdminPanelButton(),  // hanya tampil untuk admin+

if (user?.isSuperAdmin == true)
  UserManagementButton(),  // hanya tampil untuk super_admin
```

---

## Lokasi Kode Terkait Role

| Komponen | File |
|----------|------|
| Entity role (backend) | `backend/src/users/entities/user.entity.ts` |
| Guard roles | `backend/src/auth/guards/roles.guard.ts` |
| Decorator @Roles | `backend/src/auth/decorators/roles.decorator.ts` |
| Auto-promote super admin | `backend/src/auth/auth.service.ts` |
| UserModel helper (frontend) | `frontend/lib/shared/models/user_model.dart` |
| Simpan role ke storage | `frontend/lib/features/auth/providers/auth_provider.dart` |
| Layar Admin Panel | `frontend/lib/features/admin/` (setelah implementasi) |
| Layar Manajemen User | `frontend/lib/features/admin/screens/user_management_screen.dart` |
