import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/family_contact_model.dart';

const _kFamilyContactsPrefix = 'samudra_family_contacts_v1';

class FamilyContactsState {
  final List<FamilyContact> contacts;
  final bool isLoading;
  final bool isSharingLocation;

  const FamilyContactsState({
    this.contacts = const [],
    this.isLoading = false,
    this.isSharingLocation = false,
  });

  FamilyContactsState copyWith({
    List<FamilyContact>? contacts,
    bool? isLoading,
    bool? isSharingLocation,
  }) {
    return FamilyContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      isSharingLocation: isSharingLocation ?? this.isSharingLocation,
    );
  }
}

class FamilyContactsNotifier extends StateNotifier<FamilyContactsState> {
  final String? _userId;
  final bool _isAuthenticated;
  SharedPreferences? _prefs;

  FamilyContactsNotifier({
    required String? userId,
    required bool isAuthenticated,
  })  : _userId = userId,
        _isAuthenticated = isAuthenticated,
        super(const FamilyContactsState(isLoading: true)) {
    _load();
  }

  String get _storageKey {
    final uid = _userId;
    return uid != null && uid.isNotEmpty
        ? '${_kFamilyContactsPrefix}_$uid'
        : '${_kFamilyContactsPrefix}_guest';
  }

  Future<void> _load() async {
    // 1. Muat cache lokal akun terlebih dulu agar cepat & tetap ada saat offline
    List<FamilyContact> localContacts = [];
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        localContacts = decoded
            .map((e) => FamilyContact.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(contacts: localContacts);
      }
    } catch (e) {
      debugPrint('Error loading local family contacts: $e');
    }

    // 2. Jika akun login, sinkronkan dengan backend per-akun
    if (_isAuthenticated) {
      try {
        final client = ApiClient();
        client.init();
        final res = await client.dio
            .get('/family-contacts')
            .timeout(const Duration(seconds: 6));

        if (res.statusCode == 200 && res.data is List) {
          final remoteList = (res.data as List)
              .map((e) => FamilyContact.fromJson(e as Map<String, dynamic>))
              .toList();
          await _save(remoteList);
          state = state.copyWith(contacts: remoteList, isLoading: false);
          return;
        }
      } catch (e) {
        debugPrint('Error syncing family contacts from API: $e');
      }
      state = state.copyWith(isLoading: false);
      return;
    }

    // 3. Mode tamu: tampilkan contoh default jika belum ada data lokal
    if (localContacts.isEmpty) {
      final defaultContacts = [
        const FamilyContact(
          id: '1',
          name: 'Rina Susanti',
          relationship: 'Ibu',
          phone: '081234567890',
        ),
      ];
      await _save(defaultContacts);
      state = state.copyWith(contacts: defaultContacts, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _save(List<FamilyContact> list) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(list.map((c) => c.toJson()).toList());
      await _prefs?.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving family contacts: $e');
    }
  }

