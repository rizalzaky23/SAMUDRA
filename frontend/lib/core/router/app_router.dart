import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/emergency/screens/emergency_screen.dart';
import '../../features/earthquake/screens/history_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_articles_screen.dart';
import '../../features/admin/screens/admin_mitigasi_screen.dart';
import '../../features/admin/screens/admin_peralatan_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/notifications/screens/notification_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const map = '/map';
  static const history = '/history';
  static const emergency = '/emergency';
  static const evacuation = '/evacuation';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const admin = '/admin';
  static const adminArticles = '/admin/articles';
  static const adminMitigasi = '/admin/mitigasi';
  static const adminPeralatan = '/admin/peralatan';
  static const adminUsers = '/admin/users';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated || authState.isGuest;
      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.splash,
      ].contains(state.matchedLocation);

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && state.matchedLocation == AppRoutes.login) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.map,
            builder: (_, __) => const MapScreen(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (_, __) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.emergency,
            builder: (_, __) => const EmergencyScreen(),
          ),
          GoRoute(
            path: AppRoutes.evacuation,
            builder: (_, __) => const MapScreen(), // map with evacuation focus
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminArticles,
        builder: (_, __) => const AdminArticlesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminMitigasi,
        builder: (_, __) => const AdminMitigasiScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPeralatan,
        builder: (_, __) => const AdminPeralatanScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (_, __) => const AdminUsersScreen(),
      ),
    ],
  );
});
