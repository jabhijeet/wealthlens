import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

class LoanAmortizationResult {
  LoanAmortizationResult({
    required this.outstandingPrincipal,
    required this.totalInterestPaid,
    required this.totalPrincipalPaid,
  });
  final Decimal outstandingPrincipal;
  final Decimal totalInterestPaid;
  final Decimal totalPrincipalPaid;
}

class LoanAmortizationCalculator {
  /// Calculate loan amortization as of a given date.
  /// [principal] loan amount in minor units.
  /// [annualRatePct] annual interest rate as decimal (e.g., 8.5 for 8.5%).
  /// [emi] Equated Monthly Installment in minor units.
  /// [startDate] loan disbursement date.
  /// [asOf] date to calculate outstanding balance.
  /// Returns outstanding principal, total interest paid, total principal paid.
  static LoanAmortizationResult calculate({
    required int principal,
    required Decimal annualRatePct,
    required int emi,
    required DateTime startDate,
    required DateTime asOf,
  }) {
    if (asOf.isBefore(startDate)) {
      return LoanAmortizationResult(
        outstandingPrincipal: Decimal.fromInt(principal),
        totalInterestPaid: Decimal.zero,
        totalPrincipalPaid: Decimal.zero,
      );
    }

    var outstanding = Rational.fromInt(principal);
    var totalInterest = Rational.zero;
    var totalPrincipal = Rational.zero;
    final monthlyRate =
        Rational.parse(annualRatePct.toString()) /
        Rational.fromInt(1200); // annual rate / 12 / 100

    var currentDate = startDate;
    while (currentDate.isBefore(asOf) && outstanding > Rational.zero) {
      // Calculate interest for the month
      final interest = outstanding * monthlyRate;
      totalInterest += interest;

      // Principal component of EMI
      final principalComponent = Rational.fromInt(emi) - interest;
      if (principalComponent > outstanding) {
        // Last installment
        totalPrincipal += outstanding;
        outstanding = Rational.zero;
      } else {
        outstanding -= principalComponent;
        totalPrincipal += principalComponent;
      }

      // Move to next month
      currentDate = DateTime(
        currentDate.year,
        currentDate.month + 1,
        currentDate.day,
      );
    }

    return LoanAmortizationResult(
      outstandingPrincipal: Decimal.parse(outstanding.toDouble().toString()),
      totalInterestPaid: Decimal.parse(totalInterest.toDouble().toString()),
      totalPrincipalPaid: Decimal.parse(totalPrincipal.toDouble().toString()),
    );
  }

  /// Calculate EMI given principal, annual rate, and loan term in months.
  static int calculateEmi({
    required int principal,
    required Decimal annualRatePct,
    required int termMonths,
  }) {
    if (annualRatePct == Decimal.zero) {
      // Zero interest loan: EMI = principal / termMonths
      return (principal / termMonths).ceil();
    }

    final monthlyRate =
        Rational.parse(annualRatePct.toString()) / Rational.fromInt(1200);
    final ratePow = (Rational.one + monthlyRate).pow(termMonths);
    final emiRational =
        Rational.fromInt(principal) *
        monthlyRate *
        ratePow /
        (ratePow - Rational.one);
    return Decimal.parse(emiRational.toDouble().toString()).toBigInt().toInt();
  }
}
