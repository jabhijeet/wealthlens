import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../data/db/database.dart';
import '../../domain/money.dart';
import '../../data/db/daos.dart';

import 'models/dashboard_state.dart';

import '../../providers/providers.dart';

final optimizedDashboardDataProvider = FutureProvider<DashboardState>((
  ref,
) async {
  return _calculateDashboardData(ref);
});

Future<DashboardState> _calculateDashboardData(Ref ref) async {
  final holdingsWithInstruments = await ref.watch<Future<List<HoldingWithInstrument>>>(
    holdingsWithInstrumentsProvider.future,
  );
  final fxService = ref.watch(fxServiceProvider);
  final baseCurrency = ref.watch(selectedCurrencyProvider);

  if (holdingsWithInstruments.isEmpty) {
    final upcomingEvents = await _computeUpcomingEvents(ref, baseCurrency);
    return DashboardState(
      currencySummaries: [],
      totalValueInBaseCurrency: Money(minor: 0, currency: baseCurrency),
      assetAllocation: {},
      countryAllocation: {},
      currencyAllocation: {},
      baseCurrency: baseCurrency,
      upcomingEvents: upcomingEvents,
    );
  }

  final groupedByCurrency = _groupByCurrency(holdingsWithInstruments);

  // Batch-fetch all price snapshots in one query instead of N+1
  final priceDao = ref.read(priceSnapshotDaoProvider);
  final allInstrumentIds = holdingsWithInstruments.map((h) => h.instrument.id).toList();
  final priceMap = await priceDao.getLatestBatch(allInstrumentIds);
  final twoSnapshotMap = await priceDao.getTwoLatestBatch(allInstrumentIds);

  final currencySummaries = <CurrencySummary>[];
  final assetAllocation = <AssetClass, double>{};
  final countryAllocation = <String, double>{};
  final currencyAllocation = <String, double>{};
  var grandTotalMinor = 0;

  final rateCache = <String, Decimal>{};

  Future<Decimal> getCachedRate(String from, String to) async {
    if (from == to) return Decimal.one;
    final key = '$from:$to';
    if (rateCache.containsKey(key)) return rateCache[key]!;
    final rate = await fxService.getRate(from, to);
    rateCache[key] = rate;
    return rate;
  }

  for (final entry in groupedByCurrency.entries) {
    final currency = entry.key;
    final holdings = entry.value;

    final nativeTotal = _calculateNativeTotalFromCache(holdings, priceMap);
    final nativeMoney = Money(minor: nativeTotal, currency: currency);

    final rate = await getCachedRate(currency, baseCurrency);
    final baseAmount = nativeMoney.decimal * rate;
    final baseMoney = Money.fromDecimal(baseAmount, baseCurrency);

    currencySummaries.add(
      CurrencySummary(
        currency: currency,
        totalInNative: nativeMoney,
        totalInBase: baseMoney,
        fxRateToBase: rate,
      ),
    );

    final baseValueDouble = baseMoney.decimal.toDouble();
    currencyAllocation[currency] = (currencyAllocation[currency] ?? 0) + baseValueDouble;

    grandTotalMinor += baseMoney.minor;

    _updateAssetAllocationFromCache(assetAllocation, holdings, priceMap, rate);
    
    // Update country allocation
    for (final holding in holdings) {
      final country = holding.instrument.country.name;
      final nativeTotal = _calculateNativeTotalFromCache([holding], priceMap);
      final baseHoldingValue = Money(minor: nativeTotal, currency: currency).decimal * rate;
      countryAllocation[country] = (countryAllocation[country] ?? 0) + baseHoldingValue.toDouble();
    }
  }

  final topMovers = await _computeTopMoversFromCache(
    holdingsWithInstruments,
    baseCurrency,
    twoSnapshotMap,
  );
  final upcomingEvents = await _computeUpcomingEvents(ref, baseCurrency);
  final insightTeaser = await _loadInsightTeaser(ref);

  var hasFxError = false;
  for (final summary in currencySummaries) {
    if (summary.currency != baseCurrency && summary.fxRateToBase == Decimal.one) {
      hasFxError = true;
      break;
    }
  }

  return DashboardState(
    currencySummaries: currencySummaries,
    totalValueInBaseCurrency: Money(minor: grandTotalMinor, currency: baseCurrency),
    assetAllocation: assetAllocation,
    countryAllocation: countryAllocation,
    currencyAllocation: currencyAllocation,
    baseCurrency: baseCurrency,
    topMovers: topMovers,
    upcomingEvents: upcomingEvents,
    insightTeaser: insightTeaser,
    hasFxError: hasFxError,
  );
}

Map<String, List<HoldingWithInstrument>> _groupByCurrency(
  List<HoldingWithInstrument> holdings,
) {
  final result = <String, List<HoldingWithInstrument>>{};
  for (final holding in holdings) {
    result.putIfAbsent(holding.instrument.currency, () => []).add(holding);
  }
  return result;
}

// Synchronous - uses pre-fetched price cache
int _calculateNativeTotalFromCache(
  List<HoldingWithInstrument> holdings,
  Map<String, PriceSnapshot> priceMap,
) {
  var totalMinor = 0;
  for (final h in holdings) {
    final priceMinor = priceMap[h.instrument.id]?.closeMinor ?? h.holding.avgCostMinor;
    final quantity = Decimal.parse(h.holding.quantity);
    totalMinor += (quantity * Decimal.fromInt(priceMinor)).toBigInt().toInt();
  }
  return totalMinor;
}

