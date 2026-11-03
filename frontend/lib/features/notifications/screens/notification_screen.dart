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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Riwayat Notifikasi',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (state.notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF64748B),
              ),
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
                      const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Tandai semua dibaca',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Text(
                        'Hapus semua riwayat',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterTabs(state),

          // Notification List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.loadNotifications(),
              color: AppColors.primary,
              child: state.isLoading && state.notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredNotifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: filteredNotifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, index) {
                            final item = filteredNotifications[index];
                            return _buildNotificationCard(item, notifier);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(NotificationsState state) {
    final filters = ['Semua', 'Peringatan', 'Edukasi & Info'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
              ),
              onSelected: (_) {
                setState(() => _selectedFilter = f);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(
      NotificationModel item, NotificationsNotifier notifier) {
    Color iconBg;
    Color iconColor;
    IconData icon;
    String badgeText;

    if (item.isTsunami) {
      iconBg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.tsunami_rounded;
      badgeText = 'PERINGATAN TSUNAMI';
    } else if (item.isEarthquake) {
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      icon = Icons.sensors_rounded;
      badgeText = 'INFO GEMPA';
    } else if (item.isArticle) {
      iconBg = const Color(0xFFE0E7FF);
      iconColor = const Color(0xFF4F46E5);
      icon = Icons.menu_book_rounded;
      badgeText = 'EDUKASI';
    } else {
      iconBg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF475569);
      icon = Icons.notifications_none_rounded;
      badgeText = 'INFORMASI';
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        notifier.markAsRead(item.id);
      },
      child: GestureDetector(
        onTap: () {
          notifier.markAsRead(item.id);
          _handleNotificationTap(item);
        },
        child: Container(
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE2E8F0)
                  : AppColors.primary.withValues(alpha: 0.3),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
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

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge category & time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTimeAgo(item.sentAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Body
                    Text(
                      item.body,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.35,
                        color: const Color(0xFF64748B),
                      ),
                    ),

                    // Earthquake metadata chips (if available)
                    if (item.data != null &&
                        (item.data!['magnitude'] != null || item.data!['depthKm'] != null || item.data!['depth'] != null)) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.data!['magnitude'] != null)
                            _buildInfoChip(
                              Icons.bolt_rounded,
                              'M ${item.data!['magnitude']}',
                              const Color(0xFFEF4444),
                            ),
                          if (item.data!['depthKm'] != null || item.data!['depth'] != null)
                            _buildInfoChip(
                              Icons.arrow_downward_rounded,
                              '${item.data!['depthKm'] ?? item.data!['depth']} km',
                              const Color(0xFF0284C7),
                            ),
                          if (item.data!['region'] != null)
                            _buildInfoChip(
                              Icons.location_on_outlined,
                              item.data!['region'].toString(),
                              const Color(0xFF475569),
                              maxWidth: 160,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color,
      {double? maxWidth}) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel item) {
    if (item.isTsunami || item.isEarthquake) {
      // Buka Peta Live atau Riwayat Gempa
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum Ada Notifikasi',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
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
            child: Text('Hapus',
                style: GoogleFonts.inter(color: Colors.white)),
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
      return '${difference.inMinutes} mnt lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

