import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../../data/db/daos.dart';
import '../../../domain/money.dart';
import '../models/enriched_holding.dart';
import '../../../providers/providers.dart';

final holdingsMarketDataProvider = FutureProvider<List<EnrichedHolding>>((ref) async {
  final holdingsWithInstruments = await ref.watch(holdingsWithInstrumentsProvider.future);
  final fxService = ref.watch(fxServiceProvider);
  final baseCurrency = ref.watch(selectedCurrencyProvider);
  final priceDao = ref.read(priceSnapshotDaoProvider);

  if (holdingsWithInstruments.isEmpty) return [];

  final allInstrumentIds = holdingsWithInstruments.map((h) => h.instrument.id).toList();
  final priceMap = await priceDao.getLatestBatch(allInstrumentIds);

  final enrichedHoldings = <EnrichedHolding>[];
  final rateCache = <String, Decimal>{};

  Future<Decimal> getCachedRate(String from, String to) async {
    if (from == to) return Decimal.one;
    final key = '$from:$to';
    if (rateCache.containsKey(key)) return rateCache[key]!;
    final rate = await fxService.getRate(from, to);
    rateCache[key] = rate;
    return rate;
  }

  for (final h in holdingsWithInstruments) {
    final instrument = h.instrument;
    final holding = h.holding;
    
    // Calculate latest price
    final snapshot = priceMap[instrument.id];
    final latestPrice = snapshot != null 
        ? Money(minor: snapshot.closeMinor, currency: snapshot.currency)
        : null;
    
    // Effective price for valuation (fallback to avg cost if no market price)
    final effectivePriceMinor = snapshot?.closeMinor ?? holding.avgCostMinor;
    final quantity = Decimal.parse(holding.quantity);
    
    final valueInNative = Money(
      minor: (quantity * Decimal.fromInt(effectivePriceMinor)).toBigInt().toInt(),
      currency: instrument.currency,
    );

    final rate = await getCachedRate(instrument.currency, baseCurrency);
    final valueInBase = Money.fromDecimal(valueInNative.decimal * rate, baseCurrency);

    enrichedHoldings.add(EnrichedHolding(
      holdingWithInstrument: h,
      valueInNative: valueInNative,
      valueInBase: valueInBase,
      latestPrice: latestPrice,
    ));
  }

  return enrichedHoldings;
});
