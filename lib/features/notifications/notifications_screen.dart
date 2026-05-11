import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/db/database.dart' as db;
import '../../data/db/daos.dart';
import '../../services/notifications/notification_service.dart';
import '../../core/theme.dart';
import '../../widgets/llm_status_box.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<db.Notification> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, unread, read

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dao = ref.read(notificationDaoProvider);
      final notifications = await dao.getAllNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final service = ref.read(notificationServiceProvider);
      await service.markAsRead(notificationId);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final service = ref.read(notificationServiceProvider);
      await service.markAllAsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final service = ref.read(notificationServiceProvider);
      await service.deleteNotification(notificationId);
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final service = ref.read(notificationServiceProvider);
      await service.clearAllNotifications();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<db.Notification> get _filteredNotifications {
    switch (_filter) {
      case 'unread':
        return _notifications.where((n) => n.readAt == null).toList();
      case 'read':
        return _notifications.where((n) => n.readAt != null).toList();
      default:
        return _notifications;
    }
  }

  int get _unreadCount {
    return _notifications.where((n) => n.readAt == null).length;
  }

  Color _getChannelColor(String channel) {
    switch (channel) {
      case 'price_alerts':
        return WealthColors.accent;
      case 'news_alerts':
        return WealthColors.primary;
      case 'sip_swp_reminders':
        return WealthColors.success;
      case 'fd_maturity':
        return WealthColors.crypto;
      case 'insurance_premium':
        return WealthColors.error;
      case 'daily_digest':
        return WealthColors.fixedDeposit;
      case 'weekly_review':
        return WealthColors.equity;
      default:
        return WealthColors.other;
    }
  }

  IconData _getChannelIcon(String channel) {
    switch (channel) {
      case 'price_alerts':
        return Icons.trending_up;
      case 'news_alerts':
        return Icons.newspaper;
      case 'sip_swp_reminders':
        return Icons.calendar_today;
      case 'fd_maturity':
        return Icons.account_balance;
      case 'insurance_premium':
        return Icons.health_and_safety;
      case 'daily_digest':
        return Icons.summarize;
      case 'weekly_review':
        return Icons.assessment;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildFilterSection()),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredNotifications.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(isDark))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final notification = _filteredNotifications[index];
                    return _buildPremiumNotificationCard(notification, isDark);
                  }, childCount: _filteredNotifications.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Notifications',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: WealthColors.primaryGradient,
          ),
        ),
      ),
      actions: [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(right: 8),
            child: LlmStatusBox(),
          ),
        ),
        if (_unreadCount > 0)
          IconButton(
            icon: Badge(
              label: Text(_unreadCount.toString()),
              child: const Icon(Icons.mark_email_read),
            ),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: _clearAllNotifications,
          tooltip: 'Clear all notifications',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadNotifications,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All'),
            const SizedBox(width: 8),
            _buildFilterChip('unread', 'Unread'),
            const SizedBox(width: 8),
            _buildFilterChip('read', 'Read'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: WealthColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: WealthColors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nothing here yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? WealthColors.textLight : WealthColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'all'
                ? "You're all caught up! Go hunt some assets."
                : 'No $_filter notifications found.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _filter == filter;
    final count = filter == 'unread' ? _unreadCount : null;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.blue : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filter = filter);
      },
      selectedColor: WealthColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildPremiumNotificationCard(
    db.Notification notification,
    bool isDark,
  ) {
    final isUnread = notification.readAt == null;
    final color = _getChannelColor(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread
            ? color.withValues(alpha: isDark ? 0.12 : 0.05)
            : (isDark ? WealthColors.cardDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? color.withValues(alpha: 0.3)
              : (isDark ? WealthColors.borderDark : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _handleTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getChannelIcon(notification.type),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 16,
                                color: isDark
                                    ? WealthColors.textLight
                                    : WealthColors.textDark,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeAgo(notification.firedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    if (isUnread)
                      const PopupMenuItem(
                        value: 'mark_read',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Mark as read'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'mark_read') {
                      _markAsRead(notification.id);
                    } else if (value == 'delete') {
                      _deleteNotification(notification.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(db.Notification notification) {
    if (notification.readAt == null) {
      _markAsRead(notification.id);
    }
    final payloadJson = notification.payloadJson;
    if (payloadJson != null) {
      try {
        final decoded = jsonDecode(payloadJson);
        if (decoded is Map<String, dynamic>) {
          final type = decoded['type']?.toString();
          if (mounted) {
            final holdingId = decoded['holdingId']?.toString();
            if (type == 'news') {
              context.push('/news');
            } else if (type == 'systematic_plan') {
              context.push('/systematic-plans');
            } else if (holdingId != null) {
              context.push('/holdings/$holdingId');
            } else {
              context.push('/');
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }
}
