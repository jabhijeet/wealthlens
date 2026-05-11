import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:decimal/decimal.dart';
import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../core/theme.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../dashboard/dashboard_provider.dart';
import '../../services/fx/fx_service.dart';

final allFxRatesProvider = FutureProvider<List<FxRate>>((ref) async {
  final dao = ref.watch(fxRateDaoProvider);
  return dao.getAllLatest();
});

class FxRatesScreen extends ConsumerWidget {
  const FxRatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(allFxRatesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FX Rates',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              final rates = await ref.read(allFxRatesProvider.future);
              final fxService = ref.read<FxService>(fxServiceProvider);
              for (final r in rates) {
                await fxService.forceFetch(r.base, r.quote);
              }
              ref
                ..invalidate(allFxRatesProvider)
                ..invalidate(optimizedDashboardDataProvider);
            },
          ),
        ],
      ),
      body: ratesAsync.when(
        data: (rates) => rates.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: rates.length,
                itemBuilder: (context, index) {
                  final rate = rates[index];
                  return _FxRateCard(rate: rate, isDark: isDark);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRateDialog(context, ref),
        label: const Text('Add Rate'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: WealthColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.currency_exchange_rounded,
            size: 64,
            color: WealthColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No FX rates found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Rates are automatically fetched when needed\nor you can add them manually.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: WealthColors.textMuted),
          ),
        ],
      ),
    );
  }

  void _showAddRateDialog(BuildContext context, WidgetRef ref) {
    final baseController = TextEditingController();
    final quoteController = TextEditingController();
    final rateController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add FX Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: baseController,
              decoration: const InputDecoration(
                labelText: 'Base Currency (e.g. USD)',
                hintText: 'USD',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quoteController,
              decoration: const InputDecoration(
                labelText: 'Quote Currency (e.g. INR)',
                hintText: 'INR',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateController,
              decoration: const InputDecoration(
                labelText: 'Rate',
                hintText: '1.0',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (baseController.text.isEmpty ||
                  quoteController.text.isEmpty ||
                  rateController.text.isEmpty) {
                return;
              }

              final rate = Decimal.tryParse(rateController.text);
              if (rate == null) {
                return;
              }

              final dao = ref.read(fxRateDaoProvider);
              await dao.insertOrUpdate(
                FxRatesCompanion(
                  base: drift.Value(baseController.text.toUpperCase()),
                  quote: drift.Value(quoteController.text.toUpperCase()),
                  rate: drift.Value(rate.toString()),
                  date: drift.Value(DateTime.now()),
                  source: const drift.Value('manual'),
                ),
              );

              ref
                ..invalidate(allFxRatesProvider)
                ..invalidate(optimizedDashboardDataProvider);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _FxRateCard extends ConsumerWidget {
  const _FxRateCard({required this.rate, required this.isDark});
  final FxRate rate;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(rate.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: WealthColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: WealthColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rate.base} / ${rate.quote}',
                  style: GoogleFonts.sora(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      rate.source,
                      style: GoogleFonts.sora(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: WealthColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                    if (rate.source == 'manual') ...[
                      const SizedBox(width: 4),
                      FutureBuilder<FxRate?>(
                        future: ref
                            .read(fxRateDaoProvider)
                            .getLatestNonManual(rate.base, rate.quote),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Market: ${snapshot.data!.rate} (${snapshot.data!.source})',
                                style: GoogleFonts.sora(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      '•  $dateStr',
                      style: GoogleFonts.sora(
                        color: WealthColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rate.rate,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: WealthColors.primary,
                ),
              ),
              Text(
                '1 ${rate.base} = ${rate.rate} ${rate.quote}',
                style: GoogleFonts.sora(
                  fontSize: 9,
                  color: WealthColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showEditRateDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: WealthColors.error,
            onPressed: () => _showDeleteConfirmDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete FX Rate'),
        content: Text(
          'Are you sure you want to delete the rate for ${rate.base}/${rate.quote}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final dao = ref.read(fxRateDaoProvider);
              await dao.deleteRate(rate.base, rate.quote);
              ref
                ..invalidate(allFxRatesProvider)
                ..invalidate(optimizedDashboardDataProvider);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: WealthColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditRateDialog(BuildContext context, WidgetRef ref) {
    final rateController = TextEditingController(text: rate.rate);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Rate: ${rate.base}/${rate.quote}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: rateController,
              decoration: const InputDecoration(labelText: 'Rate'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Current Source: ${rate.source}',
              style: GoogleFonts.sora(
                fontSize: 11,
                color: WealthColors.textMuted,
              ),
            ),
            Text(
              'Saving will change source to "manual"',
              style: GoogleFonts.sora(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: WealthColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newRate = Decimal.tryParse(rateController.text);
              if (newRate == null) {
                return;
              }

              final dao = ref.read(fxRateDaoProvider);
              await dao.insertOrUpdate(
                FxRatesCompanion(
                  base: drift.Value(rate.base),
                  quote: drift.Value(rate.quote),
                  rate: drift.Value(newRate.toString()),
                  date: drift.Value(DateTime.now()),
                  source: const drift.Value('manual'),
                ),
              );

              ref
                ..invalidate(allFxRatesProvider)
                ..invalidate(optimizedDashboardDataProvider);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
