part of '../dashboard_screen.dart';

class _TopMetricsCarousel extends StatelessWidget {
  const _TopMetricsCarousel({required this.data, required this.isDark});
  final DashboardState data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: _NetWorthCard(
        total: data.totalValueInBaseCurrency,
        summaries: data.currencySummaries,
        isDark: isDark,
      ),
    );
  }
}

class _DashboardActionChip extends StatelessWidget {
  const _DashboardActionChip({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? WealthColors.cardDark : const Color(0xFFF0F1F5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({
    required this.total,
    required this.summaries,
    required this.isDark,
  });
  final Money total;
  final List<CurrencySummary> summaries;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 128,
      decoration: BoxDecoration(
        gradient: isDark
            ? WealthColors.heroGradient
            : WealthColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: WealthColors.primary.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              // Column 1: Net Worth
            Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NET WORTH',
                              style: GoogleFonts.sora(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _InfoButton(
                            onTap: () => _showNetWorthInfo(context),
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MoneyText(
                        money: total,
                        useCompact: true,
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Base: ${total.currency}',
                        style: GoogleFonts.sora(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Vertical Divider
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 30),
                color: Colors.white.withValues(alpha: 0.1),
              ),

              // Column 2: By Currency
              Expanded(
                flex: 3,
                child: summaries.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'BY CURRENCY',
                              style: GoogleFonts.sora(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: summaries.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, idx) {
                                  final s = summaries[idx];
                                  return _CurrencyRowCompact(summary: s);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyRowCompact extends StatelessWidget {
  const _CurrencyRowCompact({required this.summary});
  final CurrencySummary summary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCurrencyInfo(context, summary),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                summary.currency,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: Colors.white38,
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: MoneyText(
              money: summary.totalInNative,
              style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
