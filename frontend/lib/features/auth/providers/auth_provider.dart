import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

// Auth State
class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isGuest;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isGuest = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isGuest,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Auth Notifier (Google Sign-In based)
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  late final GoogleSignIn _googleSignIn;

  AuthNotifier(this._storage) : super(const AuthState()) {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    );
    _init();
  }

  Future<void> _init() async {
    try {
      // Check if user was previously logged in via saved credentials
      final savedName = await _storage.read(key: 'user_name');
      if (savedName != null && savedName.isNotEmpty) {
        final savedEmail = await _storage.read(key: 'user_email') ?? '';
        final savedId = await _storage.read(key: 'user_id') ?? '';
        final savedAvatar = await _storage.read(key: 'user_avatar');
        state = AuthState(
          isAuthenticated: true,
          user: UserModel(
            id: savedId,
            name: savedName,
            email: savedEmail,
            avatarUrl: savedAvatar,
          ),
        );
        return;
      }

      // Check guest mode
      final isGuest = await _storage.read(key: 'is_guest');
      if (isGuest == 'true') {
        state = const AuthState(isGuest: true);
      }
    } catch (_) {
      // Silent init failure — user lands on login
    }
  }

  /// Google Sign-In → send idToken to backend → receive JWT
  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        state = state.copyWith(isLoading: false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken != null) {
        // Send idToken to backend for verification & JWT exchange
        try {
          final dio = Dio();
          final response = await dio.post(
            '${AppConstants.apiBaseUrl}/auth/google/token',
            data: {'idToken': idToken},
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data;
            // Save backend tokens
            if (data['accessToken'] != null) {
              await _storage.write(
                  key: AppConstants.accessTokenKey,
                  value: data['accessToken']);
            }
            if (data['refreshToken'] != null) {
              await _storage.write(
                  key: AppConstants.refreshTokenKey,
                  value: data['refreshToken']);
            }
          }
        } catch (e) {
          debugPrint('Backend token exchange skipped: $e');
          // Continue with Google profile even if backend is unavailable
        }
      }

      // Build user from Google account info
      final user = UserModel(
        id: account.id,
        name: account.displayName ?? account.email.split('@').first,
        email: account.email,
        avatarUrl: account.photoUrl,
      );

      // Persist user data locally
      await _storage.write(key: 'user_id', value: user.id);
      await _storage.write(key: 'user_name', value: user.name);
      await _storage.write(key: 'user_email', value: user.email);
      if (user.avatarUrl != null) {
        await _storage.write(key: 'user_avatar', value: user.avatarUrl!);
      }
      await _storage.delete(key: 'is_guest');

      state = AuthState(
        isAuthenticated: true,
        user: user,
      );
    } catch (e, stack) {
      debugPrint('Google Sign-In Error: $e');
      debugPrint('Stack: $stack');
      final msg = e.toString();
      String displayError;
      if (msg.contains('sign_in_canceled') ||
          msg.contains('canceled') ||
          msg.contains('cancelled')) {
        displayError = 'Login dibatalkan.';
      } else if (msg.contains('network_error') ||
          msg.contains('ApiException: 7')) {
        displayError = 'Tidak ada koneksi internet. Coba lagi nanti.';
      } else if (msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR')) {
        displayError =
            'Google OAuth Error (10): Pastikan SHA-1 & Package Name (com.samudra.samudra) sudah didaftarkan di Google Cloud Console.';
      } else if (msg.contains('ApiException: 12500')) {
        displayError =
            'Google OAuth Error (12500): Akun Google belum login di emulator/perangkat atau Google Play Services bermasalah.';
      } else {
        displayError = 'Login Google gagal: $msg';
      }
      state = state.copyWith(
        isLoading: false,
        error: displayError,
      );
    }
  }

  /// Login dengan email & kata sandi via Backend API
  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = Dio();
      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      ).timeout(const Duration(seconds: 10));

      final data = response.data;
      if (data['accessToken'] != null) {
        await _storage.write(
            key: AppConstants.accessTokenKey,
            value: data['accessToken']);
      }
      if (data['refreshToken'] != null) {
        await _storage.write(
            key: AppConstants.refreshTokenKey,
            value: data['refreshToken']);
      }

      final userData = data['user'] ?? {};
      final user = UserModel(
        id: userData['id']?.toString() ?? '',
        name: userData['name'] ?? userData['email']?.toString().split('@').first ?? 'User',
        email: userData['email'] ?? email,
        avatarUrl: userData['avatarUrl'],
      );

      await _storage.write(key: 'user_id', value: user.id);
      await _storage.write(key: 'user_name', value: user.name);
      await _storage.write(key: 'user_email', value: user.email);
      if (user.avatarUrl != null) {
        await _storage.write(key: 'user_avatar', value: user.avatarUrl!);
      }
      await _storage.delete(key: 'is_guest');

      state = AuthState(
        isAuthenticated: true,
        user: user,
      );
    } on DioException catch (e) {
      String displayError = 'Gagal masuk. Periksa kembali email dan kata sandi.';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        final m = e.response?.data['message'];
        displayError = m is List ? m.join(', ') : m.toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        displayError = 'Tidak dapat terhubung ke server backend.';
      }
      state = state.copyWith(
        isLoading: false,
        error: displayError,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  /// Register dengan email & kata sandi
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = Dio();
      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      ).timeout(const Duration(seconds: 10));

      final data = response.data;
      if (data['accessToken'] != null) {
        await _storage.write(
            key: AppConstants.accessTokenKey,
            value: data['accessToken']);
      }
      if (data['refreshToken'] != null) {
        await _storage.write(
            key: AppConstants.refreshTokenKey,
            value: data['refreshToken']);
      }

      final userData = data['user'] ?? {};
      final user = UserModel(
        id: userData['id']?.toString() ?? '',
        name: userData['name'] ?? name,
        email: userData['email'] ?? email,
        phone: userData['phone'] ?? phone,
        avatarUrl: userData['avatarUrl'],
      );

      await _storage.write(key: 'user_id', value: user.id);
      await _storage.write(key: 'user_name', value: user.name);
      await _storage.write(key: 'user_email', value: user.email);
      if (user.avatarUrl != null) {
        await _storage.write(key: 'user_avatar', value: user.avatarUrl!);
      }
      await _storage.delete(key: 'is_guest');

      state = AuthState(
        isAuthenticated: true,
        user: user,
      );
    } on DioException catch (e) {
      String displayError = 'Gagal mendaftar. Periksa kembali data Anda.';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        final m = e.response?.data['message'];
        displayError = m is List ? m.join(', ') : m.toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        displayError = 'Tidak dapat terhubung ke server backend.';
      }
      state = state.copyWith(
        isLoading: false,
        error: displayError,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  Future<void> continueAsGuest() async {
    await _storage.write(key: 'is_guest', value: 'true');
    state = const AuthState(isGuest: true);
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _storage.deleteAll();
    state = const AuthState();
  }
}

// Providers
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(const FlutterSecureStorage());
});
