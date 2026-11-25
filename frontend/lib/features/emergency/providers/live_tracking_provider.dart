import 'dart:async';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../models/family_contact_model.dart';
import 'family_contacts_provider.dart';

class LiveTrackingState {
  final bool isActive;
  final bool isStarting;
  final String? sessionId;
  final FamilyContact? activeContact;
  final Position? lastPosition;
  final int? batteryLevel;
  final DateTime? lastSentAt;
  final String? errorMessage;

  const LiveTrackingState({
    this.isActive = false,
    this.isStarting = false,
    this.sessionId,
    this.activeContact,
    this.lastPosition,
    this.batteryLevel,
    this.lastSentAt,
    this.errorMessage,
  });

  LiveTrackingState copyWith({
    bool? isActive,
    bool? isStarting,
    String? sessionId,
    FamilyContact? activeContact,
    Position? lastPosition,
    int? batteryLevel,
    DateTime? lastSentAt,
    String? errorMessage,
  }) {
    return LiveTrackingState(
      isActive: isActive ?? this.isActive,
      isStarting: isStarting ?? this.isStarting,
      sessionId: sessionId ?? this.sessionId,
      activeContact: activeContact ?? this.activeContact,
      lastPosition: lastPosition ?? this.lastPosition,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      errorMessage: errorMessage,
    );
  }
}

class LiveTrackingNotifier extends StateNotifier<LiveTrackingState> {
  final Dio _dio = Dio();
  final Battery _battery = Battery();
  StreamSubscription<Position>? _positionSub;
  Timer? _heartbeatTimer;

  LiveTrackingNotifier() : super(const LiveTrackingState());

  String _generateSessionId() {
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    final time = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return 'track-$time-$rand';
  }

