part of '../dashboard_screen.dart';

class _TopMoversSection extends StatelessWidget {
  const _TopMoversSection({required this.movers, required this.isDark});
  final List<TopMover> movers;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Movers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize:
                  (Theme.of(context).textTheme.titleMedium?.fontSize ?? 18) *
                  0.9,
            ),
          ),
          const SizedBox(height: 14),
          ...movers.map((m) => _TopMoverRow(mover: m)),
        ],
      ),
    );
  }
}

class _TopMoverRow extends StatelessWidget {
  const _TopMoverRow({required this.mover});
  final TopMover mover;

  @override
  Widget build(BuildContext context) {
    final isGain = mover.changePercent >= 0;
    final color = isGain ? WealthColors.success : WealthColors.error;
    final sign = isGain ? '+' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mover.symbol ?? mover.instrumentName,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (mover.symbol != null)
                  Text(
                    mover.instrumentName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WealthColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(
                money: mover.currentPrice,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$sign${mover.changePercent.toStringAsFixed(2)}%',
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
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
