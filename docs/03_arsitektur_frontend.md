# 03 — Arsitektur Frontend (Flutter)

## Framework & Pattern

- **Flutter** (Dart), target: Android, iOS, Web
- **State Management**: Riverpod (`flutter_riverpod`) — `StateNotifierProvider`
- **Routing**: GoRouter (`go_router`) — dengan redirect guard auth
- **HTTP Client**: Dio
- **Storage**: `flutter_secure_storage` (token, data user), `shared_preferences` (pengaturan)
- **Font**: Google Fonts (Inter)
- **Maps**: (via `/map` route)

---

## Struktur State Management (Riverpod)

### Provider yang ada saat ini

| Provider | File | State |
|----------|------|-------|
| `authStateProvider` | `auth/providers/auth_provider.dart` | `AuthState` (user, isAuthenticated, isGuest, isLoading, error) |
| `routerProvider` | `core/router/app_router.dart` | `GoRouter` instance |
| `settingsProvider` | `core/providers/settings_provider.dart` | `AppSettings` (lokasi, notif, bahasa) |
| `earthquakeProvider` | `earthquake/providers/earthquake_provider.dart` | Data gempa terkini |
| `homeDangerModeProvider` | `home/screens/home_screen.dart` | `bool` toggle bahaya manual |
| `notificationsProvider` | `notifications/providers/notifications_provider.dart` | `NotificationsState` (riwayat notifikasi, unreadCount, sync lokal/backend) |

---

## Routing (GoRouter)

File: `lib/core/router/app_router.dart`

```
/              → SplashScreen
/login         → LoginScreen
/register      → RegisterScreen
/home          → HomeScreen       (dalam ShellRoute + MainScaffold)
/map           → MapScreen        (dalam ShellRoute)
/history       → HistoryScreen    (dalam ShellRoute)
/emergency     → EmergencyScreen  (dalam ShellRoute)
/evacuation    → MapScreen        (dalam ShellRoute, fokus evakuasi)
/profile       → ProfileScreen    (dalam ShellRoute)
/notifications → NotificationHistoryScreen (riwayat notifikasi peringatan)
```

**Redirect logic:**
- Jika belum login (`!isAuthenticated && !isGuest`) → redirect ke `/login`
- Jika sudah login dan di `/login` → redirect ke `/home`

---

## AuthState & AuthNotifier

File: `lib/features/auth/providers/auth_provider.dart`

```dart
class AuthState {
  UserModel? user;
  bool isAuthenticated;
  bool isGuest;
  bool isLoading;
  String? error;
}
```

**Method AuthNotifier:**
| Method | Fungsi |
|--------|--------|
| `_init()` | Muat state dari storage saat app buka |
| `loginWithGoogle()` | Google Sign-In → kirim idToken ke backend |
| `loginWithEmail(email, pass)` | Login via backend REST API |
| `register(name, email, pass, phone?)` | Daftar via backend REST API |
| `continueAsGuest()` | Simpan `is_guest=true` ke storage |
| `logout()` | Hapus semua storage, reset state |

**Storage keys yang disimpan:**
- `user_id`, `user_name`, `user_email`, `user_avatar`, `user_role`
- `access_token`, `refresh_token`
- `is_guest`

---

## UserModel

File: `lib/shared/models/user_model.dart`

```dart
class UserModel {
  String id;
  String name;
  String email;
  String role;       // 'user' | 'admin' | 'super_admin'
  String? phone;
  String? avatarUrl;
  bool isActive;

  // Helper getters (ditambahkan pada update admin):
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';
}
```

---

## MainScaffold & Bottom Navigation

File: `lib/shared/widgets/main_scaffold.dart`

Bottom nav memiliki 5 tab:
1. **Beranda** → `/home`
2. **Peta** → `/map`
3. **Riwayat** → `/history`
4. **Darurat** → `/emergency`
5. **Profil** → `/profile`

Semua tab dibungkus dalam `ShellRoute` sehingga `MainScaffold` tidak di-rebuild saat pindah tab.

---

## Layar-Layar Utama

### HomeScreen (`home/screens/home_screen.dart`)
- Header: gradient biru (normal) / merah (bahaya)
- Data gempa real-time dari `earthquakeProvider`
- Toggle manual bahaya via `homeDangerModeProvider`
- Quick action cards (evakuasi, kontak darurat, dll)

### ProfileScreen (`profile/screens/profile_screen.dart`)
- Info user: nama, email, avatar
- Toggle pengaturan: lokasi real-time, notif sirine, mode offline
- Tombol Logout → `authNotifier.logout()`

### EmergencyScreen (`emergency/screens/emergency_screen.dart`)
- Tombol bagikan lokasi → WhatsApp / SMS
- Daftar kontak darurat (BPBD 119, SAR 115, Polisi 110, Ambulan 118)
- Kontak keluarga (placeholder)

---

## AppConstants

File: `lib/core/constants/app_constants.dart`

| Konstanta | Nilai |
|-----------|-------|
| `apiBaseUrl` | Dari `.env: API_BASE_URL` (default: `https://samudra.rizalzaky.cloud/api`) |
| `accessTokenKey` | `'access_token'` |
| `refreshTokenKey` | `'refresh_token'` |
| `tsunamiMinMagnitude` | `6.5` |
| `tsunamiRiskRadiusKm` | `500.0` |

---

## Environment Variables Frontend

File: `frontend/.env`

| Key | Fungsi |
|-----|--------|
| `API_BASE_URL` | URL backend |
| `GOOGLE_CLIENT_ID` | Google OAuth Client ID (untuk Web) |
| `GOOGLE_SERVER_CLIENT_ID` | Server client ID (untuk verifikasi idToken mobile) |
| `GOOGLE_MAPS_API_KEY` | Google Maps API |
