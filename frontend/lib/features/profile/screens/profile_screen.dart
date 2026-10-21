import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/settings_provider.dart';
import '../../admin/providers/admin_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _locationPermissionGranted = status == LocationPermission.always ||
            status == LocationPermission.whileInUse;
      });
    }
  }

  Future<void> _handleLocationToggle(bool value) async {
    final settings = ref.read(settingsProvider.notifier);

    if (value) {
      var status = await Geolocator.checkPermission();
      if (status == LocationPermission.denied) {
        status = await Geolocator.requestPermission();
      }
      if (status == LocationPermission.deniedForever) {
        if (mounted) _showPermissionDialog();
        return;
      }
      final granted = status == LocationPermission.always ||
          status == LocationPermission.whileInUse;
      if (mounted) setState(() => _locationPermissionGranted = granted);
      await settings.setLocationRealtime(granted);
    } else {
      await settings.setLocationRealtime(false);
      if (mounted) {
        _showSnackbar(
          'Izin lokasi dimatikan. Buka Pengaturan untuk mengaktifkan kembali.',
          icon: Icons.location_off_rounded,
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Izin Lokasi Ditolak',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Akses lokasi telah diblokir secara permanen. Buka Pengaturan Aplikasi untuk mengaktifkannya.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Geolocator.openAppSettings();
              await _checkLocationPermission();
            },
            child: Text('Buka Pengaturan',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final langs = ['Indonesia', 'English'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
            const SizedBox(height: 20),
            Text(
              'Pilih Bahasa',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ...langs.map((lang) {
              final current =
                  ref.read(settingsProvider).language == lang;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(lang,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight:
                            current ? FontWeight.w600 : FontWeight.w400,
                        color: current
                            ? AppColors.primary
                            : AppColors.textPrimary)),
                trailing: current
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLanguage(lang);
                  Navigator.of(ctx).pop();
                  _showSnackbar('Bahasa diubah ke $lang',
                      icon: Icons.language_rounded);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showMitigasiSheet() {
    ref.read(adminProvider.notifier).loadMitigasi();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final adminState = ref.watch(adminProvider);
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Langkah Mitigasi Mandiri',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: adminState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : adminState.mitigasiSteps.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada panduan mitigasi',
                                style: GoogleFonts.inter(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: adminState.mitigasiSteps.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) {
                                final item = adminState.mitigasiSteps[i];
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${item.stepNumber}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: AspectRatio(
                                                  aspectRatio: 16 / 9,
                                                  child: CachedNetworkImage(
                                                    imageUrl: item.imageUrl!,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) => Container(
                                                      color: const Color(0xFFE2E8F0),
                                                      child: const Center(
                                                        child: SizedBox(
                                                          width: 18,
                                                          height: 18,
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        ),
                                                      ),
                                                    ),
                                                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Text(
                                              item.description,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPeralatanSheet() {
    ref.read(adminProvider.notifier).loadPeralatan();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final adminState = ref.watch(adminProvider);
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded, color: Color(0xFFF59E0B), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Peralatan Siaga Bencana',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: adminState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : adminState.peralatan.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada daftar peralatan',
                                style: GoogleFonts.inter(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: adminState.peralatan.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) {
                                final item = adminState.peralatan[i];
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.category,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFFB45309),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: CachedNetworkImage(
                                              imageUrl: item.imageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(
                                                color: const Color(0xFFE2E8F0),
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        item.description,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final settings = ref.watch(settingsProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Profile header ──
              _buildProfileHeader(user),

              const SizedBox(height: 28),

              // ── Admin section (hanya tampil jika admin / super_admin) ──
              if (user?.isAdmin == true) ...[
                _buildSectionLabel('Administrasi'),
                const SizedBox(height: 8),
                _buildMenuItem(
                  icon: Icons.admin_panel_settings_rounded,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  title: 'Panel Admin (${user?.isSuperAdmin == true ? 'Super Admin' : 'Admin'})',
                  onTap: () => context.push(AppRoutes.admin),
                ),
                const SizedBox(height: 24),
              ],

              // ── Edukasi & panduan ──
              _buildSectionLabel('Edukasi & panduan'),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.menu_book_outlined,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: AppColors.primary,
                title: 'Langkah evakuasi mandiri',
                onTap: _showMitigasiSheet,
              ),
              const SizedBox(height: 10),
              _buildMenuItem(
                icon: Icons.inventory_2_outlined,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: AppColors.primary,
                title: 'Peralatan siaga bencana',
                onTap: _showPeralatanSheet,
              ),

              const SizedBox(height: 24),

              // ── Pengaturan ──
              _buildSectionLabel('Pengaturan'),
              const SizedBox(height: 8),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildToggleItem(
                      title: 'Izin lokasi real-time',
                      value: settings.locationRealtime &&
                          _locationPermissionGranted,
                      onChanged: _handleLocationToggle,
                    ),
                    _buildInnerDivider(),
                    _buildToggleItem(
                      title: 'Sirine notifikasi bahaya',
                      value: settings.sirenNotif,
                      onChanged: (v) async {
                        await ref
                            .read(settingsProvider.notifier)
                            .setSirenNotif(v);
                        _showSnackbar(
                          v
                              ? 'Sirine notifikasi diaktifkan'
                              : 'Sirine notifikasi dimatikan',
                          icon: v
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                        );
                      },
                    ),
                    _buildInnerDivider(),
                    _buildToggleItem(
                      title: 'Mode offline',
                      value: settings.offlineMode,
                      onChanged: (v) async {
                        await ref
                            .read(settingsProvider.notifier)
                            .setOfflineMode(v);
                        _showSnackbar(
                          v ? 'Mode offline diaktifkan' : 'Mode offline dimatikan',
                          icon: v ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                        );
                      },
                    ),
                    _buildInnerDivider(),
                    _buildSettingRow(
                      title: 'Bahasa',
                      value: settings.language,
                      onTap: _showLanguageSheet,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Logout button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildLogoutButton(),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile header with Google photo sync ──
  Widget _buildProfileHeader(user) {
    final isGoogle =
        user != null && user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    final initials = _initials(user?.name ?? 'Anda');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isGoogle
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3B5BDB), Color(0xFF1E40AF)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isGoogle
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user!.avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _avatarInitials(initials),
                      errorWidget: (_, __, ___) => _avatarInitials(initials),
                    ),
                  )
                : _avatarInitials(initials),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Pengguna',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? 'Belum masuk',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                if (isGoogle) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Akun Google tersinkron',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitials(String initials) => Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
              fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      );

  // ── Logout ──
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Keluar dari akun?',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            content: Text('Anda akan keluar dari SAMUDRA.',
                style: GoogleFonts.inter(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Batal',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Keluar',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          await ref.read(authStateProvider.notifier).logout();
          if (mounted) context.go(AppRoutes.login);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.danger.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            Text(
              'Keluar',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable widgets ──
  Widget _buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.2),
        ),
      );

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInnerDivider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, color: AppColors.border),
      );

  Widget _buildToggleItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.all(Colors.white),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return const Color(0xFFCBD5E1);
            }),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}