  Future<void> addContact({
    required String name,
    required String relationship,
    required String phone,
  }) async {
    final trimmedName = name.trim();
    final trimmedRel = relationship.trim();
    final trimmedPhone = phone.trim();

    FamilyContact? created;
    if (_isAuthenticated) {
      try {
        final client = ApiClient();
        client.init();
        final res = await client.dio.post('/family-contacts', data: {
          'name': trimmedName,
          'relationship': trimmedRel,
          'phone': trimmedPhone,
        }).timeout(const Duration(seconds: 6));
        if ((res.statusCode == 200 || res.statusCode == 201) &&
            res.data is Map<String, dynamic>) {
          created = FamilyContact.fromJson(res.data as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('Error saving family contact to API: $e');
      }
    }

    final newContact = created ??
        FamilyContact(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: trimmedName,
          relationship: trimmedRel,
          phone: trimmedPhone,
        );
    final updated = [...state.contacts, newContact];
    state = state.copyWith(contacts: updated);
    await _save(updated);
  }

  Future<void> updateContact({
    required String id,
    required String name,
    required String relationship,
    required String phone,
  }) async {
    final trimmedName = name.trim();
    final trimmedRel = relationship.trim();
    final trimmedPhone = phone.trim();

    final updated = state.contacts.map((c) {
      if (c.id == id) {
        return c.copyWith(
          name: trimmedName,
          relationship: trimmedRel,
          phone: trimmedPhone,
        );
      }
      return c;
    }).toList();
    state = state.copyWith(contacts: updated);
    await _save(updated);

    if (_isAuthenticated) {
      try {
        final client = ApiClient();
        client.init();
        await client.dio.patch('/family-contacts/$id', data: {
          'name': trimmedName,
          'relationship': trimmedRel,
          'phone': trimmedPhone,
        }).timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint('Error updating family contact in API: $e');
      }
    }
  }

  Future<void> deleteContact(String id) async {
    final updated = state.contacts.where((c) => c.id != id).toList();
    state = state.copyWith(contacts: updated);
    await _save(updated);

    if (_isAuthenticated) {
      try {
        final client = ApiClient();
        client.init();
        await client.dio
            .delete('/family-contacts/$id')
            .timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint('Error deleting family contact in API: $e');
      }
    }
  }

  /// Format nomor telepon lokal (08...) ke format internasional WhatsApp (628...)
  static String formatPhoneForWhatsApp(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('62')) {
      cleaned = '62$cleaned';
    }
    return cleaned;
  }

  /// Ambil titik koordinat GPS real-time saat ini
  Future<Position?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      // Ambil posisi dengan akurasi tinggi
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Bagikan lokasi ke WhatsApp kontak keluarga
  Future<bool> shareLocationToContact(
    FamilyContact contact, {
    Position? position,
  }) async {
    state = state.copyWith(isSharingLocation: true);

    try {
      final pos = position ?? await getCurrentLocation();
      final lat = pos?.latitude ?? -7.7956;
      final lng = pos?.longitude ?? 110.3695;

      // Cari alamat perkiraan jika tersedia
      String? addressText;
      try {
        final placemarks = await Geocoding()
            .placemarkFromCoordinates(lat, lng)
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

      final cleanPhone = formatPhoneForWhatsApp(contact.phone);
      final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';

      final msg = StringBuffer();
      msg.writeln('🚨 *DARURAT SAMUDRA — PEMANTAUAN LIVE LOCATION* 🚨');
      msg.writeln('Halo *${contact.name}*, saya membutuhkan pertolongan darurat!');
      msg.writeln();
      msg.writeln('📍 *Peta & Titik Koordinat Real-Time Saya:*');
      msg.writeln(mapsUrl);
      msg.writeln('Koordinat: $lat, $lng');
      if (addressText != null) {
        msg.writeln('Area Sekitar: $addressText');
      }
      msg.writeln();
      msg.writeln('🔴 *PEMANTAUAN LANGSUNG (LIVE LOCATION WHATSAPP):*');
      msg.writeln('Mohon pantau pergerakan saya secara langsung di ruang obrolan ini.');
      msg.writeln();
      msg.writeln('_(Pesan otomatis dikirim melalui Fitur Darurat Aplikasi SAMUDRA)_');

      final encoded = Uri.encodeComponent(msg.toString());

      // Coba scheme langsung ke WhatsApp app
      final waDirectUri =
          Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded');
      final waWebUri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');

      bool launched = false;
      if (await canLaunchUrl(waDirectUri)) {
        launched = await launchUrl(waDirectUri,
            mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(waWebUri)) {
        launched =
            await launchUrl(waWebUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback ke SMS jika WhatsApp tidak terpasang
        final smsUri = Uri.parse('sms:$cleanPhone?body=$encoded');
        if (await canLaunchUrl(smsUri)) {
          launched = await launchUrl(smsUri);
        }
      }

      state = state.copyWith(isSharingLocation: false);
      return launched;
    } catch (e) {
      debugPrint('Error sharing location to WhatsApp: $e');
      state = state.copyWith(isSharingLocation: false);
      return false;
    }
  }

  /// Melakukan panggilan telepon langsung
  static Future<void> callPhone(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

final familyContactsProvider =
    StateNotifierProvider<FamilyContactsNotifier, FamilyContactsState>((ref) {
  final auth = ref.watch(authStateProvider);
  return FamilyContactsNotifier(
    userId: auth.user?.id,
    isAuthenticated: auth.isAuthenticated,
  );
});
