import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../data/db/database.dart';
import '../data/db/daos.dart';
import 'providers.dart';

final countryAllocationProvider = FutureProvider<Map<Country, double>>((ref) async {
  final holdingsWithInstruments = await ref.watch<Future<List<HoldingWithInstrument>>>(
    holdingsWithInstrumentsProvider.future,
  );
  final fxService = ref.watch(fxServiceProvider);
  final baseCurrency = ref.watch(selectedCurrencyProvider);

  if (holdingsWithInstruments.isEmpty) return {};

  final priceDao = ref.read(priceSnapshotDaoProvider);
  final allInstrumentIds = holdingsWithInstruments.map((h) => h.instrument.id).toList();
  final priceMap = await priceDao.getLatestBatch(allInstrumentIds);

  final countryAllocation = <Country, double>{};
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
    final currency = h.instrument.currency;
    final rate = await getCachedRate(currency, baseCurrency);

    final priceMinor = priceMap[h.instrument.id]?.closeMinor ?? h.holding.avgCostMinor;
    final quantity = Decimal.parse(h.holding.quantity);
    final valueNativeMinor = quantity * Decimal.fromInt(priceMinor);
    final valueBase = (valueNativeMinor * rate) / Decimal.fromInt(100);
    
    final country = h.instrument.country;
    countryAllocation[country] = (countryAllocation[country] ?? 0.0) + valueBase.toDouble();
  }

  return countryAllocation;
});
