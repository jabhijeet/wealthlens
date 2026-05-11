import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/services/calculators/loan_amortization_calculator.dart';

void main() {
  group('LoanAmortizationCalculator', () {
    test('should calculate EMI correctly', () {
      final emi = LoanAmortizationCalculator.calculateEmi(
        principal: 1000000, // ₹10,000.00
        annualRatePct: Decimal.fromInt(12), // 12% p.a.
        termMonths: 12,
      );

      // EMI formula: P * r * (1+r)^n / ((1+r)^n - 1)
      // P = 10000, r = 0.01 (monthly), n = 12
      // EMI ≈ ₹888.49 ≈ 88849 minor units
      expect(emi, greaterThan(88000));
      expect(emi, lessThan(90000));
    });

    test('should calculate amortization after some payments', () {
      const principal = 1000000; // ₹10,000.00
      final annualRatePct = Decimal.fromInt(12); // 12%
      const emi = 88849; // Calculated EMI from above
      final startDate = DateTime(2023);
      final asOf = DateTime(2023, 7); // After 6 payments

      final result = LoanAmortizationCalculator.calculate(
        principal: principal,
        annualRatePct: annualRatePct,
        emi: emi,
        startDate: startDate,
        asOf: asOf,
      );

      // After 6 payments, outstanding should be less than initial
      expect(result.outstandingPrincipal, lessThan(Decimal.fromInt(principal)));
      expect(result.totalPrincipalPaid, greaterThan(Decimal.zero));
      expect(result.totalInterestPaid, greaterThan(Decimal.zero));

      // Total paid = principal paid + interest paid
      final totalPaid = result.totalPrincipalPaid + result.totalInterestPaid;
      expect(totalPaid, Decimal.fromInt(emi * 6));
    });

    test('should return full principal if asOf before startDate', () {
      const principal = 1000000;
      final annualRatePct = Decimal.fromInt(12);
      const emi = 88849;
      final startDate = DateTime(2024);
      final asOf = DateTime(2023, 12, 31);

      final result = LoanAmortizationCalculator.calculate(
        principal: principal,
        annualRatePct: annualRatePct,
        emi: emi,
        startDate: startDate,
        asOf: asOf,
      );

      expect(result.outstandingPrincipal, Decimal.fromInt(principal));
      expect(result.totalInterestPaid, Decimal.zero);
      expect(result.totalPrincipalPaid, Decimal.zero);
    });

    test('should handle loan fully paid off', () {
      const principal = 1000000;
      final annualRatePct = Decimal.fromInt(12);
      const emi = 88849;
      final startDate = DateTime(2023);
      final asOf = DateTime(2024, 2); // After 13+ months (more than term)

      final result = LoanAmortizationCalculator.calculate(
        principal: principal,
        annualRatePct: annualRatePct,
        emi: emi,
        startDate: startDate,
        asOf: asOf,
      );

      // Loan should be fully paid off
      expect(result.outstandingPrincipal, Decimal.zero);

      // Total principal paid should equal original principal
      expect(result.totalPrincipalPaid, Decimal.fromInt(principal));
    });

    test('should handle large EMI (payoff in first month)', () {
      const principal = 1000000;
      final annualRatePct = Decimal.fromInt(12);
      const emi = 2000000; // EMI larger than principal + interest
      final startDate = DateTime(2023);
      final asOf = DateTime(2023, 2); // After 1 month

      final result = LoanAmortizationCalculator.calculate(
        principal: principal,
        annualRatePct: annualRatePct,
        emi: emi,
        startDate: startDate,
        asOf: asOf,
      );

      // Loan should be fully paid off in first month
      expect(result.outstandingPrincipal, Decimal.zero);
      expect(result.totalPrincipalPaid, Decimal.fromInt(principal));
    });

    test('should calculate with zero interest rate', () {
      final emi = LoanAmortizationCalculator.calculateEmi(
        principal: 1000000,
        annualRatePct: Decimal.zero,
        termMonths: 10,
      );

      // With zero interest, EMI = principal / term
      // 1000000 / 10 = 100000 minor units (₹1,000.00)
      expect(emi, 100000);

      final result = LoanAmortizationCalculator.calculate(
        principal: 1000000,
        annualRatePct: Decimal.zero,
        emi: emi,
        startDate: DateTime(2023),
        asOf: DateTime(2023, 6), // After 5 payments
      );

      // After 5 payments of ₹1,000 each, outstanding = ₹5,000
      expect(result.outstandingPrincipal, Decimal.fromInt(500000));
      expect(result.totalInterestPaid, Decimal.zero);
      expect(result.totalPrincipalPaid, Decimal.fromInt(500000));
    });
  });
}
