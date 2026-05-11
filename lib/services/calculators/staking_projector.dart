import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

class StakingProjector {
  /// Projected staking yield over a horizon given APR and compounding assumption.
  ///
  /// [principal] in minor units.
  /// [annualRatePct] as decimal (e.g., 5.0 for 5% APR).
  /// [horizonDays] number of days to project.
  /// [compounding] 'simple' or 'compound' (auto-compound).
  /// [compoundFrequency] if compounding, frequency in days (e.g., 1 for daily, 7 for weekly).
  /// Returns projected amount in minor units.
  static int projectYield({
    required int principal,
    required Decimal annualRatePct,
    required int horizonDays,
    required String compounding,
    int compoundFrequency = 1,
  }) {
    if (horizonDays <= 0) return principal;
    if (annualRatePct == Decimal.zero) return principal;

    final principalRational = Rational.fromInt(principal);
    final rateRational =
        Rational.parse(annualRatePct.toString()) / Rational.fromInt(100);

    if (compounding == 'simple') {
      // Simple interest: principal * (1 + rate * days/365)
      final factor =
          Rational.one +
          rateRational * Rational.fromInt(horizonDays) / Rational.fromInt(365);
      final result = principalRational * factor;
      return result.toBigInt().toInt();
    } else {
      // Compound interest with given frequency
      // Convert annual rate to per-period rate
      final periodsPerYear =
          Rational.fromInt(365) / Rational.fromInt(compoundFrequency);
      final periods = horizonDays ~/ compoundFrequency;
      if (periods == 0) {
        // Less than one compounding period, treat as simple for remaining days
        final remainingDays = horizonDays % compoundFrequency;
        final simpleFactor =
            Rational.one +
            rateRational *
                Rational.fromInt(remainingDays) /
                Rational.fromInt(365);
        final result = principalRational * simpleFactor;
        return result.toBigInt().toInt();
      }
      final periodRate = rateRational / periodsPerYear;
      final factor = Rational.one + periodRate;
      // (1 + r)^n
      var compounded = Rational.one;
      for (var i = 0; i < periods; i++) {
        compounded *= factor;
      }
      // Handle remaining days with simple interest
      final remainingDays = horizonDays % compoundFrequency;
      if (remainingDays > 0) {
        final simpleFactor =
            Rational.one +
            rateRational *
                Rational.fromInt(remainingDays) /
                Rational.fromInt(365);
        compounded *= simpleFactor;
      }
      final result = principalRational * compounded;
      return result.toBigInt().toInt();
    }
  }

  /// Calculate the number of days until a target date from a start date.
  static int daysBetween(DateTime start, DateTime target) {
    return target.difference(start).inDays;
  }
}
