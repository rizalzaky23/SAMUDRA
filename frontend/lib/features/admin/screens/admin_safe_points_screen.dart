import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../map/models/safe_point_model.dart';
import '../../map/providers/safe_points_provider.dart';

class AdminSafePointsScreen extends ConsumerStatefulWidget {
  const AdminSafePointsScreen({super.key});

  @override
  ConsumerState<AdminSafePointsScreen> createState() =>
      _AdminSafePointsScreenState();
}

class _AdminSafePointsScreenState
    extends ConsumerState<AdminSafePointsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(safePointsProvider.notifier).loadSafePoints());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(safePointsProvider);
    final allPoints = state.points;

    final filteredPoints = _searchQuery.isEmpty
        ? allPoints
        : allPoints.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.subtitle.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Titik Aman Peta',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showSafePointDialog(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Tambah',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner shortcut ke live map
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peta Evakuasi Interaktif',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lihat semua titik & rute evakuasi secara langsung',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.map),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF059669),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Buka Peta',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Cari titik aman atau lokasi...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF94A3B8), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List titik aman
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPoints.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(safePointsProvider.notifier)
                            .loadSafePoints(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredPoints.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final point = filteredPoints[index];
                            return _buildPointCard(point);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off_rounded,
                size: 36, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Belum ada titik aman tersimpan'
                : 'Tidak ada hasil untuk "$_searchQuery"',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Klik tombol "Tambah" di atas untuk menambahkan titik baru.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointCard(SafePointModel point) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              point.icon,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        point.name,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (point.capacity != null && point.capacity! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${point.capacity} jiwa',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                  ],
                ),
                if (point.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    point.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded,
                        size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444), size: 20),
            onPressed: () => _confirmDelete(point),
            tooltip: 'Hapus titik aman',
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SafePointModel point) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Hapus Titik Aman?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Titik aman "${point.name}" akan dihapus dari peta semua pengguna.',
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Batal',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref
                  .read(safePointsProvider.notifier)
                  .deleteSafePoint(point.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Titik aman "${point.name}" berhasil dihapus'
                        : 'Gagal menghapus titik aman'),
                    backgroundColor: success
                        ? const Color(0xFF059669)
                        : const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Hapus',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSafePointDialog(BuildContext screenContext) {
    final nameCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: '-7.780000');
    final lngCtrl = TextEditingController(text: '110.360000');
    final capCtrl = TextEditingController();
    String selectedIcon = '⛺';
    bool isSubmitting = false;

    final icons = ['⛺', '🏔️', '🏛️', '🕌', '🏟️', '🏥', '🏢'];

    showModalBottomSheet(
      context: screenContext,
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
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tambah Titik Aman Baru',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Titik aman akan langsung muncul di peta evakuasi untuk semua pengguna.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nama
                  Text('Nama Lokasi *',
                      style: GoogleFonts.inter(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Posko Lapangan Merdeka',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
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

                  // Ikon
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
                            Text('Latitude *',
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
                            Text('Longitude *',
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

                  // Submit
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
                                  ScaffoldMessenger.of(screenContext);
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

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Titik aman "$name" berhasil ditambahkan!'
                                      : 'Gagal menyimpan titik aman. Periksa koneksi backend.'),
                                  backgroundColor: success
                                      ? const Color(0xFF059669)
                                      : AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Simpan Titik Aman',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
}
