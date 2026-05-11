part of '../dashboard_screen.dart';

Color _getAssetColor(AssetClass ac) {
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
    default:
      return WealthColors.other;
  }
}

String _formatAssetName(AssetClass ac) {
  switch (ac) {
    case AssetClass.equity:
      return 'Equities';
    case AssetClass.fixedDeposit:
      return 'Fixed Deposits';
    case AssetClass.ppf:
      return 'PPF';
    case AssetClass.insuranceTerm:
      return 'Insurance';
    case AssetClass.realEstateLand:
      return 'Real Estate';
    case AssetClass.cryptoSpot:
      return 'Crypto';
    default:
      return ac.name
          .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
          .trim();
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.onTap, this.size = 20, this.color});
  final VoidCallback onTap;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          Icons.info_outline_rounded,
          size: size,
          color: color ?? WealthColors.textMuted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

void _showNetWorthInfo(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _NetWorthInfoSheet(),
  );
}

void _showCurrencyInfo(BuildContext context, CurrencySummary summary) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _CurrencyInfoSheet(summary: summary),
  );
}

void _showAssetClassInfo(BuildContext context, AssetClass assetClass) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _AssetClassInfoSheet(assetClass: assetClass),
  );
}

class _NetWorthInfoSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(optimizedDashboardDataProvider).value;
    if (dashboardData == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WealthColors.textMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Valuation Source',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your net worth is calculated by converting all assets into your base currency (${dashboardData.baseCurrency}) using current FX rates.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WealthColors.textMuted,
                ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Currency Breakdown',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...dashboardData.currencySummaries.map((s) {
            final rate = s.fxRateToBase != null
                ? ' (Rate: ${s.fxRateToBase})'
                : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${s.currency}$rate',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  MoneyText(
                    money: s.totalInBase,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: WealthColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/settings/fx-rates');
              },
              icon: const Icon(Icons.currency_exchange_rounded, size: 18),
              label: const Text('Manage FX Rates'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyInfoSheet extends StatelessWidget {
  const _CurrencyInfoSheet({required this.summary});
  final CurrencySummary summary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WealthColors.textMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Currency: ${summary.currency}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Total Native', value: summary.totalInNative),
          _InfoRow(
            label: 'FX Rate (${summary.totalInBase.currency}/${summary.currency})',
            value: summary.fxRateToBase?.toString() ?? '1.0',
          ),
          _InfoRow(label: 'Total in Base', value: summary.totalInBase),
          const SizedBox(height: 24),
          Text(
            'All investments held in ${summary.currency} are aggregated here. You can view individual holdings in the Holdings screen.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WealthColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _AssetClassInfoSheet extends StatelessWidget {
  const _AssetClassInfoSheet({required this.assetClass});
  final AssetClass assetClass;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WealthColors.textMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _formatAssetName(assetClass),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This asset class represents your investments in ${_formatAssetName(assetClass).toLowerCase()}. Values are converted to your base currency for aggregate reporting.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WealthColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WealthColors.textMuted,
                ),
          ),
          if (value is Money)
            MoneyText(
              money: value as Money,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text(
              value.toString(),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
