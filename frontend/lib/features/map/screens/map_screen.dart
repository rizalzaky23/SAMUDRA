import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/safe_point_model.dart';
import '../providers/safe_points_provider.dart';

// ─── OSRM Routing Service ────────────────────────────────────────────────────

class OsrmRoute {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const OsrmRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get distanceText {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationText {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes menit';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}j ${mins}m';
  }
}

class OsrmService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    validateStatus: (status) => true,
  ));

  /// Fetch route from OSRM public server (completely free, no API key needed).
  /// Profile: 'foot' (walking), 'car' (driving), 'bike' (cycling)
  static Future<OsrmRoute?> getRoute({
    required LatLng origin,
    required LatLng destination,
    String profile = 'foot',
  }) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/$profile/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=false';

      debugPrint('OSRM request: $url');
      final response = await _dio.get(url);
      debugPrint('OSRM status: ${response.statusCode}');

      if ((response.statusCode ?? 0) != 200) {
        debugPrint('OSRM non-200: ${response.statusCode} - using fallback route');
        return _fallbackRoute(origin, destination, profile);
      }

      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data as Map<String, dynamic>;

      if (data['code'] != 'Ok') {
        debugPrint('OSRM code not Ok: ${data['code']} - using fallback route');
        return _fallbackRoute(origin, destination, profile);
      }

      final route = data['routes'][0] as Map<String, dynamic>;
      final distanceMeters = (route['distance'] as num).toDouble();
      final durationSeconds = (route['duration'] as num).toDouble();

      final coords = route['geometry']['coordinates'] as List<dynamic>;
      final points = coords
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      return OsrmRoute(
        points: points,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      debugPrint('OSRM error: $e - using fallback route');
      return _fallbackRoute(origin, destination, profile);
    }
  }

  /// Jalur cadangan berbasis interpolasi koordinat jika server OSRM gagal atau jarak rute ekstrem
  static OsrmRoute _fallbackRoute(
    LatLng origin,
    LatLng destination,
    String profile,
  ) {
    final distanceMeters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    double speedMps = 1.25; // ~4.5 km/jam jalan kaki
    if (profile == 'bike') speedMps = 3.9; // ~14 km/jam sepeda
    if (profile == 'car') speedMps = 9.7; // ~35 km/jam mobil
    final durationSeconds = (distanceMeters / speedMps).clamp(60.0, 86400.0);

    final points = <LatLng>[origin];
    for (int i = 1; i <= 3; i++) {
      final frac = i / 4.0;
      points.add(LatLng(
        origin.latitude + (destination.latitude - origin.latitude) * frac,
        origin.longitude + (destination.longitude - origin.longitude) * frac,
      ));
    }
    points.add(destination);

    return OsrmRoute(
      points: points,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final _userLocationProvider = StateProvider<LatLng?>((ref) => null);
final _routeProvider = StateProvider<OsrmRoute?>((ref) => null);
final _isLoadingRouteProvider = StateProvider<bool>((ref) => false);
final _selectedProfileProvider = StateProvider<String>((ref) => 'foot');

// ─── Evacuation Points ───────────────────────────────────────────────────────

class _EvacPoint {
  final String id;
  final String name;
  final String subtitle;
  final LatLng location;
  final String icon;
  final bool isCustom;

  const _EvacPoint({
    this.id = '',
    required this.name,
    required this.subtitle,
    required this.location,
    required this.icon,
    this.isCustom = false,
  });
}

const _jogjaEvacPoints = [
  _EvacPoint(
    name: 'Bukit Safe Point A',
    subtitle: 'Dataran tinggi aman (Yogyakarta)',
    location: LatLng(-7.780, 110.360),
    icon: '⛺',
  ),
  _EvacPoint(
    name: 'GOR Siaga Bencana',
    subtitle: 'Gedung pengungsian resmi (Yogyakarta)',
    location: LatLng(-7.800, 110.400),
    icon: '🏛️',
  ),
  _EvacPoint(
    name: 'Masjid Al-Aman',
    subtitle: 'Titik kumpul RT 05 (Yogyakarta)',
    location: LatLng(-7.760, 110.380),
    icon: '🕌',
  ),
];

List<_EvacPoint> _getEvacuationPoints(LatLng userPos,
    [List<SafePointModel> apiPoints = const []]) {
  final list = <_EvacPoint>[];
  final seenNames = <String>{};

  // 1. Masukkan titik aman dari database (yang ditambahkan oleh Admin / Super Admin)
  for (final p in apiPoints) {
    list.add(
      _EvacPoint(
        id: p.id,
        name: p.name,
        subtitle: p.subtitle,
        location: p.location,
        icon: p.icon,
        isCustom: true,
      ),
    );
    seenNames.add(p.name.trim().toLowerCase());
  }

  // 2. Tambahkan titik evakuasi resmi jika belum ada di database
  final distToJogja = Geolocator.distanceBetween(
    userPos.latitude,
    userPos.longitude,
    -7.7956,
    110.3695,
  );

  final defaultPoints = distToJogja < 60000
      ? _jogjaEvacPoints
      : [
          _EvacPoint(
            name: 'Shelter Evakuasi Dataran Tinggi',
            subtitle: 'Zona Ketinggian Aman Terdekat (~1.2 km)',
            location: LatLng(userPos.latitude + 0.009, userPos.longitude + 0.007),
            icon: '🏔️',
          ),
          _EvacPoint(
            name: 'Posko Siaga Bencana Terpadu',
            subtitle: 'Titik Kumpul Evakuasi Resmi (~1.8 km)',
            location: LatLng(userPos.latitude - 0.008, userPos.longitude + 0.011),
            icon: '⛺',
          ),
          _EvacPoint(
            name: 'Gedung Evakuasi Vertikal',
            subtitle: 'Struktur Beton Kuat >20m (~2.3 km)',
            location: LatLng(userPos.latitude + 0.014, userPos.longitude - 0.009),
            icon: '🏛️',
          ),
        ];

  for (final d in defaultPoints) {
    if (!seenNames.contains(d.name.trim().toLowerCase())) {
      list.add(d);
      seenNames.add(d.name.trim().toLowerCase());
    }
  }

  return list;
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Stream & Status Lokasi Realtime
  StreamSubscription<Position>? _positionStream;
  LocationPermission _locationPermission = LocationPermission.denied;
  bool _isLocationServiceActive = true;
  bool _useSimulationMode = false;

  int _selectedEvacIndex = 0;
  bool _isNavigating = false;
  double _remainingDistanceMeters = 0;
  double _remainingDurationSeconds = 0;

  static const _jogjaCenter = LatLng(-7.7956, 110.3695);

  @override
  void initState() {
    super.initState();
    // Pulse animation untuk user location marker
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Inisialisasi izin & lokasi realtime
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationAndPermissions(userInitiated: false);
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  List<_EvacPoint> _getCurrentEvacPoints(LatLng userPos) {
    final apiPoints = ref.read(safePointsProvider).points;
    return _getEvacuationPoints(userPos, apiPoints);
  }

  // ── Inisialisasi Izin & Layanan GPS ──

  Future<void> _initLocationAndPermissions({bool userInitiated = false}) async {
    // 1. Cek apakah layanan GPS hardware aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) {
      setState(() => _isLocationServiceActive = serviceEnabled);
    }

    if (!serviceEnabled) {
      if (userInitiated && mounted) {
        _showEnableGpsDialog();
      }
      _useFallbackLocation();
      return;
    }

    // 2. Cek izin lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (mounted) {
      setState(() => _locationPermission = permission);
    }

    if (permission == LocationPermission.deniedForever) {
      if (userInitiated && mounted) {
        _showPermissionSettingsDialog();
      }
      _useFallbackLocation();
      return;
    }

    if (permission == LocationPermission.denied) {
      if (userInitiated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Izin lokasi diperlukan untuk navigasi realtime.'),
            action: SnackBarAction(
              label: 'Izinkan',
              onPressed: () => _initLocationAndPermissions(userInitiated: true),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _useFallbackLocation();
      return;
    }

    // Izin diberikan -> Mulai Real-time Tracking
    await _startRealtimeTracking();
  }

  void _useFallbackLocation() {
    if (mounted) {
      ref.read(_userLocationProvider.notifier).state = _jogjaCenter;
      _fetchRoute(_jogjaCenter);
    }
  }

  // ── Real-time Position Tracking ──

  Future<void> _startRealtimeTracking() async {
    if (_useSimulationMode) return;

    // 1. Ambil lokasi awal secara cepat
    try {
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      if (mounted) {
        final initialLatLng = LatLng(pos.latitude, pos.longitude);
        ref.read(_userLocationProvider.notifier).state = initialLatLng;
        _mapController.move(initialLatLng, 15.0);
        await _fetchRoute(initialLatLng);
      }
    } catch (e) {
      debugPrint('Error getting initial position: $e');
    }

    // 2. Stream lokasi realtime
    await _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Update setiap perpindahan 3 meter
      ),
    ).listen((Position position) {
      if (!mounted || _useSimulationMode) return;

      final currentLatLng = LatLng(position.latitude, position.longitude);
      ref.read(_userLocationProvider.notifier).state = currentLatLng;

      final evacPoints = _getCurrentEvacPoints(currentLatLng);
      final dest = evacPoints[_selectedEvacIndex % evacPoints.length].location;
      final distanceToDest = Geolocator.distanceBetween(
        currentLatLng.latitude,
        currentLatLng.longitude,
        dest.latitude,
        dest.longitude,
      );

      setState(() {
        _remainingDistanceMeters = distanceToDest;
      });

      // Jika sedang navigasi aktif, gerakkan kamera mengikuti user
      if (_isNavigating) {
        _mapController.move(currentLatLng, _mapController.camera.zoom);

        // Jika sampai di titik evakuasi (< 25 meter)
        if (distanceToDest < 25) {
          setState(() => _isNavigating = false);
          _showArrivalDialog(evacPoints[_selectedEvacIndex % evacPoints.length]);
        }
      }
    }, onError: (e) {
      debugPrint('Position stream error: $e');
    });
  }

  // ── Dialog Pengaturan GPS & Izin ──

  void _showEnableGpsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 10),
            Text(
              'Layanan GPS Nonaktif',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Untuk melacak pergerakan evakuasi secara realtime, mohon aktifkan layanan GPS pada perangkat Anda.',
          style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Nanti', style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Buka Pengaturan GPS',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            Text(
              'Izin Lokasi Ditolak',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Izin lokasi diblokir permanen oleh sistem. Anda dapat membukanya melalui menu Pengaturan Aplikasi SAMUDRA agar rute evakuasi realtime dapat berfungsi.',
          style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup', style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Buka Pengaturan Izin',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showArrivalDialog(_EvacPoint point) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
            const SizedBox(width: 10),
            Text(
              'Tiba di Titik Aman!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda telah sampai di ${point.name}.',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Segera temui petugas BPBD/SAR terdekat di posko pengungsian untuk registrasi keselamatan dan bantuan logistik.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Baik, Mengerti',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fetch Route dari OSRM ──

  Future<void> _fetchRoute(LatLng from) async {
    ref.read(_isLoadingRouteProvider.notifier).state = true;
    ref.read(_routeProvider.notifier).state = null;

    final profile = ref.read(_selectedProfileProvider);
    final evacPoints = _getCurrentEvacPoints(from);
    final destination = evacPoints[_selectedEvacIndex % evacPoints.length].location;

    final route = await OsrmService.getRoute(
      origin: from,
      destination: destination,
      profile: profile,
    );

    if (mounted) {
      ref.read(_routeProvider.notifier).state = route;
      ref.read(_isLoadingRouteProvider.notifier).state = false;
      if (route != null) {
        setState(() {
          _remainingDistanceMeters = route.distanceMeters;
          _remainingDurationSeconds = route.durationSeconds;
        });

        // Fit map ke seluruh rute jika tidak sedang navigasi aktif
        if (!_isNavigating && route.points.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(route.points);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.fromLTRB(40, 120, 40, 280),
            ),
          );
        }
      }
    }
  }

  void _selectEvacPoint(int index) async {
    setState(() => _selectedEvacIndex = index);
    final userLoc = ref.read(_userLocationProvider) ?? _jogjaCenter;
    await _fetchRoute(userLoc);
  }

  void _changeProfile(String profile) async {
    ref.read(_selectedProfileProvider.notifier).state = profile;
    final userLoc = ref.read(_userLocationProvider) ?? _jogjaCenter;
    await _fetchRoute(userLoc);
  }

  void _startNavigation() {
    final userLoc = ref.read(_userLocationProvider) ?? _jogjaCenter;
    final route = ref.read(_routeProvider);
    final evacPoints = _getCurrentEvacPoints(userLoc);
    final selected = evacPoints[_selectedEvacIndex % evacPoints.length];

    if (_isNavigating) {
      setState(() => _isNavigating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigasi dihentikan', style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Pastikan izin lokasi aktif untuk navigasi realtime jika bukan simulasi
    if (_locationPermission != LocationPermission.always &&
        _locationPermission != LocationPermission.whileInUse &&
        !_useSimulationMode) {
      _initLocationAndPermissions(userInitiated: true);
      return;
    }

    setState(() {
      _isNavigating = true;
      if (route != null) {
        _remainingDistanceMeters = route.distanceMeters;
        _remainingDurationSeconds = route.durationSeconds;
      }
    });

    _mapController.move(userLoc, 17.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Navigasi aktif ke ${selected.name} · ${route?.distanceText ?? ''}',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = ref.watch(_userLocationProvider) ?? _jogjaCenter;
    final route = ref.watch(_routeProvider);
    final isLoading = ref.watch(_isLoadingRouteProvider);
    final profile = ref.watch(_selectedProfileProvider);
    final user = ref.watch(authStateProvider).user;
    final isAdmin = user?.isAdmin == true;
    final safePoints = ref.watch(safePointsProvider).points;
    final evacPoints = _getEvacuationPoints(userLocation, safePoints);
    final selectedPoint = evacPoints.isNotEmpty
        ? evacPoints[_selectedEvacIndex % evacPoints.length]
        : _jogjaEvacPoints[0];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Full Screen Map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 14,
              onLongPress: (tapPosition, point) {
                if (isAdmin) {
                  _showAddSafePointDialog(context, point);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.samudra.app',
              ),
              // Danger zone circle
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: userLocation,
                    radius: 500,
                    useRadiusInMeter: true,
                    color: AppColors.danger.withValues(alpha: 0.10),
                    borderColor: AppColors.danger.withValues(alpha: 0.25),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              // Route polyline dari OSRM
              if (route != null)
                PolylineLayer(
                  polylines: [
                    // Glow/shadow effect
                    Polyline(
                      points: route.points,
                      color: AppColors.primary.withValues(alpha: 0.25),
                      strokeWidth: 8,
                    ),
                    // Main route line
                    Polyline(
                      points: route.points,
                      color: AppColors.primary,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              // Markers
              MarkerLayer(
                markers: [
                  // User location marker with pulse
                  Marker(
                    point: userLocation,
                    width: 48,
                    height: 48,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, __) => Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(
                                  alpha: _pulseAnimation.value * 0.3),
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Titik evakuasi markers
                  ...evacPoints.asMap().entries.map((e) {
                    final isSelected = e.key == (_selectedEvacIndex % evacPoints.length);
                    return Marker(
                      point: e.value.location,
                      width: isSelected ? 56 : 44,
                      height: isSelected ? 56 : 44,
                      child: GestureDetector(
                        onTap: () => _selectEvacPoint(e.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isSelected ? Colors.white : Colors.white70,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              e.value.icon,
                              style:
                                  TextStyle(fontSize: isSelected ? 26 : 20),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ── Top Bar: Back + Title + My Location Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _mapButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Peta Evakuasi',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isNavigating
                                    ? const Color(0xFF16A34A)
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isNavigating ? 'Live' : 'Siaga',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isNavigating
                                    ? const Color(0xFF16A34A)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _mapButton(
                      icon: Icons.my_location_rounded,
                      onTap: () {
                        if (_locationPermission != LocationPermission.always &&
                            _locationPermission != LocationPermission.whileInUse) {
                          _initLocationAndPermissions(userInitiated: true);
                        } else {
                          final loc = ref.read(_userLocationProvider);
                          if (loc != null) {
                            _mapController.move(loc, 16.0);
                          } else {
                            _initLocationAndPermissions(userInitiated: true);
                          }
                        }
                      },
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      _mapButton(
                        icon: Icons.add_location_alt_rounded,
                        backgroundColor: const Color(0xFF059669),
                        iconColor: Colors.white,
                        onTap: () {
                          _showAddSafePointDialog(
                              context, _mapController.camera.center);
                        },
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // ── Navigation HUD atau GPS Status Banner ──
                if (_isNavigating)
                  _buildNavigationHUD(userLocation, evacPoints)
                else
                  _buildGpsStatusBanner(userLocation),
              ],
            ),
          ),

          // ── Mode Transportasi Toggle ──
          Positioned(
            top: MediaQuery.of(context).padding.top + (_isNavigating ? 140 : 120),
            right: 16,
            child: Column(
              children: [
                _transportButton(
                  icon: Icons.directions_walk_rounded,
                  isSelected: profile == 'foot',
                  onTap: () => _changeProfile('foot'),
                ),
                const SizedBox(height: 8),
                _transportButton(
                  icon: Icons.directions_car_rounded,
                  isSelected: profile == 'car',
                  onTap: () => _changeProfile('car'),
                ),
                const SizedBox(height: 8),
                _transportButton(
                  icon: Icons.pedal_bike_rounded,
                  isSelected: profile == 'bike',
                  onTap: () => _changeProfile('bike'),
                ),
              ],
            ),
          ),

          // ── Loading indicator ──
          if (isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + (_isNavigating ? 140 : 120),
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Menghitung rute...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom Sheet ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Pilih titik evakuasi (horizontal scroll)
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      scrollDirection: Axis.horizontal,
                      itemCount: evacPoints.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final point = evacPoints[index];
                        final isSelected = index == (_selectedEvacIndex % evacPoints.length);
                        return GestureDetector(
                          onTap: () => _selectEvacPoint(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(point.icon,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      point.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      point.subtitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Route info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedPoint.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isAdmin &&
                                      selectedPoint.isCustom &&
                                      selectedPoint.id.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.danger,
                                        size: 20,
                                      ),
                                      tooltip: 'Hapus titik aman',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _confirmDeleteSafePoint(
                                          selectedPoint),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              if (route != null)
                                Row(
                                  children: [
                                    const Icon(Icons.route_rounded,
                                        size: 14,
                                        color: Color(0xFF3B6FE8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${route.distanceText}  ·  ${route.durationText}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              else if (isLoading)
                                Text(
                                  'Menghitung rute...',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              else
                                Text(
                                  'Ketuk titik di peta untuk pilih',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            profile == 'car'
                                ? Icons.directions_car_rounded
                                : profile == 'bike'
                                    ? Icons.pedal_bike_rounded
                                    : Icons.directions_walk_rounded,
                            color: const Color(0xFF16A34A),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Start Navigation Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _startNavigation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isNavigating ? const Color(0xFFDC2626) : AppColors.primary,
                          disabledBackgroundColor: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isNavigating
                                  ? Icons.stop_circle_rounded
                                  : Icons.navigation_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isNavigating
                                  ? 'Hentikan navigasi'
                                  : 'Mulai navigasi realtime',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HUD Navigasi Realtime ──

  Widget _buildNavigationHUD(LatLng userLocation, List<_EvacPoint> evacPoints) {
    final selectedPoint = evacPoints[_selectedEvacIndex % evacPoints.length];
    final distText = _remainingDistanceMeters < 1000
        ? '${_remainingDistanceMeters.toStringAsFixed(0)} m'
        : '${(_remainingDistanceMeters / 1000).toStringAsFixed(1)} km';
    final estMins = _remainingDurationSeconds > 0
        ? (_remainingDurationSeconds / 60).ceil()
        : (_remainingDistanceMeters / 1.25 / 60).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF16A34A), width: 0.8),
                      ),
                      child: Text(
                        'PANDUAN LIVE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Est. $estMins menit',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  selectedPoint.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Sisa jarak: $distText',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF60A5FA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isNavigating = false),
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Hentikan',
          ),
        ],
      ),
    );
  }

  // ── GPS Status / Simulation Pill Banner ──

  Widget _buildGpsStatusBanner(LatLng userLocation) {
    if (!_isLocationServiceActive) {
      return GestureDetector(
        onTap: () => _initLocationAndPermissions(userInitiated: true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_off_rounded, size: 16, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS nonaktif. Ketuk untuk mengaktifkan',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF991B1B),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFDC2626)),
            ],
          ),
        ),
      );
    }

    if (_locationPermission == LocationPermission.deniedForever) {
      return GestureDetector(
        onTap: () => _initLocationAndPermissions(userInitiated: true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Izin lokasi diblokir. Ketuk untuk buka pengaturan',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFD97706)),
            ],
          ),
        ),
      );
    }

    final isOutsideJogja = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          _jogjaCenter.latitude,
          _jogjaCenter.longitude,
        ) >
        60000;

    if (!isOutsideJogja && !_useSimulationMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _useSimulationMode ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _useSimulationMode ? const Color(0xFFBFDBFE) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _useSimulationMode ? Icons.place_rounded : Icons.my_location_rounded,
            size: 15,
            color: _useSimulationMode ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _useSimulationMode
                  ? 'Simulasi DIY Yogyakarta aktif'
                  : 'GPS Aktif (Titik aman disesuaikan)',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _useSimulationMode ? const Color(0xFF1E40AF) : const Color(0xFF166534),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _useSimulationMode = !_useSimulationMode;
              });
              if (_useSimulationMode) {
                _useFallbackLocation();
              } else {
                _initLocationAndPermissions(userInitiated: true);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                _useSimulationMode ? 'Pakai GPS' : 'Simulasi DIY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 22),
      ),
    );
  }

  // ── Modal Tambah Titik Aman (Admin & Super Admin) ──

  void _showAddSafePointDialog(BuildContext rootContext, LatLng initialCoords) {
    final nameCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final latCtrl = TextEditingController(
        text: initialCoords.latitude.toStringAsFixed(6));
    final lngCtrl = TextEditingController(
        text: initialCoords.longitude.toStringAsFixed(6));
    final capCtrl = TextEditingController();
    String selectedIcon = '⛺';
    bool isSubmitting = false;

    final icons = ['⛺', '🏔️', '🏛️', '🕌', '🏟️', '🏥', '🏢'];

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (innerCtx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(innerCtx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ADMIN PANEL',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tambah Titik Aman',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Titik aman baru akan langsung muncul di peta evakuasi semua pengguna.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nama Titik
                  Text('Nama Titik Aman *',
                      style: GoogleFonts.inter(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Posko Lapangan Merdeka / Bukit Aman',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Keterangan / Subtitle
                  Text('Keterangan Fasilitas / Ketinggian',
                      style: GoogleFonts.inter(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subtitleCtrl,
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Dataran tinggi >30m, posko medis & logistik',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ikon Lokasi
                  Text('Pilih Ikon Lokasi',
                      style: GoogleFonts.inter(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: icons.map((ic) {
                        final isSel = selectedIcon == ic;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedIcon = ic),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF059669)
                                      .withValues(alpha: 0.15)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF059669)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child:
                                Text(ic, style: const TextStyle(fontSize: 22)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Koordinat
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Latitude',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: latCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Longitude',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: lngCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Kapasitas
                  Text('Kapasitas Jiwa (Opsional)',
                      style: GoogleFonts.inter(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: capCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 500',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(innerCtx).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Nama titik aman wajib diisi')),
                                );
                                return;
                              }

                              final lat =
                                  double.tryParse(latCtrl.text.trim());
                              final lng =
                                  double.tryParse(lngCtrl.text.trim());
                              if (lat == null || lng == null) {
                                ScaffoldMessenger.of(innerCtx).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Koordinat lokasi tidak valid')),
                                );
                                return;
                              }

                              setSheetState(() => isSubmitting = true);

                              final messenger =
                                  ScaffoldMessenger.of(rootContext);
                              final navigator = Navigator.of(modalCtx);
                              final success = await ref
                                  .read(safePointsProvider.notifier)
                                  .createSafePoint(
                                    name: name,
                                    subtitle: subtitleCtrl.text.trim(),
                                    latitude: lat,
                                    longitude: lng,
                                    icon: selectedIcon,
                                    capacity:
                                        int.tryParse(capCtrl.text.trim()),
                                  );

                              navigator.pop();
                              if (success) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Titik aman "$name" berhasil ditambahkan!'),
                                    backgroundColor:
                                        const Color(0xFF059669),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                if (mounted) {
                                  _mapController.move(LatLng(lat, lng), 15);
                                  final userLoc = ref.read(
                                          _userLocationProvider) ??
                                      _jogjaCenter;
                                  _fetchRoute(userLoc);
                                }
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Gagal menyimpan titik aman. Periksa koneksi backend.'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              'Simpan Titik Aman',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteSafePoint(_EvacPoint point) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Titik Aman?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Titik aman "${point.name}" akan dihapus dari peta semua pengguna.',
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(safePointsProvider.notifier)
                  .deleteSafePoint(point.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Titik aman "${point.name}" berhasil dihapus'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  setState(() => _selectedEvacIndex = 0);
                  final userLoc =
                      ref.read(_userLocationProvider) ?? _jogjaCenter;
                  _fetchRoute(userLoc);
                }
              }
            },
            child: Text('Hapus',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _transportButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: isSelected ? 0.15 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
