import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/notification_service.dart';
import '../../earthquake/providers/earthquake_provider.dart';
import '../models/notification_model.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref _ref;
  StreamSubscription<NotificationModel>? _streamSub;

  NotificationsNotifier(this._ref) : super(const NotificationsState()) {
    _init();
  }

  void _init() {
    // Muat riwayat awal
    loadNotifications();

    // Dengarkan notifikasi baru yang masuk secara realtime
    _streamSub = NotificationService.onNewNotification.stream.listen((item) {
      final exists = state.notifications.any((n) => n.id == item.id);
      if (!exists) {
        state = state.copyWith(
          notifications: [item, ...state.notifications],
        );
      }
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  /// Muat riwayat notifikasi dari penyimpanan lokal dan backend
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);

    // 1. Muat dari lokal terlebih dahulu agar UI instan
    final localItems = await NotificationService.getStoredNotifications();
    if (localItems.isNotEmpty) {
      state = state.copyWith(notifications: localItems, isLoading: false);
    }

    // 2. Tarik log riwayat dari backend
    try {
      final client = ApiClient();
      client.init();

      final response = await client.dio.get(
        '/notifications/logs',
        queryParameters: {'limit': 40},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.data is List) {
        final List rawList = response.data;
        final remoteItems = rawList
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // 3. Gabungkan remote dan local, singkirkan duplikat
        final Map<String, NotificationModel> map = {};

        // Masukkan remote items dulu
        for (final item in remoteItems) {
          map[item.id] = item;
        }

        // Masukkan local items (bisa menimpa status isRead jika sudah dibaca lokal)
        for (final item in localItems) {
          if (map.containsKey(item.id)) {
            // Jika di lokal sudah ditandai dibaca, pertahankan status isRead
            map[item.id] = map[item.id]!.copyWith(isRead: item.isRead);
          } else {
            map[item.id] = item;
          }
        }

        final merged = map.values.toList()
          ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

        // Simpan versi gabungan ke lokal agar offline tetap lengkap
        for (final item in merged.take(30)) {
          await NotificationService.saveNotification(item);
        }

        state = state.copyWith(
          notifications: merged,
          isLoading: false,
        );
        return;
      }
    } catch (e) {
      debugPrint('Load backend notifications note: $e');
    }

    // 4. Jika lokal dan remote sama-sama kosong, gunakan data peringatan gempa terkini
    if (state.notifications.isEmpty) {
      try {
        final eqAsync = _ref.read(earthquakeProvider);
        eqAsync.whenData((risk) {
          final eq = risk.earthquake;
          final isTsunami = eq.potentialTsunami;
          final title = isTsunami
              ? '🚨 PERINGATAN POTENSI TSUNAMI (M ${eq.magnitude})'
              : '⚠️ Gempa Bumi Terkini (M ${eq.magnitude})';
          final body = isTsunami
              ? 'Wilayah ${eq.region}. BMKG menyatakan berpotensi tsunami. Segera evakuasi ke tempat tinggi!'
              : 'Gempa kedalaman ${eq.depthKm} km terjadi di ${eq.region}. Tetap tenang dan waspada.';

          final fallback = NotificationModel(
            id: 'bmkg_${eq.id.isNotEmpty ? eq.id : DateTime.now().millisecondsSinceEpoch}',
            title: title,
            body: body,
            type: isTsunami ? 'tsunami_alert' : 'earthquake',
            sentAt: DateTime.tryParse(eq.occurredAt) ?? DateTime.now(),
            isRead: false,
            data: {
              'magnitude': eq.magnitude,
              'depthKm': eq.depthKm,
              'region': eq.region,
              'potentialTsunami': isTsunami.toString(),
            },
          );

          NotificationService.saveNotification(fallback);
          state = state.copyWith(notifications: [fallback], isLoading: false);
        });
      } catch (_) {}
    }

    state = state.copyWith(isLoading: false);
  }

  /// Tandai satu notifikasi sebagai dibaca
  Future<void> markAsRead(String id) async {
    await NotificationService.markAsRead(id);
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList(),
    );
  }

  /// Tandai semua sebagai telah dibaca
  Future<void> markAllAsRead() async {
    await NotificationService.markAllAsRead();
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  /// Bersihkan semua riwayat notifikasi
  Future<void> clearAll() async {
    await NotificationService.clearAllNotifications();
    state = state.copyWith(notifications: const []);
  }

  /// Tambahkan notifikasi secara manual
  Future<void> addNotification(NotificationModel item) async {
    await NotificationService.saveNotification(item);
    state = state.copyWith(
      notifications: [item, ...state.notifications],
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});
