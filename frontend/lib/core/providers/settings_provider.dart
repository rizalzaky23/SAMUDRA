import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys
const _kLocationRealtime = 'setting_location_realtime';
const _kSirenNotif = 'setting_siren_notif';
const _kOfflineMode = 'setting_offline_mode';
const _kLanguage = 'setting_language';

class AppSettings {
  final bool locationRealtime;
  final bool sirenNotif;
  final bool offlineMode;
  final String language;

  const AppSettings({
    this.locationRealtime = true,
    this.sirenNotif = true,
    this.offlineMode = false,
    this.language = 'Indonesia',
  });

  AppSettings copyWith({
    bool? locationRealtime,
    bool? sirenNotif,
    bool? offlineMode,
    String? language,
  }) {
    return AppSettings(
      locationRealtime: locationRealtime ?? this.locationRealtime,
      sirenNotif: sirenNotif ?? this.sirenNotif,
      offlineMode: offlineMode ?? this.offlineMode,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SharedPreferences? _prefs;

  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      locationRealtime: _prefs?.getBool(_kLocationRealtime) ?? true,
      sirenNotif: _prefs?.getBool(_kSirenNotif) ?? true,
      offlineMode: _prefs?.getBool(_kOfflineMode) ?? false,
      language: _prefs?.getString(_kLanguage) ?? 'Indonesia',
    );
  }

  Future<void> setLocationRealtime(bool value) async {
    state = state.copyWith(locationRealtime: value);
    await _prefs?.setBool(_kLocationRealtime, value);
  }

  Future<void> setSirenNotif(bool value) async {
    state = state.copyWith(sirenNotif: value);
    await _prefs?.setBool(_kSirenNotif, value);
  }

  Future<void> setOfflineMode(bool value) async {
    state = state.copyWith(offlineMode: value);
    await _prefs?.setBool(_kOfflineMode, value);
  }

  Future<void> setLanguage(String value) async {
    state = state.copyWith(language: value);
    await _prefs?.setString(_kLanguage, value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
