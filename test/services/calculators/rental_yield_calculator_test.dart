import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/services/calculators/rental_yield_calculator.dart';

void main() {
  group('RentalYieldCalculator', () {
    test('should calculate rental yields correctly', () {
      const annualRent = 2400000; // ₹24,000.00 annual rent
      const currentValuation = 50000000; // ₹500,000.00 property value
      const annualExpenses = 600000; // ₹6,000.00 annual expenses
      const vacancyDays = 30; // 30 days vacant per year

      final result = RentalYieldCalculator.calculate(
        annualRent: annualRent,
        currentValuation: currentValuation,
        annualExpenses: annualExpenses,
        vacancyDays: vacancyDays,
      );

      // Effective rent = 24000 * (365-30)/365 = 24000 * 0.9178 ≈ ₹22,027.40
      // Gross yield = 22027.40 / 500000 = 4.405% ≈ 4.41%
      expect(result.grossYieldPct.toDouble(), closeTo(4.405, 0.01));

      // Net yield = (22027.40 - 6000) / 500000 = 16027.40 / 500000 = 3.205% ≈ 3.21%
      expect(result.netYieldPct.toDouble(), closeTo(3.205, 0.01));

      // Cap rate should equal net yield
      expect(result.capRatePct, result.netYieldPct);
    });

    test('should handle zero vacancy', () {
      const annualRent = 2400000;
      const currentValuation = 50000000;
      const annualExpenses = 600000;
      const vacancyDays = 0;

      final result = RentalYieldCalculator.calculate(
        annualRent: annualRent,
        currentValuation: currentValuation,
        annualExpenses: annualExpenses,
        vacancyDays: vacancyDays,
      );

      // Gross yield = 24000 / 500000 = 4.8%
      expect(result.grossYieldPct.toDouble(), closeTo(4.8, 0.01));

      // Net yield = (24000 - 6000) / 500000 = 18000 / 500000 = 3.6%
      expect(result.netYieldPct.toDouble(), closeTo(3.6, 0.01));
    });

    test('should handle full vacancy', () {
      const annualRent = 2400000;
      const currentValuation = 50000000;
      const annualExpenses = 600000;
      const vacancyDays = 365;

      final result = RentalYieldCalculator.calculate(
        annualRent: annualRent,
        currentValuation: currentValuation,
        annualExpenses: annualExpenses,
        vacancyDays: vacancyDays,
      );

      // Effective rent = 0
      // Gross yield = 0%
      expect(result.grossYieldPct, Decimal.zero);

      // Net yield = (0 - 6000) / 500000 = -1.2%
      expect(result.netYieldPct.toDouble(), closeTo(-1.2, 0.01));
    });

    test('should return zero yields for zero valuation', () {
      final result = RentalYieldCalculator.calculate(
        annualRent: 2400000,
        currentValuation: 0,
        annualExpenses: 600000,
        vacancyDays: 30,
      );

      expect(result.grossYieldPct, Decimal.zero);
      expect(result.netYieldPct, Decimal.zero);
      expect(result.capRatePct, Decimal.zero);
    });

    test('should calculate occupancy rate', () {
      final rate = RentalYieldCalculator.occupancyRate(
        300,
      ); // 300 occupied days

      // 300/365 = 0.8219 = 82.19%
      expect(rate.toDouble(), closeTo(82.19, 0.01));
    });

    test('should handle edge cases for occupancy rate', () {
      expect(RentalYieldCalculator.occupancyRate(0), Decimal.zero);
      expect(RentalYieldCalculator.occupancyRate(365), Decimal.fromInt(100));
      expect(
        RentalYieldCalculator.occupancyRate(400),
        greaterThan(Decimal.fromInt(100)),
      ); // >100% possible if input error
    });

    test('should handle negative net yield when expenses exceed rent', () {
      const annualRent = 1000000; // ₹10,000.00
      const currentValuation = 50000000; // ₹500,000.00
      const annualExpenses = 2000000; // ₹20,000.00 (expenses > rent)
      const vacancyDays = 0;

      final result = RentalYieldCalculator.calculate(
        annualRent: annualRent,
        currentValuation: currentValuation,
        annualExpenses: annualExpenses,
        vacancyDays: vacancyDays,
      );

      // Net yield = (10000 - 20000) / 500000 = -10000 / 500000 = -2%
      expect(result.netYieldPct.toDouble(), closeTo(-2.0, 0.01));
    });
  });
}
