import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/earthquake_model.dart';

class BmkgRealtimeService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    ),
  );

  /// Fetch all 200 real-time earthquakes directly from BMKG official website
  /// URL: https://www.bmkg.go.id/gempabumi/gempabumi-realtime
  static Future<List<EarthquakeModel>> fetch200RealtimeEarthquakes() async {
    try {
      final response = await _dio.get(
        'https://www.bmkg.go.id/gempabumi/gempabumi-realtime',
        options: Options(responseType: ResponseType.plain),
      );

      final html = response.data.toString();
      final scriptRegex = RegExp(r'<script[^>]*>(.*?)</script>', dotAll: true);
      final matches = scriptRegex.allMatches(html);

      for (final match in matches) {
        final scriptContent = match.group(1)?.trim() ?? '';
        if (scriptContent.startsWith('[') &&
            scriptContent.contains('"eventid"') &&
            scriptContent.contains('"waktu"')) {
          final decoded = jsonDecode(scriptContent);
          if (decoded is List) {
            dynamic resolve(dynamic val) {
              if (val is int && val >= 0 && val < decoded.length) {
                return decoded[val];
              }
              return val;
            }

            final List<EarthquakeModel> list = [];
            for (final item in decoded) {
              if (item is Map &&
                  item.containsKey('eventid') &&
                  item.containsKey('waktu')) {
                final eventId = resolve(item['eventid'])?.toString() ?? '';
                final waktuStr = resolve(item['waktu'])?.toString() ?? '';
                final latStr = resolve(item['lintang'])?.toString() ?? '0';
                final lngStr = resolve(item['bujur'])?.toString() ?? '0';
                final depthStr = resolve(item['dalam'])?.toString() ?? '10';
                final magStr = resolve(item['mag'])?.toString() ?? '0';
                final areaStr = resolve(item['area'])?.toString() ?? '';

                final formattedTime = _formatUtcToWib(waktuStr);
                final mag = double.tryParse(magStr) ?? 0.0;
                final isPotentialTsunami = mag >= 7.0;

                list.add(
                  EarthquakeModel(
                    id: eventId,
                    bmkgRefId: eventId,
                    magnitude: magStr,
                    depthKm: depthStr,
                    occurredAt: formattedTime,
                    region: areaStr,
                    latitude: latStr,
                    longitude: lngStr,
                    potentialTsunami: isPotentialTsunami,
                  ),
                );
              }
            }

            if (list.isNotEmpty) {
              return list;
            }
          }
        }
      }
    } catch (e) {
      // Error logging can be handled if needed
    }
    return [];
  }

  /// Converts BMKG UTC string "2026/09/24  08:18:42.014" to "24 Sep 2026, 15:18 WIB"
  static String _formatUtcToWib(String raw) {
    try {
      final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      final parts = cleaned.split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('/');
        final timeParts = parts[1].split(':');
        if (dateParts.length == 3 && timeParts.length >= 2) {
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);

          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final secParts = timeParts.length > 2 ? timeParts[2].split('.') : ['0'];
          final sec = int.parse(secParts[0]);

          final utc = DateTime.utc(year, month, day, hour, minute, sec);
          final wib = utc.add(const Duration(hours: 7));

          const monthNames = [
            '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
          ];
          final mName = month >= 1 && month <= 12 ? monthNames[month] : month.toString();
          final padMin = wib.minute.toString().padLeft(2, '0');
          final padHour = wib.hour.toString().padLeft(2, '0');

          return '$day $mName $year, $padHour:$padMin WIB';
        }
      }
    } catch (_) {}
    return raw;
  }
}
