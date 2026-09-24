import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kinde_flutter_sdk/kinde_flutter_sdk.dart';
import '../../../shared/models/user_model.dart';

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

// Auth Notifier (Kinde-based)
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;

  AuthNotifier(this._storage) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final kinde = KindeFlutterSDK.instance;
      final isAuth = await kinde.isAuthenticated().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (isAuth) {
        final profile = await kinde.getUserProfileV2().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
        state = AuthState(
          isAuthenticated: true,
          user: UserModel(
            id: profile?.id ?? profile?.sub ?? '',
            name: profile?.name ??
                [profile?.givenName, profile?.familyName]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(' '),
            email: profile?.email ?? '',
          ),
        );
      } else {
        final savedName = await _storage.read(key: 'user_name');
        if (savedName != null && savedName.isNotEmpty) {
          final savedEmail = await _storage.read(key: 'user_email') ?? '';
          state = AuthState(
            isAuthenticated: true,
            user: UserModel(id: 'usr-rz', name: savedName, email: savedEmail),
          );
          return;
        }

        final isGuest = await _storage.read(key: 'is_guest');
        if (isGuest == 'true') {
          state = const AuthState(isGuest: true);
        }
      }
    } catch (_) {
      try {
        final savedName = await _storage.read(key: 'user_name');
        if (savedName != null && savedName.isNotEmpty) {
          final savedEmail = await _storage.read(key: 'user_email') ?? '';
          state = AuthState(
            isAuthenticated: true,
            user: UserModel(id: 'usr-rz', name: savedName, email: savedEmail),
          );
          return;
        }

        final isGuest = await _storage.read(key: 'is_guest');
        if (isGuest == 'true') {
          state = const AuthState(isGuest: true);
        }
      } catch (_) {}
    }
  }

  /// Opens Kinde login flow (browser redirect / webview)
  Future<void> loginWithKinde({String? connectionId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final kinde = KindeFlutterSDK.instance;
      final token = await kinde.login(
        additionalParams: AdditionalParameters(
          connectionId: connectionId,
        ),
      );
      if (token != null) {
        final profile = await kinde.getUserProfileV2();
        await _storage.delete(key: 'is_guest');
        state = AuthState(
          isAuthenticated: true,
          user: UserModel(
            id: profile?.id ?? profile?.sub ?? '',
            name: profile?.name ??
                [profile?.givenName, profile?.familyName]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(' '),
            email: profile?.email ?? '',
          ),
        );
      } else {
        // User cancelled login
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      final msg = e.toString();
      final displayError = msg.contains('User cancelled')
          ? 'Login dibatalkan.'
          : 'Login Kinde gagal. Pastikan Callback URL sudah diizinkan di dashboard Kinde.';
      state = state.copyWith(
        isLoading: false,
        error: displayError,
      );
    }
  }

  /// Opens Kinde register flow (browser redirect / webview)
  Future<void> registerWithKinde({String? connectionId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final kinde = KindeFlutterSDK.instance;
      final token = await kinde.register(
        additionalParams: AdditionalParameters(
          connectionId: connectionId,
        ),
      );
      if (token != null) {
        final profile = await kinde.getUserProfileV2();
        await _storage.delete(key: 'is_guest');
        state = AuthState(
          isAuthenticated: true,
          user: UserModel(
            id: profile?.id ?? profile?.sub ?? '',
            name: profile?.name ??
                [profile?.givenName, profile?.familyName]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(' '),
            email: profile?.email ?? '',
          ),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      final msg = e.toString();
      final displayError = msg.contains('User cancelled')
          ? 'Pendaftaran dibatalkan.'
          : 'Pendaftaran Kinde gagal. Pastikan Callback URL sudah diatur di dashboard Kinde.';
      state = state.copyWith(
        isLoading: false,
        error: displayError,
      );
    }
  }

  Future<void> loginDirectly({String? name, String? email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 200));
    final user = UserModel(
      id: 'usr-rz',
      name: name ?? 'Rizal Zaky',
      email: email ?? 'rizalzaky@gmail.com',
    );
    await _storage.write(key: 'user_name', value: user.name);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.delete(key: 'is_guest');
    state = AuthState(
      isAuthenticated: true,
      user: user,
    );
  }

  Future<void> continueAsGuest() async {
    await _storage.write(key: 'is_guest', value: 'true');
    state = const AuthState(isGuest: true);
  }

  Future<void> logout() async {
    try {
      final kinde = KindeFlutterSDK.instance;
      await kinde.logout();
    } catch (_) {}
    await _storage.deleteAll();
    state = const AuthState();
  }
}

// Providers
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(const FlutterSecureStorage());
});
