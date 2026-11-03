import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../../features/notifications/models/notification_model.dart';

/// Top-level background message handler wajib berada di luar kelas
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM background message received: ${message.messageId} - ${message.notification?.title}');
  await NotificationService.saveRemoteMessageLocally(message);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String storageKey = 'samudra_local_notifications_v1';
  static final StreamController<NotificationModel> onNewNotification =
      StreamController<NotificationModel>.broadcast();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Simpan notifikasi dari RemoteMessage FCM ke penyimpanan lokal
  static Future<NotificationModel?> saveRemoteMessageLocally(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? message.data['title'] ?? 'Peringatan SAMUDRA';
      final body = message.notification?.body ?? message.data['body'] ?? 'Informasi peringatan bencana BMKG';
      final type = message.data['type'] ?? (title.toLowerCase().contains('tsunami') ? 'tsunami_alert' : 'info');

      final item = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        sentAt: message.sentTime ?? DateTime.now(),
        isRead: false,
        data: message.data,
      );

      await saveNotification(item);
      onNewNotification.add(item);
      return item;
    } catch (e) {
      debugPrint('Failed to save notification locally: $e');
      return null;
    }
  }

  /// Simpan satu item notifikasi ke SharedPreferences
  static Future<void> saveNotification(NotificationModel item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(storageKey) ?? [];

      // Hindari duplikasi ID
      final updated = <String>[jsonEncode(item.toJson())];
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded['id']?.toString() != item.id) {
            updated.add(raw);
          }
        } catch (_) {}
      }

      // Simpan maksimal 100 riwayat notifikasi lokal
      await prefs.setStringList(storageKey, updated.take(100).toList());
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  /// Ambil riwayat notifikasi yang tersimpan di lokal
  static Future<List<NotificationModel>> getStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(storageKey) ?? [];
      final list = <NotificationModel>[];

      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw);
          list.add(NotificationModel.fromJson(map));
        } catch (_) {}
      }
      return list;
    } catch (e) {
      debugPrint('Error loading stored notifications: $e');
      return [];
    }
  }

  /// Tandai notifikasi spesifik sebagai dibaca
  static Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(storageKey) ?? [];
      final updated = <String>[];

      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          if (map['id']?.toString() == id) {
            map['isRead'] = true;
          }
          updated.add(jsonEncode(map));
        } catch (_) {
          updated.add(raw);
        }
      }
      await prefs.setStringList(storageKey, updated);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Tandai semua notifikasi lokal sebagai dibaca
  static Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(storageKey) ?? [];
      final updated = <String>[];

      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          map['isRead'] = true;
          updated.add(jsonEncode(map));
        } catch (_) {
          updated.add(raw);
        }
      }
      await prefs.setStringList(storageKey, updated);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Hapus semua riwayat notifikasi lokal
  static Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

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
      // ignore: deprecated_member_use
      _fcmToken = await messaging.getToken();
      debugPrint('Device FCM Token: $_fcmToken');

      // 7. Subscribe ke topic penting:
      await messaging.subscribeToTopic('earthquakes');
      await messaging.subscribeToTopic('tsunami_alerts');
      await messaging.subscribeToTopic('articles');
      debugPrint('Subscribed to topics: earthquakes, tsunami_alerts, articles');

      // 8. Listener jika token diperbarui (token refresh)
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        syncTokenWithBackend(newToken);
      });

      // 9. Handle notifikasi saat aplikasi berada di FOREGROUND (terbuka di layar)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Foreground message: ${message.notification?.title}');
        await saveRemoteMessageLocally(message);
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
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        debugPrint('App opened from notification: ${message.data}');
        await saveRemoteMessageLocally(message);
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
