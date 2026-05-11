import 'dart:math';

class XirrCalculator {
  /// Calculate XIRR (Extended Internal Rate of Return) for a series of cash flows.
  /// [cashFlows] list of (date, amount) where amount is positive for inflow,
  /// negative for outflow (from perspective of the investor).
  /// [guess] initial guess for IRR (default 0.1 = 10%).
  /// [maxIterations] maximum Newton-Raphson iterations.
  /// [tolerance] convergence tolerance.
  static double calculate({
    required List<CashFlow> cashFlows,
    double guess = 0.1,
    int maxIterations = 100,
    double tolerance = 1e-6,
  }) {
    if (cashFlows.length < 2) return 0.0;

    // Sort by date
    cashFlows.sort((a, b) => a.date.compareTo(b.date));

    var x = guess;
    for (var i = 0; i < maxIterations; i++) {
      final (value, derivative) = _npvAndDerivative(cashFlows, x);
      if (derivative.abs() < tolerance) break;

      final xNew = x - value / derivative;
      if ((xNew - x).abs() < tolerance) {
        x = xNew;
        break;
      }
      x = xNew;
    }

    return x;
  }

  static (double npv, double derivative) _npvAndDerivative(
    List<CashFlow> cashFlows,
    double rate,
  ) {
    var npv = 0.0;
    var derivative = 0.0;
    final startDate = cashFlows.first.date;

    for (final flow in cashFlows) {
      final years = flow.date.difference(startDate).inDays / 365.25;
      final amount = flow.amount;
      final factor = pow(1 + rate, years);
      npv += amount / factor;

      if (years != 0) {
        derivative -= amount * years / pow(1 + rate, years + 1);
      }
    }

    return (npv, derivative);
  }

  /// Calculate CAGR (Compound Annual Growth Rate) between two values over time.
  /// [startValue] initial value.
  /// [endValue] final value.
  /// [years] time period in years (can be fractional).
  static double calculateCagr({
    required double startValue,
    required double endValue,
    required double years,
  }) {
    if (startValue == 0 || years == 0) return 0.0;
    return pow(endValue / startValue, 1 / years) - 1;
  }
}

class CashFlow {
  CashFlow({required this.date, required this.amount});
  final DateTime date;
  final double amount;
}
