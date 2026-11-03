import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

import '../providers/earthquake_provider.dart';
import '../models/earthquake_model.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'Semua';
  final _searchCtrl = TextEditingController();

  final _filters = ['Semua', 'Mag > 5.0', 'Potensi tsunami', 'Terdekat'];

  // Fallback data
  final _defaultEarthquakes = const [
    _EarthquakeItem(
      magnitude: 7.2,
      location: 'Selatan Jawa',
      depth: '10 km',
      timeAgo: 'hari ini, 14:02',
      status: 'Awas',
      hasTsunami: true,
    ),
    _EarthquakeItem(
      magnitude: 5.4,
      location: 'Bengkulu',
      depth: '18 km',
      timeAgo: 'kemarin, 09:41',
      status: 'Waspada',
      hasTsunami: false,
    ),
    _EarthquakeItem(
      magnitude: 4.1,
      location: 'Sukabumi',
      depth: '6 km',
      timeAgo: '3 hari lalu',
      status: 'Aman',
      hasTsunami: false,
    ),
    _EarthquakeItem(
      magnitude: 3.6,
      location: 'Lombok Barat',
      depth: '15 km',
      timeAgo: '5 hari lalu',
      status: 'Aman',
      hasTsunami: false,
    ),
  ];

  _EarthquakeItem _fromModel(EarthquakeModel m) {
    final mag = double.tryParse(m.magnitude) ?? 5.0;
    String status = 'Aman';
    if (m.potentialTsunami) {
      status = 'Awas';
    } else if (mag >= 6.5) {
      status = 'Siaga';
    } else if (mag >= 5.0) {
      status = 'Waspada';
    }

    return _EarthquakeItem(
      magnitude: mag,
      location: m.region,
      depth: '${m.depthKm} km',
      timeAgo: m.occurredAt,
      status: status,
      hasTsunami: m.potentialTsunami,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(earthquakeHistoryProvider);
    final bmkgItems = historyAsync.valueOrNull?.map(_fromModel).toList();

    // Ketika masih loading, jangan tampilkan data dummy!
    final List<_EarthquakeItem> items;
    if (historyAsync.isLoading && bmkgItems == null) {
      items = [];
    } else if (bmkgItems != null && bmkgItems.isNotEmpty) {
      items = bmkgItems;
    } else if (historyAsync.hasError && (bmkgItems == null || bmkgItems.isEmpty)) {
      items = _defaultEarthquakes;
    } else {
      items = bmkgItems ?? [];
    }

    final filtered = _filterList(items);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                'Riwayat gempa',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari wilayah atau tanggal',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textMuted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Filter Chips ──
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final isActive = _selectedFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── List ──
            Expanded(
              child: historyAsync.isLoading && bmkgItems == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Memuat riwayat gempa BMKG...',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada data gempa',
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted, fontSize: 14),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(earthquakeHistoryProvider);
                          },
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _buildEarthquakeCard(filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<_EarthquakeItem> _filterList(List<_EarthquakeItem> source) {
    var list = source.toList();

    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((e) => e.location.toLowerCase().contains(query))
          .toList();
    }

    switch (_selectedFilter) {
      case 'Mag > 5.0':
        list = list.where((e) => e.magnitude > 5.0).toList();
        break;
      case 'Potensi tsunami':
        list = list.where((e) => e.hasTsunami).toList();
        break;
      case 'Terdekat':
        list = list.take(2).toList();
        break;
    }

    return list;
  }

  Widget _buildEarthquakeCard(_EarthquakeItem eq) {
    final magColor = _magnitudeColor(eq.magnitude);
    final statusColor = _statusColor(eq.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Magnitude badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: magColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                eq.magnitude.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: magColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eq.location,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${eq.depth} · ${eq.timeAgo}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              eq.status,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _magnitudeColor(double mag) {
    if (mag >= 7.0) return AppColors.danger;
    if (mag >= 5.0) return AppColors.warning;
    if (mag >= 4.0) return AppColors.safe;
    return const Color(0xFF6EE7B7); // light green
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Awas':
        return AppColors.danger;
      case 'Waspada':
        return AppColors.warning;
      default:
        return AppColors.safe;
    }
  }
}

class _EarthquakeItem {
  final double magnitude;
  final String location;
  final String depth;
  final String timeAgo;
  final String status;
  final bool hasTsunami;

  const _EarthquakeItem({
    required this.magnitude,
    required this.location,
    required this.depth,
    required this.timeAgo,
    required this.status,
    required this.hasTsunami,
  });
}
