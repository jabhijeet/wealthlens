import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:decimal/decimal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/money.dart';
import '../../providers/providers.dart';
import '../../data/db/database.dart';
import 'dashboard_provider.dart';
import '../../common/widgets/money_text.dart';
import '../../core/theme.dart';
import 'models/dashboard_state.dart';
import '../../common/widgets/empty_state.dart';
import '../../widgets/llm_status_box.dart';

part 'widgets/net_worth_hero_card.dart';
part 'widgets/asset_allocation_chart.dart';
part 'widgets/top_movers_list.dart';
part 'widgets/upcoming_events_strip.dart';
part 'widgets/dashboard_helpers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, welcome back';
    if (hour < 17) return 'Good afternoon, welcome back';
    return 'Good evening, welcome back';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(optimizedDashboardDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header (Always visible) ──
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (MediaQuery.of(context).size.width > 600) ...[
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _greeting(),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: WealthColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'WealthLens',
                              style: GoogleFonts.outfit(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const LlmStatusBox(),
                        const SizedBox(width: 8),
                        _DashboardActionChip(
                          icon: Icons.notifications_none_rounded,
                          onTap: () => context.push('/notifications'),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          initialValue: ref.watch(selectedCurrencyProvider),
                          onSelected: (currency) {
                            ref
                                    .read(selectedCurrencyProvider.notifier)
                                    .currency =
                                currency;
                          },
                          offset: const Offset(0, 40),
                          tooltip: 'Change Base Currency',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ref.watch(selectedCurrencyProvider),
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) =>
                              ['INR', 'USD', 'SGD', 'EUR', 'GBP']
                                  .map(
                                    (c) => PopupMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── State-dependent Content ──
          dashboardDataAsync.when(
            data: (data) => _buildSlivers(context, ref, data, isDark),
            loading: () => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: WealthColors.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your portfolio...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: WealthColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Something went wrong',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$error',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlivers(
    BuildContext context,
    WidgetRef ref,
    DashboardState data,
    bool isDark,
  ) {
    return SliverMainAxisGroup(
      slivers: [
        // ── FX Error Warning ──
        if (data.hasFxError)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: WealthColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: WealthColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: WealthColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Market rates unavailable. Using cost-basis or 1:1 fallbacks.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WealthColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Top Metrics Carousel ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _TopMetricsCarousel(data: data, isDark: isDark),
          ),
        ),

        // ── Upcoming Events ──
        if (data.upcomingEvents.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _UpcomingEventsStrip(events: data.upcomingEvents),
            ),
          ),

        // ── Empty State or Asset Allocation ──
        if (data.assetAllocation.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              child: _EmptyPortfolioState(),
            ),
          )
        else ...[
          // ── Asset Allocation ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _AssetAllocationSection(data: data, isDark: isDark),
            ),
          ),

          // ── Top Movers ──
          if (data.topMovers.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _TopMoversSection(
                  movers: data.topMovers,
                  isDark: isDark,
                ),
              ),
            ),

          // ── Asset Class Breakdown ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleMedium?.fontSize ??
                          18) *
                      0.9,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            sliver: _AssetBreakdownList(data: data),
          ),
        ],
      ],
    );
  }
}
