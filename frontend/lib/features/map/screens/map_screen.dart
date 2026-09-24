import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  final bool _showBottomSheet = true;

  // Safe point location (Bukit Safe Point A - example coords)
  static const _safePoint = LatLng(-7.80, 110.36);
  static const _userLocation = LatLng(-7.77, 110.41);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Full Screen Map ──
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-7.785, 110.385),
              initialZoom: 14,
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
                    point: _userLocation,
                    radius: 800,
                    useRadiusInMeter: true,
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderColor: AppColors.danger.withValues(alpha: 0.3),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              // Polyline (dashed route)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_userLocation, _safePoint],
                    color: AppColors.primary,
                    strokeWidth: 3,
                    pattern: StrokePattern.dashed(segments: const [8.0, 4.0]),
                  ),
                ],
              ),
              // Markers
              MarkerLayer(
                markers: [
                  // User location marker
                  Marker(
                    point: _userLocation,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Safe point tent marker
                  Marker(
                    point: _safePoint,
                    width: 48,
                    height: 48,
                    child: const Text(
                      '⛺',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Top: Safe area padding ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Column(
              children: [
                _mapButton(
                  icon: Icons.my_location_rounded,
                  onTap: () => _mapController.move(_userLocation, 14),
                ),
                const SizedBox(height: 10),
                _mapButton(
                  icon: Icons.gps_fixed_rounded,
                  onTap: () => _mapController.move(_safePoint, 14),
                ),
              ],
            ),
          ),

          // ── Bottom Sheet ──
          if (_showBottomSheet)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bukit Safe Point A',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '1.2 km · jalan kaki 15 menit',
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
                            child: const Icon(
                              Icons.directions_walk_rounded,
                              color: Color(0xFF16A34A),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _startNavigation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                          ),
                          child: Text(
                            'Mulai navigasi',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Bottom nav safe area
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mapButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }

  void _startNavigation() {
    // TODO: open maps app or in-app navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Memulai navigasi ke Bukit Safe Point A',
            style: GoogleFonts.inter()),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
