import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

/// Top-level background message handler wajib berada di luar kelas
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM background message received: ${message.messageId} - ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Inisialisasi Firebase Messaging & Local Notification channel
  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Inisialisasi Firebase Core (jika belum)
      await Firebase.initializeApp();

      // 2. Registrasi background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Konfigurasi Local Notifications (untuk foreground alert)
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
          // Handler navigasi ketika banner notifikasi ditekan
        },
      );

      // 4. Buat High-Priority Android Notification Channel khusus peringatan gempa/tsunami
      const androidChannel = AndroidNotificationChannel(
        'samudra_alerts',
        'Peringatan Gempa & Tsunami SAMUDRA',
        description: 'Notifikasi darurat peringatan gempa bumi dan potensi tsunami BMKG',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
      }

      // 5. Request permission ke sistem operasi (Android 13+ & iOS)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM authorization status: ${settings.authorizationStatus}');

      // 6. Dapatkan FCM Token perangkat
      _fcmToken = await messaging.getToken();
      debugPrint('Device FCM Token: $_fcmToken');

      // 7. Subscribe ke topic penting:
      await messaging.subscribeToTopic('earthquakes');
      await messaging.subscribeToTopic('tsunami_alerts');
      await messaging.subscribeToTopic('articles');
      debugPrint('Subscribed to topics: earthquakes, tsunami_alerts, articles');

      // 8. Listener jika token diperbarui (token refresh)
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        syncTokenWithBackend(newToken);
      });

      // 9. Handle notifikasi saat aplikasi berada di FOREGROUND (terbuka di layar)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message: ${message.notification?.title}');
        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                androidChannel.id,
                androidChannel.name,
                channelDescription: androidChannel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: message.data['earthquakeId'],
          );
        }
      });

      // 10. Handle notifikasi saat aplikasi dibuka dari keadaan background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from notification: ${message.data}');
        // Bisa trigger routing ke /earthquake/:id
      });

      _initialized = true;
    } catch (e) {
      debugPrint('Note: Firebase Messaging initialization deferred or google-services.json not yet added: $e');
    }
  }

  /// Kirim FCM Token ke backend agar tersimpan di profil user
  Future<void> syncTokenWithBackend([String? token]) async {
    final targetToken = token ?? _fcmToken;
    if (targetToken == null || targetToken.isEmpty) return;

    try {
      final client = ApiClient();
      client.init();
      await client.dio.patch(
        '/users/profile',
        data: {'fcmToken': targetToken},
      );
      debugPrint('FCM Token successfully synced with backend user profile.');
    } catch (e) {
      debugPrint('Failed to sync FCM Token with backend (user might not be logged in yet): $e');
    }
  }

  /// Kirim lokasi pengguna dan FCM Token sekaligus agar deteksi gempa terdekat bekerja akurat
  Future<void> syncUserLocationAndToken({
    required double latitude,
    required double longitude,
    String? token,
  }) async {
    final targetToken = token ?? _fcmToken;

    try {
      final client = ApiClient();
      client.init();
      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };
      if (targetToken != null && targetToken.isNotEmpty) {
        body['fcmToken'] = targetToken;
      }
      await client.dio.patch('/users/profile', data: body);
      debugPrint('User location ($latitude, $longitude) & FCM Token successfully synced with backend.');
    } catch (e) {
      debugPrint('Failed to sync user location with backend: $e');
    }
  }
}

// Riverpod Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
