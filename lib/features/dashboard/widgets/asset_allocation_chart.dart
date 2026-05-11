part of '../dashboard_screen.dart';

class _AssetAllocationSection extends StatefulWidget {
  const _AssetAllocationSection({required this.data, required this.isDark});
  final DashboardState data;
  final bool isDark;

  @override
  State<_AssetAllocationSection> createState() =>
      _AssetAllocationSectionState();
}

class _AssetAllocationSectionState extends State<_AssetAllocationSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getChartColor(int index, int total) {
    if (total == 0) return WealthColors.primary;
    final hue = (index * 360 / total) % 360;
    return HSLColor.fromAHSL(
      1.0,
      hue,
      0.65,
      widget.isDark ? 0.6 : 0.55,
    ).toColor();
  }

  Widget _buildAllocationPage(
    Map<String, double> allocationData,
    double totalValue, {
    bool useAssetColors = false,
  }) {
    if (allocationData.isEmpty) return const SizedBox.shrink();

    final sortedEntries = allocationData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = sortedEntries.asMap().entries.map((e) {
      final index = e.key;
      final entry = e.value;
      final percentage = (entry.value / totalValue) * 100;
      final color = useAssetColors
          ? _getAssetColor(
              AssetClass.values.firstWhere(
                (ac) => _formatAssetName(ac) == entry.key,
                orElse: () => AssetClass.equity,
              ),
            )
          : _getChartColor(index, sortedEntries.length);

      return PieChartSectionData(
        value: entry.value,
        title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 31,
        color: color,
        titleStyle: GoogleFonts.sora(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.5,
      );
    }).toList();

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 135,
            height: 135,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 36,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.sora(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: WealthColors.textMuted,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: MoneyText(
                            money: widget.data.totalValueInBaseCurrency,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: widget.isDark
                                  ? Colors.white
                                  : WealthColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: sortedEntries.take(5).toList().asMap().entries.map((e) {
                final index = e.key;
                final entry = e.value;
                final percentage = (entry.value / totalValue) * 100;
                final color = useAssetColors
                    ? _getAssetColor(
                        AssetClass.values.firstWhere(
                          (ac) => _formatAssetName(ac) == entry.key,
                          orElse: () => AssetClass.equity,
                        ),
                      )
                    : _getChartColor(index, sortedEntries.length);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.key,
                              style: GoogleFonts.sora(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: widget.isDark
                                    ? Colors.white70
                                    : WealthColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.sora(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: WealthColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Asset Allocation';
      case 1:
        return 'Country Allocation';
      case 2:
        return 'Currency Allocation';
      default:
        return 'Allocation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = widget.data.totalValueInBaseCurrency.decimal.toDouble();
    if (totalValue == 0) return const SizedBox.shrink();

    final assetMap = widget.data.assetAllocation.map(
      (k, v) => MapEntry(_formatAssetName(k), v),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? WealthColors.cardDark : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        gradient: widget.isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  WealthColors.cardDark,
                  WealthColors.cardDarkElevated.withValues(alpha: 0.8),
                ],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: widget.isDark
              ? WealthColors.borderDark
              : WealthColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                    _getPageTitle(_currentPage),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  )
                  .animate(key: ValueKey(_currentPage))
                  .fadeIn()
                  .slideX(begin: -0.1, end: 0),
              Row(
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    height: 4,
                    width: _currentPage == index ? 10 : 4,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? WealthColors.primary
                          : WealthColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildAllocationPage(
                  assetMap,
                  totalValue,
                  useAssetColors: true,
                ),
                _buildAllocationPage(widget.data.countryAllocation, totalValue),
                _buildAllocationPage(
                  widget.data.currencyAllocation,
                  totalValue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetBreakdownList extends StatelessWidget {
  const _AssetBreakdownList({required this.data});
  final DashboardState data;

  @override
  Widget build(BuildContext context) {
    final sortedAssets = data.assetAllocation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalValue = data.totalValueInBaseCurrency.decimal.toDouble();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final entry = sortedAssets[index];
        final pct = totalValue > 0 ? (entry.value / totalValue) : 0.0;
        final color = _getAssetColor(entry.key);

        return Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? WealthColors.borderDark
                  : WealthColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatAssetName(entry.key),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        _InfoButton(
                          onTap: () => _showAssetClassInfo(context, entry.key),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    money: Money.fromDecimal(
                      Decimal.parse(entry.value.toString()),
                      data.baseCurrency,
                    ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.03, end: 0);
      }, childCount: sortedAssets.length),
    );
  }
}

class _EmptyPortfolioState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const UnifiedEmptyPortfolioState();
  }
}
