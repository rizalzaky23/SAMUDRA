import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:samudra/features/map/screens/map_screen.dart';

void main() {
  const origin = LatLng(-7.7956, 110.3695);
  const destination = LatLng(-7.7800, 110.3600);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('offline mode returns direct fallback route when no cache exists', () async {
    final route = await OsrmService.getRoute(
      origin: origin,
      destination: destination,
      profile: 'foot',
      forceOffline: true,
    );

    expect(route.isOffline, isTrue);
    expect(route.isDirectLine, isTrue);
    expect(route.points.length, greaterThanOrEqualTo(2));
    expect(route.distanceMeters, greaterThan(1000));
    expect(route.durationSeconds, greaterThan(60));
  });

  test('offline mode reuses cached road route across profiles and within 5km', () async {
    const cachedRoute = OsrmRoute(
      points: [
        origin,
        LatLng(-7.7880, 110.3650),
        destination,
      ],
      distanceMeters: 2150,
      durationSeconds: 1620,
    );

    await OsrmService.saveCachedRoute(
      origin: origin,
      destination: destination,
      profile: 'foot',
      route: cachedRoute,
    );

    // Pindah ~100m dan ganti ke profil car — tetap pakai rute jalan tersimpan
    const nearbyOrigin = LatLng(-7.7948, 110.3695);
    final loaded = await OsrmService.getRoute(
      origin: nearbyOrigin,
      destination: destination,
      profile: 'car',
      forceOffline: true,
    );

    expect(loaded.isOffline, isTrue);
    expect(loaded.isDirectLine, isFalse);
    expect(loaded.points.first, nearbyOrigin);
    expect(loaded.points.last, destination);
  });

  test('offline mode falls back to direct line when origin is > 5km from cache', () async {
    const cachedRoute = OsrmRoute(
      points: [origin, destination],
      distanceMeters: 2000,
      durationSeconds: 1500,
    );
    await OsrmService.saveCachedRoute(
      origin: origin,
      destination: destination,
      profile: 'foot',
      route: cachedRoute,
    );

    const farOrigin = LatLng(-7.8600, 110.4500); // > 10km dari cache
    final route = await OsrmService.getRoute(
      origin: farOrigin,
      destination: destination,
      profile: 'foot',
      forceOffline: true,
    );

    expect(route.isOffline, isTrue);
    expect(route.isDirectLine, isTrue);
  });

  test('bearingLabel returns accurate Indonesian compass direction', () {
    expect(OsrmService.bearingLabel(origin, const LatLng(-7.78, 110.3695)), 'Utara');
    expect(OsrmService.bearingLabel(origin, const LatLng(-7.7956, 110.39)), 'Timur');
    expect(OsrmService.bearingLabel(origin, const LatLng(-7.81, 110.3695)), 'Selatan');
    expect(OsrmService.bearingLabel(origin, const LatLng(-7.7956, 110.35)), 'Barat');
  });

  test('latLngToTile computes valid OSM tile indices for Yogyakarta', () {
    final z14 = OsrmService.latLngToTile(origin, 14);
    final z15 = OsrmService.latLngToTile(origin, 15);
    expect(z14.x, 13215);
    expect(z14.y, 8547);
    expect(z15.x, inInclusiveRange(z14.x * 2, z14.x * 2 + 1));
    expect(z15.y, inInclusiveRange(z14.y * 2, z14.y * 2 + 1));
  });
}
