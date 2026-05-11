import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/money.dart';
import '../../providers/providers.dart';
import 'package:drift/drift.dart' show Value;
import '../../data/db/database.dart';
import '../../data/db/daos.dart';
import '../../core/theme.dart';
import './models/enriched_holding.dart';
import './providers/holdings_market_data_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/money_text.dart';
import '../../widgets/llm_status_box.dart';
import '../../widgets/skeleton_loaders.dart';
import 'widgets/add_transaction_dialog.dart';

class HoldingsScreen extends ConsumerStatefulWidget {
  const HoldingsScreen({super.key});

  @override
  ConsumerState<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends ConsumerState<HoldingsScreen> {
  String _searchQuery = '';
  AssetClass? _filterAssetClass;
  String? _filterCountry;
  String? _filterCurrency;

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  Future<void> _onRefresh() async {
    ref.invalidate(holdingsMarketDataProvider);
    await ref.read(holdingsMarketDataProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final holdingsAsync = ref.watch(holdingsMarketDataProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: WealthColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
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
                          'Holdings',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Row(children: [LlmStatusBox()]),
                    ],
                  ),
                ),
              ),
            ),

            // ── Search Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search holdings...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            // ── Asset Class Filters ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      FilterChip(
                        label: const Text('All Assets'),
                        selected: _filterAssetClass == null,
                        onSelected: (_) =>
                            setState(() => _filterAssetClass = null),
                        showCheckmark: false,
                        labelStyle: GoogleFonts.sora(
                          fontSize: 11,
                          fontWeight: _filterAssetClass == null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _filterAssetClass == null
                              ? Colors.white
                              : null,
                        ),
                        selectedColor: WealthColors.primary,
                        backgroundColor: isDark
                            ? WealthColors.cardDark
                            : Colors.grey[100],
                      ),
                      const SizedBox(width: 8),
                      ...AssetClass.values.map((ac) {
                        final isSelected = _filterAssetClass == ac;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_capitalize(_formatName(ac))),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _filterAssetClass = ac),
                            showCheckmark: false,
                            labelStyle: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? Colors.white : null,
                            ),
                            selectedColor: _getColor(ac),
                            backgroundColor: isDark
                                ? WealthColors.cardDark
                                : Colors.grey[100],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // ── Country and Currency Filters ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? WealthColors.cardDark
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? WealthColors.borderDark
                                : WealthColors.borderLight,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _filterCountry,
                            hint: Text(
                              'All Countries',
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            items: [
                              DropdownMenuItem<String?>(
                                child: Text(
                                  'All Countries',
                                  style: GoogleFonts.sora(fontSize: 12),
                                ),
                              ),
                              // Generate unique countries from holdings
                              ...holdingsAsync
                                  .maybeWhen(
                                    data: (holdings) =>
                                        holdings
                                            .map(
                                              (h) => h.instrument.country.name,
                                            )
                                            .toSet()
                                            .toList()
                                          ..sort(),
                                    orElse: () => <String>[],
                                  )
                                  .map(
                                    (c) => DropdownMenuItem<String?>(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: GoogleFonts.sora(fontSize: 12),
                                      ),
                                    ),
                                  ),
                            ],
                            onChanged: (val) =>
                                setState(() => _filterCountry = val),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? WealthColors.cardDark
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? WealthColors.borderDark
                                : WealthColors.borderLight,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _filterCurrency,
                            hint: Text(
                              'All Currencies',
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            items: [
                              DropdownMenuItem<String?>(
                                child: Text(
                                  'All Currencies',
                                  style: GoogleFonts.sora(fontSize: 12),
                                ),
                              ),
                              // Generate unique currencies from holdings
                              ...holdingsAsync
                                  .maybeWhen(
                                    data: (holdings) =>
                                        holdings
                                            .map((h) => h.instrument.currency)
                                            .toSet()
                                            .toList()
                                          ..sort(),
                                    orElse: () => <String>[],
                                  )
                                  .map(
                                    (c) => DropdownMenuItem<String?>(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: GoogleFonts.sora(fontSize: 12),
                                      ),
                                    ),
                                  ),
                            ],
                            onChanged: (val) =>
                                setState(() => _filterCurrency = val),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ──
            holdingsAsync.when(
              data: (holdings) {
                // Apply filters
                var filtered = holdings.where((h) {
                  if (_searchQuery.isNotEmpty) {
                    final name = h.instrument.name.toLowerCase();
                    final symbol = (h.instrument.symbol ?? '').toLowerCase();
                    if (!name.contains(_searchQuery) &&
                        !symbol.contains(_searchQuery)) {
                      return false;
                    }
                  }
                  if (_filterAssetClass != null &&
                      h.instrument.assetClass != _filterAssetClass) {
                    return false;
                  }
                  if (_filterCountry != null &&
                      h.instrument.country.name != _filterCountry) {
                    return false;
                  }
                  if (_filterCurrency != null &&
                      h.instrument.currency != _filterCurrency) {
                    return false;
                  }
                  return true;
                }).toList();

                if (holdings.isEmpty) {
                  return const SliverFillRemaining(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: UnifiedEmptyPortfolioState(),
                    ),
                  );
                }

                // Group by asset class
                final grouped = <AssetClass, List<EnrichedHolding>>{};
                for (final item in filtered) {
                  grouped
                      .putIfAbsent(item.instrument.assetClass, () => [])
                      .add(item);
                }
                final sortedClasses = grouped.keys.toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Build alternating headers + items
                        var currentIndex = 0;
                        for (final ac in sortedClasses) {
                          // Header
                          if (index == currentIndex) {
                            return Padding(
                              padding: EdgeInsets.only(
                                top: currentIndex == 0 ? 0 : 16,
                                bottom: 8,
                              ),
                              child: _SectionHeader(
                                assetClass: ac,
                                count: grouped[ac]!.length,
                                totalInBase: grouped[ac]!.fold<Money>(
                                  Money(
                                    minor: 0,
                                    currency: ref.watch(
                                      selectedCurrencyProvider,
                                    ),
                                  ),
                                  (sum, item) => sum + item.valueInBase,
                                ),
                              ),
                            );
                          }
                          currentIndex++;

                          // Items
                          for (final item in grouped[ac]!) {
                            if (index == currentIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Dismissible(
                                  key: Key(item.holding.id),
                                  background: _buildSwipeBackground(
                                    color: WealthColors.primary,
                                    icon: Icons.add_circle_outline_rounded,
                                    alignment: Alignment.centerLeft,
                                  ),
                                  secondaryBackground: _buildSwipeBackground(
                                    color: Colors.red,
                                    icon: Icons.delete_outline_rounded,
                                    alignment: Alignment.centerRight,
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction ==
                                        DismissDirection.startToEnd) {
                                      await HapticFeedback.selectionClick();
                                      if (!context.mounted) return false;
                                      final result = await showDialog<bool>(
                                        context: context,
                                        builder: (context) =>
                                            AddTransactionDialog(
                                              holdingId: item.holding.id,
                                              currency:
                                                  item.instrument.currency,
                                            ),
                                      );
                                      if (result == true) {
                                        ref.invalidate(
                                          holdingsMarketDataProvider,
                                        );
                                      }
                                      return false;
                                    } else {
                                      return await _confirmDelete(
                                        context,
                                        ref,
                                        item,
                                      );
                                    }
                                  },
                                  child:
                                      _HoldingCard(item: item, isDark: isDark)
                                          .animate()
                                          .fadeIn(delay: (50 * index).ms)
                                          .slideX(begin: 0.02, end: 0),
                                ),
                              );
                            }
                            currentIndex++;
                          }
                        }
                        return null;
                      },
                      childCount: sortedClasses.fold<int>(
                        0,
                        (sum, ac) => sum + 1 + grouped[ac]!.length,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SliverSkeletonHoldings(),
              error: (Object error, StackTrace stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      child: Icon(icon, color: color),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EnrichedHolding item,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.instrument.name}?'),
        content: const Text('Move to trash? You can restore it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final dao = ref.read(holdingDaoProvider);
              await dao.updateHolding(
                item.holding.id,
                HoldingsCompanion(isActive: Value(false)),
              );
              ref.invalidate(holdingsMarketDataProvider);
              if (context.mounted) Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WealthColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.assetClass,
    required this.count,
    required this.totalInBase,
  });
  final AssetClass assetClass;
  final int count;
  final Money totalInBase;

  @override
  Widget build(BuildContext context) {
    final color = _getColor(assetClass);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatName(assetClass),
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: WealthColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total (Base)',
                style: GoogleFonts.sora(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: WealthColors.textMuted.withValues(alpha: 0.6),
                ),
              ),
              MoneyText(
                money: totalInBase,
                useCompact: true,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: WealthColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({required this.item, required this.isDark});
  final EnrichedHolding item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final instrument = item.instrument;

    return InkWell(
      onTap: () => context.push('/holdings/${item.holding.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
          borderRadius: BorderRadius.circular(12),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: WealthColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      instrument.symbol?.substring(0, 1).toUpperCase() ??
                          instrument.name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: WealthColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instrument.name,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            '${item.holding.quantity} units',
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: WealthColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: WealthColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          MoneyText(
                            money: item.bookValue,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: WealthColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Native (${instrument.currency})',
                      style: GoogleFonts.sora(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: WealthColors.textMuted,
                      ),
                    ),
                    MoneyText(
                      money: item.valueInNative,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Base Value',
                      style: GoogleFonts.sora(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: WealthColors.textMuted,
                      ),
                    ),
                    MoneyText(
                      money: item.valueInBase,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: WealthColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Unified empty state is now used instead of local _EmptyState

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _getColor(AssetClass ac) {
  switch (ac) {
    case AssetClass.equity:
      return WealthColors.equity;
    case AssetClass.fixedDeposit:
      return WealthColors.fixedDeposit;
    case AssetClass.ppf:
      return WealthColors.ppf;
    case AssetClass.insuranceTerm:
      return WealthColors.insurance;
    case AssetClass.realEstateLand:
      return WealthColors.realEstate;
    case AssetClass.cryptoSpot:
      return WealthColors.crypto;
    case AssetClass.commodity:
      return WealthColors.gold;
    case AssetClass.cash:
      return WealthColors.cash;
    default:
      return WealthColors.other;
  }
}

String _formatName(AssetClass ac) {
  switch (ac) {
    case AssetClass.equity:
      return 'EQUITIES';
    case AssetClass.fixedDeposit:
      return 'FIXED DEPOSITS';
    case AssetClass.ppf:
      return 'PPF';
    case AssetClass.insuranceTerm:
      return 'INSURANCE';
    case AssetClass.realEstateLand:
      return 'REAL ESTATE';
    case AssetClass.cryptoSpot:
      return 'CRYPTO';
    case AssetClass.commodity:
      return 'COMMODITIES';
    case AssetClass.cash:
      return 'CASH';
    default:
      return ac.name.toUpperCase();
  }
}
