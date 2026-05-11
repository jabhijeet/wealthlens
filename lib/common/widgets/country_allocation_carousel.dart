import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:decimal/decimal.dart';
import '../../providers/country_allocation_provider.dart';
import '../../providers/providers.dart';
import '../../data/db/database.dart';
import '../../domain/money.dart';
import '../../core/theme.dart';
import 'money_text.dart';

class CountryAllocationCarousel extends ConsumerWidget {
  const CountryAllocationCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryAllocationAsync = ref.watch(countryAllocationProvider);
    final baseCurrency = ref.watch(selectedCurrencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return countryAllocationAsync.when(
      data: (allocation) {
        if (allocation.isEmpty) return const SizedBox.shrink();

        final total = allocation.values.fold<double>(0, (sum, val) => sum + val);
        final sortedEntries = allocation.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'By Country',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: sortedEntries.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  final country = entry.key;
                  final value = entry.value;
                  final pct = total > 0 ? (value / total) * 100 : 0.0;
                  final color = _getCountryColor(country);

                  return Container(
                    width: 160,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatCountryName(country),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Allocated',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: WealthColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: MoneyText(
                            money: Money.fromDecimal(Decimal.parse(value.toString()), baseCurrency),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => SizedBox(height: 120, child: Center(child: Text('Error: $e'))),
    );
  }

  String _formatCountryName(Country country) {
    switch (country) {
      case Country.usa: return 'USA';
      case Country.uk: return 'UK';
      case Country.india: return 'India';
      case Country.singapore: return 'Singapore';
      case Country.other: return 'Other';
    }
  }

  Color _getCountryColor(Country country) {
    switch (country) {
      case Country.india: return const Color(0xFFFF9933);
      case Country.usa: return const Color(0xFF3C3B6E);
      case Country.singapore: return const Color(0xFFED2939);
      case Country.uk: return const Color(0xFF012169);
      default: return WealthColors.primary;
    }
  }
}
