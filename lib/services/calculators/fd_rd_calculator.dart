import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

class FdCalculator {
  /// Calculate the maturity amount of a fixed deposit.
  /// [principal] in minor units.
  /// [annualRatePct] as decimal (e.g., 6.5 for 6.5%).
  /// [startDate] start of deposit.
  /// [asOf] date to calculate value (must be ≤ maturityDate).
  /// [compoundingFrequency] 'monthly', 'quarterly', 'yearly', 'atMaturity'.
  /// [payoutType] 'cumulative' (interest reinvested) or 'payout' (interest paid out).
  static int calculateValue({
    required int principal,
    required Decimal annualRatePct,
    required DateTime startDate,
    required DateTime asOf,
    required String compoundingFrequency,
    required String payoutType,
    DateTime? maturityDate,
  }) {
    if (asOf.isBefore(startDate)) return principal;

    final days = asOf.difference(startDate).inDays;
    final years = days / 365.0; // Use 365 days for financial calculations

    if (payoutType == 'payout') {
      // Simple interest paid out periodically
      final interestRational =
          Rational.fromInt(principal) *
          Rational.parse(annualRatePct.toString()) *
          Rational.fromInt(days) /
          Rational.fromInt(365 * 100);
      final interest = Decimal.parse(
        interestRational.toDouble().toString(),
      ).toBigInt().toInt();
      return principal + interest;
    }

    // Cumulative compounding
    final n = _compoundingPeriodsPerYear(compoundingFrequency);
    final rateRational =
        Rational.parse(annualRatePct.toString()) / Rational.fromInt(100);
    final nt = (n * years).toInt();
    final amountRational =
        Rational.fromInt(principal) *
        (Rational.one + rateRational / Rational.fromInt(n)).pow(nt);
    return Decimal.parse(
      amountRational.toDouble().toString(),
    ).toBigInt().toInt();
  }

  static int _compoundingPeriodsPerYear(String frequency) {
    switch (frequency) {
      case 'monthly':
        return 12;
      case 'quarterly':
        return 4;
      case 'yearly':
        return 1;
      case 'atMaturity':
        return 1;
      default:
        return 1;
    }
  }
}

class RdCalculator {
  /// Calculate the maturity amount of a recurring deposit.
  /// [installment] monthly installment in minor units.
  /// [annualRatePct] as decimal.
  /// [startDate] first installment date.
  /// [asOf] date to calculate value.
  /// [compoundingFrequency] 'quarterly' (standard for RD) or 'monthly'.
  static int calculateValue({
    required int installment,
    required Decimal annualRatePct,
    required DateTime startDate,
    required DateTime asOf,
    required String compoundingFrequency,
  }) {
    if (asOf.isBefore(startDate)) return 0;

    final months = _monthsBetween(startDate, asOf);

    final rateRational =
        Rational.parse(annualRatePct.toString()) / Rational.fromInt(100);
    var totalRational = Rational.zero;

    for (var i = 1; i <= months; i++) {
      final monthsRemaining = months - i + 1;
      final interestRational =
          Rational.fromInt(installment) *
          rateRational *
          Rational.fromInt(monthsRemaining) /
          Rational.fromInt(12);
      totalRational += Rational.fromInt(installment) + interestRational;
    }

    return Decimal.parse(
      totalRational.toDouble().toString(),
    ).toBigInt().toInt();
  }

  static int _monthsBetween(DateTime start, DateTime end) {
    final years = end.year - start.year;
    final months = end.month - start.month;
    return years * 12 + months + (end.day >= start.day ? 0 : -1);
  }
}
