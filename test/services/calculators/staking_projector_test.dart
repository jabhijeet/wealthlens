import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/services/calculators/staking_projector.dart';

void main() {
  group('StakingProjector', () {
    test('should calculate simple interest yield', () {
      // 1000 units at 10% APR for 365 days = 1100
      final result = StakingProjector.projectYield(
        principal: 1000,
        annualRatePct: Decimal.fromInt(10),
        horizonDays: 365,
        compounding: 'simple',
      );
      expect(result, 1100); // 1000 * (1 + 0.10) = 1100
    });

    test('should calculate simple interest for partial year', () {
      // 1000 at 10% for 182 days ≈ 1000 * (1 + 0.10 * 182/365) = 1049.86 → truncated to 1049
      final result = StakingProjector.projectYield(
        principal: 1000,
        annualRatePct: Decimal.fromInt(10),
        horizonDays: 182,
        compounding: 'simple',
      );
      expect(result, 1049); // truncated
    });

    test('should calculate compound interest daily', () {
      // 1000 at 10% compounded daily for 365 days
      // formula: principal * (1 + rate/365)^365
      // approximate: 1000 * e^(0.10) ≈ 1105.17
      final result = StakingProjector.projectYield(
        principal: 1000,
        annualRatePct: Decimal.fromInt(10),
        horizonDays: 365,
        compounding: 'compound',
      );
      // Expect slightly more than simple interest (1100)
      expect(result, greaterThan(1100));
      // Rough check: should be around 1105
      expect(result, inInclusiveRange(1104, 1106));
    });

    test('should calculate compound interest weekly', () {
      // 1000 at 10% compounded weekly for 52 weeks (364 days)
      final result = StakingProjector.projectYield(
        principal: 1000,
        annualRatePct: Decimal.fromInt(10),
        horizonDays: 364,
        compounding: 'compound',
        compoundFrequency: 7,
      );
      // Should be less than daily compounding but more than simple
      expect(result, greaterThan(1100));
      expect(result, lessThan(1106));
    });

    test('should return principal for zero rate', () {
      final result = StakingProjector.projectYield(
        principal: 1000,
        annualRatePct: Decimal.zero,
        horizonDays: 365,
        compounding: 'simple',
      );
      expect(result, 1000);
    });

    test('should return principal for zero days', () {
      final result = StakingProjector.projectYield(
        principal: 1000,
        annualRatePct: Decimal.fromInt(10),
        horizonDays: 0,
        compounding: 'simple',
      );
      expect(result, 1000);
    });

    test('should handle large principal and small rate', () {
      final result = StakingProjector.projectYield(
        principal: 1000000,
        annualRatePct: Decimal.parse('0.5'),
        horizonDays: 365,
        compounding: 'simple',
      );
      // 1,000,000 * (1 + 0.005) = 1,005,000
      expect(result, 1005000);
    });

    test('should handle compound with remaining days', () {
      // 1000 at 10% compounded daily for 370 days (5 extra days simple)
      final result = StakingProjector.projectYield(
        principal: 1000,
        annualRatePct: Decimal.fromInt(10),
        horizonDays: 370,
        compounding: 'compound',
      );
      // Should be slightly more than 365 days compounding
      expect(result, greaterThan(1105));
    });

    test('daysBetween should compute correctly', () {
      final start = DateTime(2023);
      final target = DateTime(2023, 1, 11);
      final days = StakingProjector.daysBetween(start, target);
      expect(days, 10);
    });
  });
}
