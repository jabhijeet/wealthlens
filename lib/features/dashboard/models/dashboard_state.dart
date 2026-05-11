import 'package:decimal/decimal.dart';
import '../../../data/db/database.dart';
import '../../../domain/money.dart';

class DashboardState {
  DashboardState({
    required this.currencySummaries,
    required this.totalValueInBaseCurrency,
    required this.assetAllocation,
    required this.countryAllocation,
    required this.currencyAllocation,
    required this.baseCurrency,
    this.topMovers = const [],
    this.upcomingEvents = const [],
    this.insightTeaser,
    this.hasFxError = false,
  });
  final List<CurrencySummary> currencySummaries;
  final Money totalValueInBaseCurrency;
  final Map<AssetClass, double> assetAllocation;
  final Map<String, double> countryAllocation;
  final Map<String, double> currencyAllocation;
  final String baseCurrency;
  final List<TopMover> topMovers;
  final List<UpcomingEvent> upcomingEvents;
  final String? insightTeaser;
  final bool hasFxError;
}

class CurrencySummary {
  CurrencySummary({
    required this.currency,
    required this.totalInNative,
    required this.totalInBase,
    this.fxRateToBase,
  });
  final String currency;
  final Money totalInNative;
  final Money totalInBase;
  final Decimal? fxRateToBase;
}

class TopMover {
  TopMover({
    required this.instrumentName,
    required this.symbol,
    required this.currentPrice,
    required this.changePercent,
  });
  final String instrumentName;
  final String? symbol;
  final Money currentPrice;
  final double changePercent; // positive = gain, negative = loss
}

enum UpcomingEventType {
  sipDue,
  swpDue,
  fdMaturity,
  insurancePremium,
  ppfDeposit,
}

class UpcomingEvent {
  UpcomingEvent({
    required this.type,
    required this.label,
    required this.dueDate,
    this.amount,
    this.holdingId,
  });
  final UpcomingEventType type;
  final String label;
  final DateTime dueDate;
  final Money? amount;
  final String? holdingId;

  int get daysUntil => dueDate.difference(DateTime.now()).inDays;
}
