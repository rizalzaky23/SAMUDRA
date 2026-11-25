import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/safe_point_model.dart';

const _kCachedSafePoints = 'cached_safe_points';

class SafePointsState {
  final List<SafePointModel> points;
  final bool isLoading;
  final String? error;

  const SafePointsState({
    this.points = const [],
    this.isLoading = false,
    this.error,
  });

  SafePointsState copyWith({
    List<SafePointModel>? points,
    bool? isLoading,
    String? error,
  }) {
    return SafePointsState(
      points: points ?? this.points,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SafePointsNotifier extends StateNotifier<SafePointsState> {
  SafePointsNotifier() : super(const SafePointsState()) {
    loadSafePoints();
  }

  Future<void> _saveCache(List<SafePointModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'subtitle': p.subtitle,
                'latitude': p.latitude,
                'longitude': p.longitude,
                'icon': p.icon,
                if (p.capacity != null) 'capacity': p.capacity,
                if (p.authorId != null) 'authorId': p.authorId,
                if (p.createdAt != null) 'createdAt': p.createdAt!.toIso8601String(),
              })
          .toList());
      await prefs.setString(_kCachedSafePoints, encoded);
    } catch (e) {
      debugPrint('Failed to cache safe points: $e');
    }
  }

  Future<void> loadSafePoints() async {
    state = state.copyWith(isLoading: true, error: null);

    // Tampilkan cache lokal lebih dulu agar tetap tersedia saat offline
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kCachedSafePoints);
      if (cached != null && cached.isNotEmpty) {
        final List raw = jsonDecode(cached) as List;
        final list = raw
            .map((item) => SafePointModel.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          state = state.copyWith(points: list);
        }
      }
    } catch (e) {
      debugPrint('Failed to load cached safe points: $e');
    }

    try {
      final client = ApiClient();
      client.init();

      final response = await client.dio.get('/safe-points').timeout(
            const Duration(seconds: 6),
          );

      if (response.statusCode == 200 && response.data is List) {
        final List raw = response.data;
        final list = raw
            .map((item) => SafePointModel.fromJson(item as Map<String, dynamic>))
            .toList();

        state = state.copyWith(points: list, isLoading: false);
        await _saveCache(list);
        return;
      }
    } catch (e) {
      debugPrint('Failed to load safe points from API: $e');
    }
    state = state.copyWith(isLoading: false);
  }

  Future<bool> createSafePoint({
    required String name,
    required String subtitle,
    required double latitude,
    required double longitude,
    String icon = '⛺',
    int? capacity,
  }) async {
    try {
      final client = ApiClient();
      client.init();

      final body = {
        'name': name.trim(),
        'subtitle': subtitle.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'icon': icon,
        if (capacity != null) 'capacity': capacity,
      };

      final response = await client.dio.post('/safe-points', data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final created = SafePointModel.fromJson(response.data as Map<String, dynamic>);
        final updated = [...state.points, created];
        state = state.copyWith(points: updated);
        await _saveCache(updated);
        return true;
      }
    } catch (e) {
      debugPrint('Error creating safe point: $e');
    }
    return false;
  }

  Future<bool> deleteSafePoint(String id) async {
    try {
      final client = ApiClient();
      client.init();

      final response = await client.dio.delete('/safe-points/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        final updated = state.points.where((p) => p.id != id).toList();
        state = state.copyWith(points: updated);
        await _saveCache(updated);
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting safe point: $e');
    }
    return false;
  }
}

final safePointsProvider =
    StateNotifierProvider<SafePointsNotifier, SafePointsState>((ref) {
  return SafePointsNotifier();
});

