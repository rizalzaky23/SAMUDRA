import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../earthquake/providers/earthquake_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earthquakeState = ref.watch(earthquakeProvider);
    final authState = ref.watch(authStateProvider);

    final isTsunami = earthquakeState.maybeWhen(
      data: (d) => d.earthquake.potentialTsunami,
      orElse: () => false,
    );

    final userName = authState.user?.name ?? 'Anda';
    final initials = _initials(userName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(earthquakeProvider),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Bar ──
                _buildTopBar(context, initials: initials, isTsunami: isTsunami),
                const SizedBox(height: 16),

                // ── Earthquake Card ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: earthquakeState.when(
                    data: (d) => isTsunami
                        ? _buildTsunamiCard(d)
                        : _buildNormalCard(d),
                    loading: () => _buildLoadingCard(),
                    error: (e, _) => _buildErrorCard(ref),
                  ),
                ),

                const SizedBox(height: 20),

                if (isTsunami) ...[
                  // ── Tsunami Mode Content ──
                  _buildTsunamiContent(context),
                ] else ...[
                  // ── Normal Mode Content ──
                  _buildNormalContent(context),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Bar ──
  Widget _buildTopBar(BuildContext context,
      {required String initials, required bool isTsunami}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B5BDB), Color(0xFF1E40AF)],
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lokasi Anda',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                    Text(
                      'Yogyakarta, ID',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Notification dot
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
              if (isTsunami)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Normal Earthquake Card ──
  Widget _buildNormalCard(RiskAssessment d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B5BDB), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GEMPA TERKINI · BMKG REAL-TIME',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'M ${d.earthquake.magnitude}',
                style: GoogleFonts.inter(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  d.earthquake.occurredAt,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            d.earthquake.region.isNotEmpty
                ? '${d.earthquake.region} · Kedalaman ${d.earthquake.depthKm} km'
                : 'Kedalaman ${d.earthquake.depthKm} km · ${d.distance?.toStringAsFixed(0) ?? "--"} km dari lokasi',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.95),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4ADE80), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Tidak berpotensi tsunami',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tsunami Alert Card ──
  Widget _buildTsunamiCard(RiskAssessment d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                'STATUS AWAS',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Berpotensi tsunami di wilayah Anda',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _tsStatItem('Magnitudo', d.earthquake.magnitude),
              const SizedBox(width: 24),
              _tsStatItem('Kedalaman', '${d.earthquake.depthKm} km'),
              const SizedBox(width: 24),
              _tsStatItem('Jarak', '${d.distance?.toStringAsFixed(0) ?? "--"} km'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tsStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7))),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildErrorCard(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.signal_wifi_off_rounded,
              color: AppColors.danger, size: 32),
          const SizedBox(height: 8),
          Text('Gagal memuat data gempa',
              style: GoogleFonts.inter(
                  color: AppColors.danger, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.refresh(earthquakeProvider),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  // ── Normal Mode Content ──
  Widget _buildNormalContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Akses cepat'),
              const SizedBox(height: 12),
              _buildQuickAccess(context),
              const SizedBox(height: 20),
              _sectionTitle('Cuaca ekstrem'),
              const SizedBox(height: 12),
              _buildWeatherCard(),
              const SizedBox(height: 20),
              _sectionTitle('Titik evakuasi terdekat'),
              const SizedBox(height: 12),
              _buildEvacuationCard(context),
              const SizedBox(height: 20),
              _sectionTitle('Statistik minggu ini'),
              const SizedBox(height: 12),
              _buildStats(),
              const SizedBox(height: 20),
              _sectionTitle('Artikel edukasi'),
              const SizedBox(height: 12),
            ],
          ),
        ),
        _buildArticleCards(),
      ],
    );
  }

  // ── Tsunami Mode Content ──
  Widget _buildTsunamiContent(BuildContext context) {
    return _sectionPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rute Evakuasi Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.map),
              icon: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
              label: Text('Rute Evakuasi Cepat',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _smallActionCard(
                  icon: Icons.map_outlined,
                  label: 'Lihat peta zona',
                  onTap: () => context.go(AppRoutes.map))),
              const SizedBox(width: 12),
              Expanded(child: _smallActionCard(
                  icon: Icons.phone_outlined,
                  label: 'Kontak darurat',
                  onTap: () => context.go(AppRoutes.emergency))),
            ],
          ),
          const SizedBox(height: 14),
          // Warning banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.volume_up_rounded,
                    color: Color(0xFF92400E), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sirine peringatan aktif. Segera menuju dataran tinggi terdekat.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.warningText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Titik evakuasi terdekat'),
          const SizedBox(height: 12),
          _buildEvacPoint(
              icon: Icons.flag_outlined,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              title: 'Bukit Safe Point A',
              subtitle: '1.2 km · jalan kaki 15 menit',
              badge: 'Terdekat',
              badgeColor: AppColors.safe),
          const SizedBox(height: 10),
          _buildEvacPoint(
              icon: Icons.business_outlined,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: AppColors.primary,
              title: 'GOR Siaga Bencana',
              subtitle: '2.4 km · kendaraan 8 menit',
              badge: null,
              badgeColor: AppColors.safe),
          const SizedBox(height: 20),
          _sectionTitle('Langkah keselamatan cepat'),
          const SizedBox(height: 12),
          _buildSafetyStep(1, 'Jauhi pantai dan menuju dataran tinggi'),
          const SizedBox(height: 10),
          _buildSafetyStep(2, 'Bawa dokumen penting dan air minum'),
          const SizedBox(height: 10),
          _buildSafetyStep(3, 'Ikuti arahan petugas BPBD setempat'),
        ],
      ),
    );
  }

  Widget _buildSafetyStep(int num, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: Center(
            child: Text(
              '$num',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _smallActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  // ── Quick Access ──
  Widget _buildQuickAccess(BuildContext context) {
    final items = [
      _QItem(Icons.map_outlined, 'Peta live', AppRoutes.map),
      _QItem(Icons.directions_run_rounded, 'Evakuasi', AppRoutes.evacuation),
      _QItem(Icons.history_rounded, 'Riwayat', AppRoutes.history),
      _QItem(Icons.phone_in_talk_outlined, 'Darurat', AppRoutes.emergency),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: GestureDetector(
              onTap: () => context.go(item.route),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(item.label,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Weather Card ──
  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.iconBgBlue,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.waves_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Waspada gelombang tinggi',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Pesisir selatan Jawa',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Evacuation Card ──
  Widget _buildEvacuationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flag_outlined,
                color: Color(0xFF16A34A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bukit Safe Point A',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('1.2 km · jalan kaki 15 menit',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go(AppRoutes.map),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.navigation_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvacPoint({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String? badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(badge,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor)),
            ),
        ],
      ),
    );
  }

  // ── Stats ──
  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _statCell('18', 'Total gempa')),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _statCell('M 4.1', 'Rata-rata mag.')),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(child: _statCell('1', 'Potensi tsunami')),
        ],
      ),
    );
  }

  Widget _statCell(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  // ── Article Cards (horizontal scroll) ──
  Widget _buildArticleCards() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Container(
          width: 130,
          decoration: BoxDecoration(
            color: AppColors.iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary));
  }

  Widget _sectionPadding({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'AR';
  }
}

class _QItem {
  final IconData icon;
  final String label;
  final String route;
  const _QItem(this.icon, this.label, this.route);
}
