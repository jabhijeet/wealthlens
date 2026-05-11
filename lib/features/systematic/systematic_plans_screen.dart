import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/db/database.dart';
import '../../providers/providers.dart';
import 'add_systematic_plan_screen.dart';
import '../../core/theme.dart';
import '../../services/systematic/systematic_plan_service.dart';

class SystematicPlansScreen extends ConsumerStatefulWidget {
  const SystematicPlansScreen({super.key, this.holdingId});
  final String? holdingId;

  @override
  ConsumerState<SystematicPlansScreen> createState() =>
      _SystematicPlansScreenState();
}

class _SystematicPlansScreenState extends ConsumerState<SystematicPlansScreen> {
  @override
  Widget build(BuildContext context) {
    final plansAsync = widget.holdingId != null
        ? ref.watch(holdingSystematicPlansProvider(widget.holdingId!))
        : ref.watch(systematicPlansProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.holdingId != null ? 'Systematic Plans' : 'All Plans',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _navigateToAdd(context),
            tooltip: 'Add new plan',
          ),
        ],
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlanCard(
                      plan: plan,
                      isDark: isDark,
                      onStatusUpdate: (status) =>
                          _updatePlanStatus(plan.id, status),
                      onDelete: () => _deletePlan(plan.id),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (100 * index).ms)
                  .slideY(begin: 0.1, end: 0);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: WealthColors.primary),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Plan'),
      ),
    );
  }

  Future<void> _navigateToAdd(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            AddSystematicPlanScreen(holdingId: widget.holdingId),
      ),
    );
    // Refresh if needed (Riverpod should handle it if provider is invalidated)
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: WealthColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.autorenew_rounded,
              size: 48,
              color: WealthColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No systematic plans found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Create SIP, SWP, or STP plans to automate\nyour investment workflows.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: WealthColors.textMuted),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToAdd(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create First Plan'),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Future<void> _updatePlanStatus(String planId, String status) async {
    try {
      final service = ref.read(systematicPlanServiceProvider);
      await service.updatePlanStatus(planId, status);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Plan $status successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: WealthColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deletePlan(String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text(
          'Are you sure you want to delete this plan? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WealthColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(systematicPlanServiceProvider);
        await service.deletePlan(planId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: WealthColors.error,
            ),
          );
        }
      }
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isDark,
    required this.onStatusUpdate,
    required this.onDelete,
  });

  final SystematicPlan plan;
  final bool isDark;
  final void Function(String) onStatusUpdate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(plan.status);
    final kindIcon = _getKindIcon(plan.kind);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WealthColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(kindIcon, color: WealthColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.kind.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getFrequencyText(plan.frequency, plan.dayOfMonth),
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: WealthColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.status.toUpperCase(),
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(label: 'Amount', value: '${plan.amountMinor ~/ 100}'),
              const Spacer(),
              _Metric(
                label: 'Start Date',
                value: plan.startDate.toString().split(' ')[0],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              if (plan.status == 'active')
                _ActionButton(
                  label: 'Pause',
                  icon: Icons.pause_rounded,
                  color: WealthColors.accent,
                  onTap: () => onStatusUpdate('paused'),
                )
              else if (plan.status == 'paused')
                _ActionButton(
                  label: 'Resume',
                  icon: Icons.play_arrow_rounded,
                  color: WealthColors.success,
                  onTap: () => onStatusUpdate('active'),
                ),
              const SizedBox(width: 8),
              _ActionButton(
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                color: WealthColors.error,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return WealthColors.success;
      case 'paused':
        return WealthColors.accent;
      case 'completed':
        return WealthColors.primary;
      case 'cancelled':
        return WealthColors.error;
      default:
        return WealthColors.other;
    }
  }

  IconData _getKindIcon(String kind) {
    switch (kind) {
      case 'sip':
        return Icons.trending_up_rounded;
      case 'swp':
        return Icons.trending_down_rounded;
      case 'stp':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.autorenew_rounded;
    }
  }

  String _getFrequencyText(String frequency, int? dayOfMonth) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return dayOfMonth != null ? 'Monthly on day $dayOfMonth' : 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return frequency;
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.sora(fontSize: 11, color: WealthColors.textMuted),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
