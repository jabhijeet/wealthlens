import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/services/calculators/fd_rd_calculator.dart';

void main() {
  group('FdCalculator', () {
    test('should calculate simple interest payout FD', () {
      const principal =
          1000000; // ₹10,000.00 in minor units (100 paise per rupee)
      final rate = Decimal.fromInt(6); // 6%
      final startDate = DateTime(2023);
      final asOf = DateTime(2024); // exactly 1 year later

      final value = FdCalculator.calculateValue(
        principal: principal,
        annualRatePct: rate,
        startDate: startDate,
        asOf: asOf,
        compoundingFrequency: 'yearly',
        payoutType: 'payout',
      );

      // Simple interest: 10000 * 6% = ₹600 interest
      // Total = ₹10,600.00 = 1060000 minor units
      expect(value, 1060000);
    });

    test('should calculate cumulative compounding FD monthly', () {
      const principal = 1000000; // ₹10,000.00
      final rate = Decimal.fromInt(6);
      final startDate = DateTime(2023);
      final asOf = DateTime(2024); // 1 year

      final value = FdCalculator.calculateValue(
        principal: principal,
        annualRatePct: rate,
        startDate: startDate,
        asOf: asOf,
        compoundingFrequency: 'monthly',
        payoutType: 'cumulative',
      );

      // Monthly compounding: A = P(1 + r/n)^(nt)
      // r = 0.06, n = 12, t = 1
      // A = 10000 * (1 + 0.06/12)^12 ≈ 10616.78 ≈ ₹10,616.78
      // Minor units: 1061678 (approx)
      expect(value, greaterThan(1061600));
      expect(value, lessThan(1061800));
    });

    test('should return principal if asOf before startDate', () {
      const principal = 1000000;
      final rate = Decimal.fromInt(6);
      final startDate = DateTime(2024);
      final asOf = DateTime(2023, 12, 31);

      final value = FdCalculator.calculateValue(
        principal: principal,
        annualRatePct: rate,
        startDate: startDate,
        asOf: asOf,
        compoundingFrequency: 'yearly',
        payoutType: 'cumulative',
      );

      expect(value, principal);
    });

    test('should handle fractional years', () {
      const principal = 1000000;
      final rate = Decimal.fromInt(6);
      final startDate = DateTime(2023);
      final asOf = DateTime(2023, 7); // 0.5 years

      final value = FdCalculator.calculateValue(
        principal: principal,
        annualRatePct: rate,
        startDate: startDate,
        asOf: asOf,
        compoundingFrequency: 'yearly',
        payoutType: 'payout',
      );

      // Simple interest for 181 days (Jan 1 to Jul 1): 10000 * 6% * (181/365) ≈ ₹297.53
      // Total ≈ ₹10,297.53 = 1029753 minor units (rounded down)
      expect(value, 1029753);
    });
  });

  group('RdCalculator', () {
    test('should calculate RD maturity with quarterly compounding', () {
      const installment = 50000; // ₹500.00 monthly
      final rate = Decimal.fromInt(6);
      final startDate = DateTime(2023);
      final asOf = DateTime(2024); // 12 months

      final value = RdCalculator.calculateValue(
        installment: installment,
        annualRatePct: rate,
        startDate: startDate,
        asOf: asOf,
        compoundingFrequency: 'quarterly',
      );

      // RD formula approximation: should be > simple sum of installments (12 * 500 = 6000)
      // With interest, should be around ₹6,180-6,200
      expect(value, greaterThan(600000)); // ₹6,000.00
      expect(value, lessThan(630000)); // ₹6,300.00
    });

    test('should return zero if asOf before startDate', () {
      const installment = 50000;
      final rate = Decimal.fromInt(6);
      final startDate = DateTime(2024);
      final asOf = DateTime(2023, 12, 31);

      final value = RdCalculator.calculateValue(
        installment: installment,
        annualRatePct: rate,
        startDate: startDate,
        asOf: asOf,
        compoundingFrequency: 'quarterly',
      );

      expect(value, 0);
    });

    test('should handle partial months', () {
      const installment = 50000;
      final rate = Decimal.fromInt(6);
      final startDate = DateTime(2023);
      final asOf = DateTime(2023, 3, 15); // 2 full months + partial

      final value = RdCalculator.calculateValue(
        installment: installment,
        annualRatePct: rate,
        startDate: startDate,
        asOf: asOf,
        compoundingFrequency: 'quarterly',
      );

      // Should count only full months (Jan, Feb) = 2 installments
      // With interest for 2 months
      expect(value, greaterThan(100000)); // > ₹1,000.00
      expect(value, lessThan(102000)); // < ₹1,020.00
    });
  });
}
