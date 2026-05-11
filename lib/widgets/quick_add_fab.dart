import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class QuickAddFab extends StatelessWidget {
  const QuickAddFab({super.key});

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? WealthColors.surfaceDark : WealthColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _ActionCard(
                    title: 'Add Holding',
                    subtitle: 'Manually add a new asset to your portfolio',
                    icon: Icons.add_chart_rounded,
                    color: WealthColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/holdings/new');
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Import Statements',
                    subtitle: 'Upload PDF statements for auto-parsing',
                    icon: Icons.file_upload_rounded,
                    color: WealthColors.success,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/import');
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Ask AI Assistant',
                    subtitle: 'Get intelligent insights on your portfolio',
                    icon: Icons.auto_awesome_rounded,
                    color: WealthColors.accentDark,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/ai-chat');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showAddOptions(context),
      backgroundColor: WealthColors.primary,
      elevation: 4,
      child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? WealthColors.cardDarkElevated : WealthColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? WealthColors.textMutedDark : WealthColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
