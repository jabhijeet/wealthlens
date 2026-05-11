import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/db/database.dart' as db;
import '../../data/db/daos.dart';
import '../../core/theme.dart';
import '../../widgets/llm_status_box.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  bool _isLoading = true;
  List<dynamic> _activityItems = [];

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() => _isLoading = true);
    try {
      final notificationDao = ref.read(notificationDaoProvider);
      final transactionDao = ref.read(transactionDaoProvider);
      
      final notifications = await notificationDao.getAllNotifications();
      final transactions = await transactionDao.getRecent();
      
      final items = [...notifications, ...transactions]..sort((a, b) {
        final dateA = a is db.Notification ? a.firedAt : (a as db.Transaction).date;
        final dateB = b is db.Notification ? b.firedAt : (b as db.Transaction).date;
        return dateB.compareTo(dateA);
      });

      setState(() {
        _activityItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading activity: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? WealthColors.surfaceDark : WealthColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_activityItems.isEmpty)
            _buildEmptyState(isDark)
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildActivityItem(_activityItems[index], isDark),
                  childCount: _activityItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Activity Log',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: WealthColors.primaryGradient,
          ),
        ),
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LlmStatusBox(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadActivity,
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: WealthColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No activity yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: WealthColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(dynamic item, bool isDark) {
    if (item is db.Notification) {
      return _NotificationItem(notification: item, isDark: isDark);
    } else if (item is db.Transaction) {
      return _TransactionItem(transaction: item, isDark: isDark);
    }
    return const SizedBox.shrink();
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({required this.notification, required this.isDark});
  final db.Notification notification;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WealthColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_outlined, color: WealthColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: GoogleFonts.inter(fontSize: 13, color: WealthColors.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(notification.firedAt),
                  style: GoogleFonts.inter(fontSize: 11, color: WealthColors.textMuted.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({required this.transaction, required this.isDark});
  final db.Transaction transaction;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isBuy = transaction.type == db.TransactionType.buy || 
                  transaction.type == db.TransactionType.contribution;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isBuy ? Colors.green : Colors.red).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBuy ? Icons.add_chart_rounded : Icons.show_chart_rounded,
              color: isBuy ? Colors.green : Colors.red,
              size: 20,
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
                    Text(
                      '${transaction.type.name.toUpperCase()} Transaction',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      '${isBuy ? "+" : "-"}${transaction.quantity}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: isBuy ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (transaction.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.notes!,
                    style: GoogleFonts.inter(fontSize: 13, color: WealthColors.textMuted),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.date),
                  style: GoogleFonts.inter(fontSize: 11, color: WealthColors.textMuted.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
