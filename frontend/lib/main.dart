import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kinde_flutter_sdk/kinde_flutter_sdk.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safe .env load
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Note: .env load skipped or not found: $e');
  }

  // Safe Kinde SDK initialization with fallbacks
  try {
    final domain = dotenv.env['KINDE_AUTH_DOMAIN'] ?? 'https://rizalzaky.kinde.com';
    final clientId = dotenv.env['KINDE_AUTH_CLIENT_ID'] ?? '826e5341fc1e4c31a81cb521abf9da26';
    final loginRedirect = dotenv.env['KINDE_LOGIN_REDIRECT_URI'] ?? 'com.kinde.myapp://kinde_callback';
    final logoutRedirect = dotenv.env['KINDE_LOGOUT_REDIRECT_URI'] ?? 'com.kinde.myapp://kinde_logoutcallback';
    final rawAudience = dotenv.env['KINDE_AUDIENCE'];
    final audience = (rawAudience != null && rawAudience.trim().isNotEmpty) ? rawAudience.trim() : null;

    await KindeFlutterSDK.initializeSDK(
      authDomain: domain,
      authClientId: clientId,
      loginRedirectUri: loginRedirect,
      logoutRedirectUri: logoutRedirect,
      audience: audience,
      scopes: const ['email', 'profile', 'offline', 'openid'],
    );
  } catch (e) {
    debugPrint('Note: Kinde SDK initialization: $e');
  }

  // Lock to portrait
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Light status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (_) {}

  runApp(
    const ProviderScope(
      child: SamudraApp(),
    ),
  );
}

class SamudraApp extends ConsumerWidget {
  const SamudraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SAMUDRA — Deteksi Tsunami',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
