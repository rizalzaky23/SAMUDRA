import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/app_router.dart';
import '../../earthquake/providers/earthquake_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../blog/models/article_model.dart';
import '../../blog/providers/articles_provider.dart';
import '../../blog/widgets/article_detail_sheet.dart';
import '../widgets/emergency_guidance_sheet.dart';

// Provider to toggle between Status Normal (Blue) & Status Bahaya (Red)
final homeDangerModeProvider = StateProvider<bool>((ref) => false);

const double kSheetOverlap = 44;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earthquakeAsync = ref.watch(earthquakeProvider);
    final isManualDanger = ref.watch(homeDangerModeProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    // If live data has tsunami warning or manual toggle is active, show danger mode
    final isDanger = isManualDanger ||
        earthquakeAsync.maybeWhen(
          data: (d) => d.earthquake.potentialTsunami || d.risk == 'Awas',
          orElse: () => false,
        );

    // Bell shows red badge only when there IS tsunami potential
    final hasTsunamiWarning = earthquakeAsync.maybeWhen(
      data: (d) => d.earthquake.potentialTsunami || d.risk == 'Awas',
      orElse: () => false,
    );

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ───────────────────────────────────────────────────────────
            // HEADER: blue gradient + two translucent wave layers.
            // ───────────────────────────────────────────────────────────
            Stack(
              children: [
                // Blue gradient container.
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: topPadding + 6,
                    left: 20,
                    right: 20,
                    bottom: 40 + kSheetOverlap,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDanger
                          ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
                          : const [Color(0xFF3B6FE8), Color(0xFF2952D9)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(context, ref,
                          isDanger: isDanger,
                          hasTsunamiWarning: hasTsunamiWarning),
                      const SizedBox(height: 14),
                      isDanger
                          ? _buildDangerHeaderInfo()
                          : _buildNormalHeaderInfo(earthquakeAsync),
                    ],
                  ),
                ),

                // Wave painter — 90px tall at the bottom of header
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CustomPaint(
                    size: Size(screenWidth, 90),
                    painter: const _HeaderWavePainter(),
                  ),
                ),
              ],
            ),

            // ───────────────────────────────────────────────────────────
            // CONTENT CARD: white, rounded top corners with overlap.
            // ───────────────────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -kSheetOverlap),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.elliptical(64, kSheetOverlap),
                    topRight: Radius.elliptical(64, kSheetOverlap),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: isDanger
                      ? _buildDangerContent(context)
                      : _buildNormalContent(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar (Shared on both screens) ──
  Widget _buildTopBar(BuildContext context, WidgetRef ref,
      {required bool isDanger, required bool hasTsunamiWarning}) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final initials = _getInitials(user?.name);
    final hasAvatar =
        user?.avatarUrl != null && user!.avatarUrl!.trim().isNotEmpty;

    final notificationsState = ref.watch(notificationsProvider);
    final unreadCount = notificationsState.unreadCount;
    final showBadge = hasTsunamiWarning || unreadCount > 0;

    return Row(
      children: [
        // Rounded circular Avatar with user photo (Google profile) or dynamic initials
        GestureDetector(
          onTap: () {
            context.go(AppRoutes.profile);
          },
          onLongPress: () {
            // Secret/quick toggle for testing
            ref.read(homeDangerModeProvider.notifier).state = !isDanger;
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? CachedNetworkImage(
                      imageUrl: user.avatarUrl!,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Lokasi Anda & Yogyakarta, ID
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lokasi Anda',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Yogyakarta, ID',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Notification Bell — tap to open Notification History
        GestureDetector(
          onTap: () {
            context.push(AppRoutes.notifications);
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                // Badge indikator notifikasi (merah untuk tsunami/awas, oranye untuk unread baru)
                if (showBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: hasTsunamiWarning
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  // ── Layar Kiri: Header Info (Merah - Status Bahaya) ──
  Widget _buildDangerHeaderInfo() {
    return Column(
      children: [
        // Warning triangle inside white circle
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // STATUS AWAS
        Text(
          'STATUS AWAS',
          style: GoogleFonts.inter(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),

        // Subteks
        Text(
          'Berpotensi tsunami di wilayah Anda',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.90),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),

        // Tiga Metrik Ringkas: Magnitudo 7.5, Kedalaman 10 km, Jarak 35 km
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMetricItem(label: 'Magnitudo', value: '7.5'),
            Container(
              height: 26,
              width: 1,
              color: Colors.white.withValues(alpha: 0.25),
              margin: const EdgeInsets.symmetric(horizontal: 20),
            ),
            _buildMetricItem(label: 'Kedalaman', value: '10 km'),
            Container(
              height: 26,
              width: 1,
              color: Colors.white.withValues(alpha: 0.25),
              margin: const EdgeInsets.symmetric(horizontal: 20),
            ),
            _buildMetricItem(label: 'Jarak', value: '35 km'),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            color: Colors.white.withValues(alpha: 0.80),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ── Layar Kanan: Header Info (Biru - Status Normal) ──
  Widget _buildNormalHeaderInfo(AsyncValue<RiskAssessment> earthquakeAsync) {
    final mag = earthquakeAsync.maybeWhen(
      data: (d) => d.earthquake.magnitude,
      orElse: () => '4.8',
    );
    final region = earthquakeAsync.maybeWhen(
      data: (d) => d.earthquake.region.isNotEmpty
          ? d.earthquake.region
          : '45 km SW Bantul',
      orElse: () => '45 km SW Bantul',
    );
    final depth = earthquakeAsync.maybeWhen(
      data: (d) => d.earthquake.depthKm,
      orElse: () => '12',
    );

    return Column(
      children: [
        // Label GEMPA TERKINI
        Text(
          'GEMPA TERKINI',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),

        // Big Magnitude M 4.8 + 10 menit lalu
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'M $mag',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '10 menit lalu',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),

        // Detail Kedalaman & Wilayah
        Text(
          'Kedalaman $depth km · $region',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),

        // Badge pill hijau: Tidak berpotensi tsunami (lega & sempurna)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_rounded,
                color: Color(0xFF15803D),
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                'Tidak berpotensi tsunami',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Layar Kiri: Body Content (Status Bahaya) ──
  Widget _buildDangerContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CTA Utama: "Rute Evakuasi Cepat" (3D Pill Button)
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2A66F6),
                Color(0xFF1447CD),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            painter: const _Embossed3DButtonPainter(radius: 18),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.go(AppRoutes.map),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 20),
                      Text(
                        'Rute Evakuasi Cepat',
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Dua tombol sekunder berdampingan
        Row(
          children: [
            Expanded(
              child: _buildSecondaryCardButton(
                icon: Icons.map_outlined,
                label: 'Lihat peta zona',
                onTap: () => context.go(AppRoutes.map),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryCardButton(
                icon: Icons.phone_outlined,
                label: 'Kontak darurat',
                onTap: () => context.go(AppRoutes.emergency),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Banner peringatan kuning muda (Speaker icon)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFFB45309),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sirine peringatan aktif. Segera menuju dataran tinggi terdekat.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section Title: Titik evakuasi terdekat
        Text(
          'Titik evakuasi terdekat',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        // Card 1: Bukit Safe Point A (Terdekat)
        _buildEvacuationCardItem(
          icon: Icons.flag_outlined,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          title: 'Bukit Safe Point A',
          subtitle: '1.2 km · jalan kaki 15 menit',
          badgeText: 'Terdekat',
        ),

        const SizedBox(height: 10),

        // Card 2: GOR Siaga Bencana
        _buildEvacuationCardItem(
          icon: Icons.apartment_rounded,
          iconBg: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0284C7),
          title: 'GOR Siaga Bencana',
          subtitle: '2.4 km · kendaraan 8 menit',
        ),
      ],
    );
  }

  // ── Layar Kanan: Body Content (Status Normal) ──
  Widget _buildNormalContent(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Akses cepat
        Text(
          'Akses cepat',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        // 4 kotak kecil berisi ikon + label
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.map_outlined,
                label: 'Peta live',
                onTap: () => context.go(AppRoutes.map),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.alt_route_rounded,
                label: 'Evakuasi',
                onTap: () => context.go(AppRoutes.evacuation),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.history_rounded,
                label: 'Riwayat',
                onTap: () => context.go(AppRoutes.history),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.phone_outlined,
                label: 'Darurat',
                onTap: () => context.go(AppRoutes.emergency),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section: Cuaca ekstrem
        Text(
          'Cuaca ekstrem',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        // Card cuaca ekstrem
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.cloud_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waspada gelombang tinggi',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pesisir selatan Jawa',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section: Titik evakuasi terdekat
        Text(
          'Titik evakuasi terdekat',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        // Card titik evakuasi terdekat dengan tombol bulat biru di kanan
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bukit Safe Point A',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1.2 km · jalan kaki 15 menit',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.map),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D4ED8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.alt_route_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section: Panduan Kesiapsiagaan Bencana
        Text(
          'Kesiapsiagaan bencana',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        _buildGuidanceCard(
          icon: Icons.directions_run_rounded,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          title: 'Langkah evakuasi mandiri',
          subtitle: 'Panduan mitigasi & tindakan saat gempa/tsunami',
          onTap: () => showMitigasiBottomSheet(context, ref),
        ),
        const SizedBox(height: 10),
        _buildGuidanceCard(
          icon: Icons.inventory_2_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          title: 'Peralatan siaga bencana',
          subtitle: 'Daftar tas siaga darurat & perlengkapan penting',
          onTap: () => showPeralatanBottomSheet(context, ref),
        ),

        const SizedBox(height: 20),

        // Section: Statistik minggu ini (padding vertikal lebih lega)
        Text(
          'Statistik minggu ini',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        // 3 Card Angka
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                value: '18',
                label: 'Total gempa',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                value: 'M 4.1',
                label: 'Rata-rata mag.',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                value: '1',
                label: 'Potensi tsunami',
                valueColor: const Color(0xFF1D4ED8), // Blue emphasis
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section: Artikel edukasi (horizontal scroll hint)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Artikel edukasi',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        articlesAsync.when(
          data: (articles) {
            final items = articles.isNotEmpty ? articles : fallbackArticles;
            return SizedBox(
              height: 125,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) => _buildArticleCard(context, items[i]),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 125,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => SizedBox(
            height: 125,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: fallbackArticles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _buildArticleCard(context, fallbackArticles[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Secondary Card Button (Lihat peta zona & Kontak darurat) ──
  Widget _buildSecondaryCardButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Evacuation Point Card Item ──
  Widget _buildEvacuationCardItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
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
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Quick Action Item (Akses cepat 4 kotak) ──
  Widget _buildQuickActionItem({
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Guidance Card (Langkah evakuasi & peralatan siaga) ──
  Widget _buildGuidanceCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat Card (Statistik minggu ini) ──
  Widget _buildStatCard({
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Article Card ──
  Widget _buildArticleCard(BuildContext context, ArticleModel article) {
    final hasImage = article.coverImageUrl != null && article.coverImageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => ArticleDetailSheet.show(context, article),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: article.coverImageUrl!,
                  height: 52,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 52,
                    color: const Color(0xFFF1F5F9),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 6),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  article.categoryLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    article.title,
                    maxLines: hasImage ? 2 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.readTime,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Wave Painter ──
// Two translucent wave layers painted at the base of the blue header.
// The bottom portion of these waves will be hidden by the white content card
// that overlaps from below, revealing only the top portion as the "wave pita".
class _HeaderWavePainter extends CustomPainter {
  const _HeaderWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Wave 1 — further back, peak at left-center (~25% x), fainter
    final p1 = Path()
      ..moveTo(0, h * 0.35)
      ..cubicTo(
        w * 0.25, h * 0.05, // peak: rises high on the left
        w * 0.55, h * 0.75, // valley: dips on the right
        w, h * 0.25,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.8],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(p1, paint1);

    // Wave 2 — closer layer, peak shifted to center-right (~55% x), brighter
    final p2 = Path()
      ..moveTo(0, h * 0.60)
      ..cubicTo(
        w * 0.30, h * 0.28, // start of rise
        w * 0.55, h * 0.00, // peak: rises to very top
        w, h * 0.40,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.20),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.8],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(p2, paint2);
  }

  @override
  bool shouldRepaint(_HeaderWavePainter old) => false;
}

// ── 3D Embossed Button Painter (top inner highlight for "menjendol" effect) ──
class _Embossed3DButtonPainter extends CustomPainter {
  final double radius;
  const _Embossed3DButtonPainter({this.radius = 18});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.8, 0.8, size.width - 1.6, size.height - 1.6),
      Radius.circular(radius),
    );

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.8],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, highlightPaint);
  }

  @override
  bool shouldRepaint(_Embossed3DButtonPainter old) => false;
}