// Synchronous - uses pre-fetched price cache
void _updateAssetAllocationFromCache(
  Map<AssetClass, double> assetAllocation,
  List<HoldingWithInstrument> holdings,
  Map<String, PriceSnapshot> priceMap,
  Decimal rate,
) {
  for (final h in holdings) {
    final priceMinor = priceMap[h.instrument.id]?.closeMinor ?? h.holding.avgCostMinor;
    final quantity = Decimal.parse(h.holding.quantity);
    final valueNativeMinor = quantity * Decimal.fromInt(priceMinor);
    final valueBase = (valueNativeMinor * rate) / Decimal.fromInt(100);
    final assetClass = h.instrument.assetClass;
    assetAllocation[assetClass] =
        (assetAllocation[assetClass] ?? 0.0) + valueBase.toDouble();
  }
}

// Uses pre-fetched two-snapshot cache; no async needed
Future<List<TopMover>> _computeTopMoversFromCache(
  List<HoldingWithInstrument> holdings,
  String baseCurrency,
  Map<String, List<PriceSnapshot>> twoSnapshotMap,
) async {
  final movers = <TopMover>[];
  const skipClasses = {
    AssetClass.fixedDeposit,
    AssetClass.recurringDeposit,
    AssetClass.ppf,
    AssetClass.cash,
    AssetClass.realEstateResidentialSelfUse,
    AssetClass.realEstateResidentialRented,
    AssetClass.realEstateCommercialRented,
    AssetClass.realEstateCommercialVacant,
    AssetClass.realEstateLand,
  };

  for (final h in holdings) {
    if (skipClasses.contains(h.instrument.assetClass)) continue;

    final snapshots = twoSnapshotMap[h.instrument.id] ?? [];
    if (snapshots.length < 2) continue;

    final current = snapshots[0].closeMinor;
    final previous = snapshots[1].closeMinor;
    if (previous == 0) continue;

    final changePct = ((current - previous) / previous) * 100.0;
    if (changePct.abs() < 0.01) continue;

    movers.add(TopMover(
      instrumentName: h.instrument.name,
      symbol: h.instrument.symbol,
      currentPrice: Money(minor: current, currency: h.instrument.currency),
      changePercent: changePct,
    ));
  }

  movers.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));
  return movers.take(5).toList();
}

Future<List<UpcomingEvent>> _computeUpcomingEvents(
  Ref ref,
  String baseCurrency,
) async {
  final events = <UpcomingEvent>[];
  final now = DateTime.now();
  final horizon = now.add(const Duration(days: 30));

  // SIP / SWP
  final planDao = ref.read(systematicPlanDaoProvider);
  final activePlans = await planDao.getActivePlans();
  for (final plan in activePlans) {
    final next = _nextPlanDate(plan, now);
    if (next != null && next.isBefore(horizon)) {
      final kind = plan.kind == 'swp'
          ? UpcomingEventType.swpDue
          : UpcomingEventType.sipDue;
      events.add(
        UpcomingEvent(
          type: kind,
          label: plan.kind.toUpperCase(),
          dueDate: next,
          amount: Money(minor: plan.amountMinor, currency: baseCurrency),
          holdingId: plan.holdingId,
        ),
      );
    }
  }

  // FD / RD maturities
  final fdDao = ref.read(fdRdAccountDaoProvider);
  final fds = await fdDao.getAll();
  for (final fd in fds) {
    if (fd.maturityDate.isAfter(now) && fd.maturityDate.isBefore(horizon)) {
      events.add(
        UpcomingEvent(
          type: UpcomingEventType.fdMaturity,
          label: 'FD Maturity',
          dueDate: fd.maturityDate,
          amount: Money(minor: fd.principalMinor, currency: baseCurrency),
          holdingId: fd.holdingId,
        ),
      );
    }
  }

  // Insurance premium due
  final insDao = ref.read(insurancePolicyDaoProvider);
  final policies = await insDao.getAll();
  for (final policy in policies) {
    final nextPremium = _nextPremiumDate(policy, now);
    if (nextPremium != null && nextPremium.isBefore(horizon)) {
      events.add(
        UpcomingEvent(
          type: UpcomingEventType.insurancePremium,
          label: '${policy.insurer} Premium',
          dueDate: nextPremium,
          amount: Money(minor: policy.premiumMinor, currency: baseCurrency),
          holdingId: policy.holdingId,
        ),
      );
    }
  }

  events.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return events.take(5).toList();
}

DateTime? _nextPlanDate(SystematicPlan plan, DateTime now) {
  if (plan.endDate != null && plan.endDate!.isBefore(now)) return null;
  final day = plan.dayOfMonth ?? 1;
  var candidate = DateTime(now.year, now.month, day.clamp(1, 28));
  if (candidate.isBefore(now)) {
    candidate = DateTime(now.year, now.month + 1, day.clamp(1, 28));
  }
  return candidate;
}

DateTime? _nextPremiumDate(InsurancePolicy policy, DateTime now) {
  final freq = policy.premiumFrequency;
  final start = policy.startDate;
  final months = switch (freq) {
    'monthly' => 1,
    'quarterly' => 3,
    'half-yearly' => 6,
    'yearly' => 12,
    _ => 12,
  };
  var next = start;
  while (next.isBefore(now)) {
    next = DateTime(next.year, next.month + months, next.day);
  }
  return next;
}

Future<String?> _loadInsightTeaser(Ref ref) async {
  final settingDao = ref.read(settingDaoProvider);
  return settingDao.getValue('last_insight_teaser');
}
