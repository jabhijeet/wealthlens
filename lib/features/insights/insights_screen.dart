import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../services/insights/insights_service.dart';
import '../../models/insights.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/theme.dart';
import '../../widgets/llm_status_box.dart';
import '../../llm/llm_provider.dart';
import '../../services/logging/error_handler.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    return ref.refresh(portfolioInsightsProvider.future);
  }

  void _showAnalysisSheet(String analysis) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: WealthColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        color: WealthColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Detailed Analysis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: analysis),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    analysis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'warning':
        return WealthColors.accent;
      case 'risk':
        return WealthColors.error;
      case 'opportunity':
        return WealthColors.success;
      case 'allocation':
        return WealthColors.primary;
      case 'performance':
        return WealthColors.crypto;
      default:
        return WealthColors.other;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'warning':
        return Icons.warning_rounded;
      case 'risk':
        return Icons.shield_rounded;
      case 'opportunity':
        return Icons.trending_up_rounded;
      case 'allocation':
        return Icons.pie_chart_rounded;
      case 'performance':
        return Icons.assessment_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Analysis failed: ${error.contains("401") ? "Authentication error (check API keys)" : error}',
        ),
        backgroundColor: WealthColors.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'SETTINGS',
          textColor: Colors.white,
          onPressed: () {
            context.push('/settings/llm-providers');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = ref.watch(activeLlmProvider);
    final isConfigured = provider != null && provider.isConfigured;
    final insightsAsync = ref.watch(portfolioInsightsProvider);
    final analysisState = ref.watch(detailedAnalysisProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInsights,
        color: WealthColors.primary,
        child: insightsAsync.when(
          loading: () => const WealthLoadingIndicator(
            message: 'Analyzing portfolio data...',
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (insights) {
            final counts = <String, int>{};
            for (final i in insights) {
              counts[i.category] = (counts[i.category] ?? 0) + 1;
            }

            final filteredInsights = _selectedCategory == 'all'
                ? insights
                : insights
                      .where((i) => i.category == _selectedCategory)
                      .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Insights',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const LlmStatusBox(),
                              if (isConfigured) ...[
                                if (analysisState.isGenerating) ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ] else if (analysisState.error != null) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.error_outline_rounded,
                                      color: WealthColors.error,
                                    ),
                                    onPressed: () => _showErrorSnackBar(
                                      analysisState.error!,
                                    ),
                                    tooltip: 'Analysis Error',
                                  ),
                                ] else if (analysisState
                                    .analysis
                                    .isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: WealthColors.primary,
                                    ),
                                    onPressed: () => _showAnalysisSheet(
                                      analysisState.analysis,
                                    ),
                                    tooltip: 'Deep Analysis',
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (!isConfigured)
                  SliverFillRemaining(
                    child: _buildErrorStateWidget(
                      ConfigurationException(
                        'LLM API key not configured. Please add it in Settings -> LLM Providers.',
                        code: 'MISSING_API_KEY',
                      ),
                    ),
                  )
                else ...[
                  // ── Analysis Ready / Error Badge ──
                  if (!analysisState.isGenerating &&
                      (analysisState.analysis.isNotEmpty ||
                          analysisState.error != null))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child:
                            GestureDetector(
                                  onTap: analysisState.error != null
                                      ? () => _showErrorSnackBar(
                                          analysisState.error!,
                                        )
                                      : () => _showAnalysisSheet(
                                          analysisState.analysis,
                                        ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: analysisState.error != null
                                            ? [
                                                WealthColors.error,
                                                WealthColors.error.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ]
                                            : [
                                                WealthColors.primary,
                                                WealthColors.primary.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (analysisState.error != null
                                                      ? WealthColors.error
                                                      : WealthColors.primary)
                                                  .withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          analysisState.error != null
                                              ? Icons.warning_amber_rounded
                                              : Icons.stars_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                analysisState.error != null
                                                    ? 'Deep Analysis Failed ⛔'
                                                    : 'Deep Analysis Ready ✨',
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                analysisState.error != null
                                                    ? 'Tap to see what went wrong.'
                                                    : 'Tap to view your personalized portfolio deep-dive.',
                                                style: GoogleFonts.sora(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .shimmer(duration: 2.seconds)
                                .scale(
                                  begin: const Offset(0.95, 0.95),
                                  end: const Offset(1, 1),
                                  curve: Curves.easeOutBack,
                                ),
                      ),
                    ),

                  // ── Category Chips ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _CategoryChip(
                              label: 'All',
                              icon: Icons.all_inclusive_rounded,
                              isSelected: _selectedCategory == 'all',
                              color: WealthColors.primary,
                              onTap: () =>
                                  setState(() => _selectedCategory = 'all'),
                            ),
                            ...counts.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _CategoryChip(
                                  label:
                                      '${entry.key.capitalize()} (${entry.value})',
                                  icon: _getCategoryIcon(entry.key),
                                  isSelected: _selectedCategory == entry.key,
                                  color: _getCategoryColor(entry.key),
                                  onTap: () => setState(
                                    () => _selectedCategory = entry.key,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (insights.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: WealthColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.insights_rounded,
                                size: 48,
                                color: WealthColors.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No insights available',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final insight = filteredInsights[index];
                          return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _InsightCard(
                                  insight: insight,
                                  color: _getCategoryColor(insight.category),
                                  icon: _getCategoryIcon(insight.category),
                                  isDark: isDark,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: (50 * index).ms)
                              .slideY(begin: 0.1, end: 0);
                        }, childCount: filteredInsights.length),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorStateWidget(Object err) {
    final error = err.toString();
    final lowercaseError = error.toLowerCase();

    final isConfigError =
        err is ConfigurationException ||
        lowercaseError.contains('not configured') ||
        lowercaseError.contains('missing_api_key') ||
        lowercaseError.contains('api key');

    final isAuthError =
        lowercaseError.contains('401') ||
        lowercaseError.contains('invalid') ||
        lowercaseError.contains('api key');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    (isConfigError || isAuthError
                            ? Colors.orange
                            : WealthColors.error)
                        .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConfigError || isAuthError
                    ? Icons.key_off_rounded
                    : Icons.error_outline_rounded,
                size: 48,
                color: isConfigError || isAuthError
                    ? Colors.orange
                    : WealthColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isConfigError ? 'API Key Required' : 'Analysis Error',
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                color: WealthColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (isConfigError || isAuthError) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/settings/llm-providers'),
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Go to Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _loadInsights,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.insight,
    required this.color,
    required this.icon,
    required this.isDark,
  });
  final PortfolioInsight insight;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent bar
          Container(
            width: 3,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icon, color: color, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          insight.title,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? WealthColors.textLight
                                : WealthColors.textDark,
                          ),
                        ),
                      ),
                      if (insight.confidence > 0.7)
                        Icon(
                          Icons.verified_rounded,
                          color: WealthColors.success,
                          size: 14,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    insight.description,
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      color: isDark
                          ? WealthColors.textLight
                          : WealthColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  if (insight.metadata != null &&
                      insight.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      insight.metadata!.entries
                          .map(
                            (MapEntry<String, dynamic> e) =>
                                '${e.key}: ${e.value}',
                          )
                          .join(', '),
                      style: GoogleFonts.sora(
                        fontSize: 9,
                        color: WealthColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatTimeAgo(insight.generatedAt),
                        style: GoogleFonts.sora(
                          fontSize: 9,
                          color: WealthColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          insight.category.capitalize(),
                          style: GoogleFonts.sora(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
