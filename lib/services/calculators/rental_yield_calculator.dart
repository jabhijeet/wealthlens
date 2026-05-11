import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

class RentalYieldResult {
  RentalYieldResult({
    required this.grossYieldPct,
    required this.netYieldPct,
    required this.capRatePct,
  });
  final Decimal grossYieldPct;
  final Decimal netYieldPct;
  final Decimal capRatePct;
}

class RentalYieldCalculator {
  /// Calculate rental yield metrics.
  /// [annualRent] total annual rent income in minor units.
  /// [currentValuation] property current market value in minor units.
  /// [annualExpenses] total annual expenses (property tax, maintenance, insurance, etc.) in minor units.
  /// [vacancyDays] number of days property is vacant per year.
  /// Returns gross yield, net yield, and cap rate as percentages.
  static RentalYieldResult calculate({
    required int annualRent,
    required int currentValuation,
    required int annualExpenses,
    required int vacancyDays,
  }) {
    if (currentValuation == 0) {
      return RentalYieldResult(
        grossYieldPct: Decimal.zero,
        netYieldPct: Decimal.zero,
        capRatePct: Decimal.zero,
      );
    }

    final valuation = Rational.fromInt(currentValuation);
    final rent = Rational.fromInt(annualRent);
    final expenses = Rational.fromInt(annualExpenses);

    // Adjust rent for vacancy
    final effectiveRent =
        rent *
        (Rational.fromInt(365) - Rational.fromInt(vacancyDays)) /
        Rational.fromInt(365);

    // Gross yield = annual rent / valuation
    final grossYieldRational =
        effectiveRent / valuation * Rational.fromInt(100);

    // Net yield = (annual rent - expenses) / valuation
    final netYieldRational =
        (effectiveRent - expenses) / valuation * Rational.fromInt(100);

    // Cap rate = net operating income / valuation (NOI = effective rent - expenses)
    final capRateRational =
        (effectiveRent - expenses) / valuation * Rational.fromInt(100);

    return RentalYieldResult(
      grossYieldPct: Decimal.parse(grossYieldRational.toDouble().toString()),
      netYieldPct: Decimal.parse(netYieldRational.toDouble().toString()),
      capRatePct: Decimal.parse(capRateRational.toDouble().toString()),
    );
  }

  /// Calculate occupancy rate.
  /// [occupiedDays] number of days property is occupied in a year.
  static Decimal occupancyRate(int occupiedDays) {
    final rational =
        Rational.fromInt(occupiedDays) /
        Rational.fromInt(365) *
        Rational.fromInt(100);
    // Convert Rational to Decimal
    return Decimal.parse(rational.toDouble().toString());
  }
}
