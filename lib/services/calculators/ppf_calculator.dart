import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

class PpfCalculator {
  /// Calculate PPF balance as of a given date.
  /// [contributions] list of {date, amountMinor}.
  /// [rateHistory] list of {fromDate, toDate, ratePct}.
  /// [maturityDate] PPF maturity date.
  /// [asOf] date to calculate value.
  static int calculateValue({
    required List<PpfContribution> contributions,
    required List<PpfRatePeriod> rateHistory,
    required DateTime maturityDate,
    required DateTime asOf,
  }) {
    if (asOf.isBefore(contributions.first.date)) return 0;

    // Sort contributions by date
    contributions.sort((a, b) => a.date.compareTo(b.date));
    // Sort rate periods by fromDate
    rateHistory.sort((a, b) => a.fromDate.compareTo(b.fromDate));

    var balance = Rational.zero;
    var lastDate = contributions.first.date;

    for (final contribution in contributions) {
      if (contribution.date.isAfter(asOf)) break;

      // Add contribution
      balance += Rational.fromInt(contribution.amountMinor);

      // Calculate interest from lastDate to contribution.date (or asOf)
      final periodEnd = contribution.date.isBefore(asOf)
          ? contribution.date
          : asOf;
      if (periodEnd.isAfter(lastDate)) {
        final interest = _calculateInterest(
          balance,
          lastDate,
          periodEnd,
          rateHistory,
        );
        balance += interest;
      }

      lastDate = contribution.date;
    }

    // Calculate interest from last contribution to asOf
    if (asOf.isAfter(lastDate)) {
      final interest = _calculateInterest(balance, lastDate, asOf, rateHistory);
      balance += interest;
    }

    // Convert Rational to integer with proper rounding
    // balance = numerator / denominator
    final num = balance.numerator;
    final den = balance.denominator;
    // Round to nearest integer: (num + den~/2) ~/ den for positive numbers
    final two = BigInt.from(2);
    if (num >= BigInt.zero) {
      return ((num + den ~/ two) ~/ den).toInt();
    } else {
      return ((num - den ~/ two) ~/ den).toInt();
    }
  }

  static Rational _calculateInterest(
    Rational principal,
    DateTime from,
    DateTime to,
    List<PpfRatePeriod> rateHistory,
  ) {
    var interest = Rational.zero;
    var current = from;

    for (final period in rateHistory) {
      if (current.isAfter(to)) break;
      if (period.toDate.isBefore(current)) continue;

      final periodStart = current.isAfter(period.fromDate)
          ? current
          : period.fromDate;
      final periodEnd = period.toDate.isBefore(to) ? period.toDate : to;
      if (periodEnd.isBefore(periodStart)) continue;

      final days = periodEnd.difference(periodStart).inDays;
      final rate =
          Rational.parse(period.ratePct.toString()) / Rational.fromInt(100);
      final yearFraction = Rational.fromInt(days) / Rational.fromInt(365);
      interest += principal * rate * yearFraction;
      current = periodEnd;
    }

    return interest;
  }
}

class PpfContribution {
  PpfContribution({required this.date, required this.amountMinor});
  final DateTime date;
  final int amountMinor;
}

class PpfRatePeriod {
  PpfRatePeriod({
    required this.fromDate,
    required this.toDate,
    required this.ratePct,
  });
  final DateTime fromDate;
  final DateTime toDate;
  final Decimal ratePct;
}