  /// Ambil persentase baterai HP terkini
  Future<int?> _getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return null;
    }
  }

  /// Mulai sesi live tracking & buka WhatsApp keluarga
  Future<bool> startLiveTracking(FamilyContact contact) async {
    state = state.copyWith(isStarting: true, errorMessage: null);

    try {
      // 1. Dapatkan izin & posisi GPS awal
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isStarting: false,
          errorMessage: 'Layanan lokasi/GPS di HP Anda belum aktif.',
        );
        return false;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        state = state.copyWith(
          isStarting: false,
          errorMessage: 'Izin akses lokasi ditolak oleh pengguna.',
        );
        return false;
      }

      Position? initialPos;
      try {
        initialPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        initialPos = await Geolocator.getLastKnownPosition();
      }

      if (initialPos == null) {
        state = state.copyWith(
          isStarting: false,
          errorMessage: 'Gagal mendapatkan titik koordinat GPS.',
        );
        return false;
      }

      // 2. Buat ID sesi pelacakan unik
      final sessionId = _generateSessionId();

      // Dapatkan nama pengguna jika ada di storage
      String userName = 'Pengguna SAMUDRA';
      try {
        const storage = FlutterSecureStorage();
        final savedName = await storage.read(key: 'user_name');
        if (savedName != null && savedName.isNotEmpty) {
          userName = savedName;
        }
      } catch (_) {}

      // Dapatkan level baterai HP saat ini
      final batteryLvl = await _getBatteryLevel();

      // 3. Kirim data awal ke Backend SAMUDRA
      await _sendCoordinateToBackend(
        sessionId: sessionId,
        userName: userName,
        latitude: initialPos.latitude,
        longitude: initialPos.longitude,
        speed: initialPos.speed,
        heading: initialPos.heading,
        batteryLevel: batteryLvl,
        status: 'active',
      );

      // 4. Cari nama alamat/area sekitar
      String? addressText;
      try {
        final placemarks = await Geocoding()
            .placemarkFromCoordinates(initialPos.latitude, initialPos.longitude)
            .timeout(const Duration(seconds: 3));
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.subLocality,
            p.locality,
            p.subAdministrativeArea,
          ].where((s) => s != null && s.toString().trim().isNotEmpty).toList();
          if (parts.isNotEmpty) {
            addressText = parts.join(', ');
          }
        }
      } catch (_) {}

      // 5. Susun pesan darurat dengan link LIVE TRACKER samudra.buzz/live
      final liveUrl = 'https://samudra.buzz/live/$sessionId';
      final cleanPhone = FamilyContactsNotifier.formatPhoneForWhatsApp(contact.phone);

      final msg = StringBuffer();
      msg.writeln('🚨 *DARURAT SAMUDRA — PEMANTAUAN LIVE LOCATION* 🚨');
      msg.writeln('Halo *${contact.name}*, saya membutuhkan pertolongan darurat!');
      msg.writeln();
      msg.writeln('🔴 *KLIK LINK PETA LIVE TRACKER (BERGERAK REAL-TIME):*');
      msg.writeln(liveUrl);
      msg.writeln();
      msg.writeln('📍 *Koordinat Titik Awal:*');
      msg.writeln('${initialPos.latitude}, ${initialPos.longitude}');
      if (addressText != null) {
        msg.writeln('Area: $addressText');
      }
      if (batteryLvl != null) {
        msg.writeln('🔋 Baterai HP: $batteryLvl%');
      }
      msg.writeln();
      msg.writeln('_(Buka link di atas di browser Anda untuk melihat pergerakan posisi saya secara langsung di peta SAMUDRA)_');

      final encoded = Uri.encodeComponent(msg.toString());
      final waDirectUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded');
      final waWebUri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');

      if (await canLaunchUrl(waDirectUri)) {
        await launchUrl(waDirectUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(waWebUri)) {
        await launchUrl(waWebUri, mode: LaunchMode.externalApplication);
      } else {
        final smsUri = Uri.parse('sms:$cleanPhone?body=$encoded');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      }

      // 6. Aktifkan background GPS Stream di HP
      _startTrackingStream(sessionId, userName);

      state = state.copyWith(
        isActive: true,
        isStarting: false,
        sessionId: sessionId,
        activeContact: contact,
        lastPosition: initialPos,
        batteryLevel: batteryLvl,
        lastSentAt: DateTime.now(),
      );

      return true;
    } catch (e) {
      debugPrint('Error starting live tracking: $e');
      state = state.copyWith(
        isStarting: false,
        errorMessage: 'Terjadi kendala saat memulai Live Tracking: $e',
      );
      return false;
    }
  }

  void _startTrackingStream(String sessionId, String userName) {
    _positionSub?.cancel();
    _heartbeatTimer?.cancel();

    // Stream posisi saat berpindah minimal 5 meter
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((position) async {
      final batteryLvl = await _getBatteryLevel();
      state = state.copyWith(
        lastPosition: position,
        batteryLevel: batteryLvl,
        lastSentAt: DateTime.now(),
      );

      await _sendCoordinateToBackend(
        sessionId: sessionId,
        userName: userName,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        heading: position.heading,
        batteryLevel: batteryLvl,
        status: 'active',
      );
    });

    // Heartbeat berkala tiap 12 detik (untuk memastikan server tetap menerima status)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      final currentPos = state.lastPosition;
      if (currentPos != null && state.isActive) {
        final batteryLvl = await _getBatteryLevel();
        if (batteryLvl != null) {
          state = state.copyWith(batteryLevel: batteryLvl);
        }
        await _sendCoordinateToBackend(
          sessionId: sessionId,
          userName: userName,
          latitude: currentPos.latitude,
          longitude: currentPos.longitude,
          speed: currentPos.speed,
          heading: currentPos.heading,
          batteryLevel: batteryLvl,
          status: 'active',
        );
      }
    });
  }

  Future<void> _sendCoordinateToBackend({
    required String sessionId,
    required String userName,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    int? batteryLevel,
    String status = 'active',
  }) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/tracking/update';
      final payload = <String, dynamic>{
        'sessionId': sessionId,
        'userName': userName,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed ?? 0,
        'heading': heading ?? 0,
        'status': status,
      };
      if (batteryLevel != null) {
        payload['batteryLevel'] = batteryLevel;
      }

      await _dio.post(
        url,
        data: payload,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Gagal mengirim koordinat live ke backend: $e');
    }
  }

  /// Hentikan sesi live tracking
  Future<void> stopLiveTracking() async {
    final currentSession = state.sessionId;
    _positionSub?.cancel();
    _positionSub = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (currentSession != null) {
      try {
        final url = '${AppConstants.apiBaseUrl}/tracking/stop';
        await _dio.post(
          url,
          data: {'sessionId': currentSession},
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }

    state = const LiveTrackingState();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

final liveTrackingProvider =
    StateNotifierProvider<LiveTrackingNotifier, LiveTrackingState>((ref) {
  return LiveTrackingNotifier();
});

