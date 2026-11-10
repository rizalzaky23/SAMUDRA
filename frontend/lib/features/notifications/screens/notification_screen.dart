import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends ConsumerState<NotificationHistoryScreen> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    // Filter notifikasi
    final filteredNotifications = state.notifications.where((n) {
      if (_selectedFilter == 'Peringatan') {
        return n.isTsunami || n.isEarthquake;
      } else if (_selectedFilter == 'Edukasi & Info') {
        return n.isArticle || (!n.isTsunami && !n.isEarthquake);
      }
      return true;
    }).toList();

    // Pisahkan ke grup "Terbaru" (4 teratas) & "Sebelumnya" (sisanya) seperti referensi
    final recentItems = filteredNotifications.take(4).toList();
    final previousItems = filteredNotifications.length > 4
        ? filteredNotifications.sublist(4)
        : <NotificationModel>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar (sesuai referensi: tombol bulat <, judul tengah, tombol bulat •••) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                children: [
                  _buildCircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => context.pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Notifikasi',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  _buildMoreMenuButton(state, notifier),
                ],
              ),
            ),

            // ── Filter Chips ──
            _buildFilterTabs(),

            const SizedBox(height: 6),

            // ── Notification List (Grouped: Terbaru & Sebelumnya) ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => notifier.loadNotifications(),
                color: AppColors.primary,
                child: state.isLoading && state.notifications.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredNotifications.isEmpty
                        ? _buildEmptyState()
                        : ListView(
                            padding: const EdgeInsets.only(top: 6, bottom: 32),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            children: [
                              if (recentItems.isNotEmpty) ...[
                                _buildSectionHeader(
                                  title: 'Terbaru',
                                  actionText: state.unreadCount > 0
                                      ? 'Tandai dibaca'
                                      : null,
                                  onActionTap: state.unreadCount > 0
                                      ? () => notifier.markAllAsRead()
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                ...recentItems.map(
                                  (item) =>
                                      _buildNotificationRow(item, notifier),
                                ),
                              ],
                              if (previousItems.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                _buildSectionHeader(title: 'Sebelumnya'),
                                const SizedBox(height: 4),
                                ...previousItems.map(
                                  (item) =>
                                      _buildNotificationRow(item, notifier),
                                ),
                              ],
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(
          icon,
          size: 22,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildMoreMenuButton(
    NotificationsState state,
    NotificationsNotifier notifier,
  ) {
    return PopupMenuButton<String>(
      enabled: state.notifications.isNotEmpty,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onSelected: (val) {
        if (val == 'mark_all_read') {
          notifier.markAllAsRead();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Semua notifikasi ditandai dibaca'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (val == 'clear_all') {
          _showClearConfirmDialog(notifier);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'mark_all_read',
          child: Row(
            children: [
              const Icon(Icons.done_all_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Tandai semua dibaca',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'clear_all',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.danger),
              const SizedBox(width: 10),
              Text(
                'Hapus semua riwayat',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          size: 20,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['Semua', 'Peringatan', 'Edukasi & Info'];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSelected = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(
                  f,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(
    NotificationModel item,
    NotificationsNotifier notifier,
  ) {
    IconData icon;
    if (item.isTsunami) {
      icon = Icons.waves_rounded;
    } else if (item.isEarthquake) {
      icon = Icons.sensors_rounded;
    } else if (item.isArticle) {
      icon = Icons.menu_book_rounded;
    } else {
      icon = Icons.notifications_none_rounded;
    }

    final isUnread = !item.isRead;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: const Color(0xFFEF4444),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        notifier.markAsRead(item.id);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          notifier.markAsRead(item.id);
          _handleNotificationTap(item);
        },
        child: Container(
          color: isUnread ? Colors.white : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular icon container (sesuai gambar referensi)
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isUnread ? const Color(0xFFEFF6FF) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnread
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2563EB),
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Compact relative timestamp on the right
              Text(
                _formatTimeAgo(item.sentAt),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                  color: isUnread
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel item) {
    if (item.isTsunami || item.isEarthquake) {
      context.go(AppRoutes.map);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 34,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum Ada Notifikasi',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Notifikasi peringatan dini gempa, potensi tsunami, dan informasi kesiapsiagaan bencana akan tampil di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmDialog(NotificationsNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Semua Riwayat?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Semua riwayat notifikasi yang tersimpan di perangkat ini akan dibersihkan.',
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.clearAll();
            },
            child:
                Text('Hapus', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j lalu';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}h lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
