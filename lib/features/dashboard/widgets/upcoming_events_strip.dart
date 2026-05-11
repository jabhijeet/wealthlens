part of '../dashboard_screen.dart';

class _UpcomingEventsStrip extends StatelessWidget {
  const _UpcomingEventsStrip({required this.events});
  final List<UpcomingEvent> events;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Upcoming',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            separatorBuilder: (context, i) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _UpcomingEventCard(event: events[i], isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({required this.event, required this.isDark});
  final UpcomingEvent event;
  final bool isDark;

  IconData get _icon => switch (event.type) {
    UpcomingEventType.sipDue => Icons.repeat_rounded,
    UpcomingEventType.swpDue => Icons.repeat_on_rounded,
    UpcomingEventType.fdMaturity => Icons.account_balance_rounded,
    UpcomingEventType.insurancePremium => Icons.shield_outlined,
    UpcomingEventType.ppfDeposit => Icons.savings_outlined,
  };

  Color get _color => switch (event.type) {
    UpcomingEventType.sipDue => WealthColors.primary,
    UpcomingEventType.swpDue => WealthColors.accentDark,
    UpcomingEventType.fdMaturity => WealthColors.fixedDeposit,
    UpcomingEventType.insurancePremium => WealthColors.insurance,
    UpcomingEventType.ppfDeposit => WealthColors.ppf,
  };

  @override
  Widget build(BuildContext context) {
    final days = event.daysUntil;
    final daysLabel = days == 0
        ? 'Today'
        : days == 1
        ? 'Tomorrow'
        : 'In $days days';

    return Container(
      width: 126,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_icon, size: 16, color: _color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.label,
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (event.amount != null)
            MoneyText(
              money: event.amount!,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(
            daysLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: days <= 3 ? WealthColors.error : WealthColors.textMuted,
              fontWeight: days <= 3 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
