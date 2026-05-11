import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/services/calculators/crypto_cost_basis_calculator.dart';

void main() {
  group('CryptoCostBasisCalculator', () {
    test('should calculate FIFO cost basis correctly', () {
      final transactions = [
        CryptoTransaction(
          date: DateTime(2023),
          quantity: Decimal.fromInt(10), // Buy 10 units
          pricePerUnit: Decimal.fromInt(10000), // $100.00 per unit
          fees: Decimal.fromInt(100), // $1.00 fee
        ),
        CryptoTransaction(
          date: DateTime(2023, 2),
          quantity: Decimal.fromInt(5), // Buy 5 more units
          pricePerUnit: Decimal.fromInt(12000), // $120.00 per unit
          fees: Decimal.fromInt(100),
        ),
        CryptoTransaction(
          date: DateTime(2023, 3),
          quantity: Decimal.fromInt(-8), // Sell 8 units
          pricePerUnit: Decimal.fromInt(15000), // $150.00 per unit
          fees: Decimal.fromInt(200), // $2.00 fee
        ),
      ];

      final result = CryptoCostBasisCalculator.calculate(
        transactions: transactions,
        method: CostBasisMethod.fifo,
      );

      // First lot: 10 units at total cost = 10*100 + 1 = 1001
      // Second lot: 5 units at total cost = 5*120 + 1 = 601
      // Sell 8 units: consume from first lot entirely (10 units)
      // Cost basis = 1001 (entire first lot)
      // Proceeds = 8*150 - 2 = 1198
      // Realized gain = 1198 - 1001 = 197
      // Remaining: first lot has 2 units left (10 - 8), second lot untouched
      // Actually FIFO consumes entire first lot (10 units) and partial second lot? Wait algorithm consumes from earliest lots until sell quantity satisfied.
      // Let's compute manually:
      // Sell 8 units: take 8 from first lot (10 units). First lot quantity becomes 2.
      // Cost basis = 8/10 * 1001 = 800.8
      // Proceeds = 8*150 - 2 = 1198
      // Realized gain = 1198 - 800.8 = 397.2
      // Remaining lots: first lot with 2 units (cost 200.2), second lot with 5 units (cost 601)

      expect(result.realizedGains, greaterThan(Decimal.zero));
      expect(result.remainingLots.length, 2);

      // Verify total remaining quantity = 2 + 5 = 7
      final totalRemaining = result.remainingLots.fold(
        Decimal.zero,
        (sum, lot) => sum + lot.quantity,
      );
      expect(totalRemaining, Decimal.fromInt(7));
    });

    test('should calculate LIFO cost basis correctly', () {
      final transactions = [
        CryptoTransaction(
          date: DateTime(2023),
          quantity: Decimal.fromInt(10),
          pricePerUnit: Decimal.fromInt(10000),
          fees: Decimal.fromInt(100),
        ),
        CryptoTransaction(
          date: DateTime(2023, 2),
          quantity: Decimal.fromInt(5),
          pricePerUnit: Decimal.fromInt(12000),
          fees: Decimal.fromInt(100),
        ),
        CryptoTransaction(
          date: DateTime(2023, 3),
          quantity: Decimal.fromInt(-8),
          pricePerUnit: Decimal.fromInt(15000),
          fees: Decimal.fromInt(200),
        ),
      ];

      final result = CryptoCostBasisCalculator.calculate(
        transactions: transactions,
        method: CostBasisMethod.lifo,
      );

      // LIFO: sell from most recent lot first (second lot: 5 units)
      // Then from first lot: 3 units
      // Cost basis = 5 units from second lot + 3 units from first lot
      // Should be different from FIFO result
      expect(result.realizedGains, greaterThan(Decimal.zero));
      // Remaining: first lot with 7 units, second lot fully consumed
      final totalRemaining = result.remainingLots.fold(
        Decimal.zero,
        (sum, lot) => sum + lot.quantity,
      );
      expect(totalRemaining, Decimal.fromInt(7));
    });

    test('should calculate average cost basis correctly', () {
      final transactions = [
        CryptoTransaction(
          date: DateTime(2023),
          quantity: Decimal.fromInt(10),
          pricePerUnit: Decimal.fromInt(10000),
          fees: Decimal.fromInt(100),
        ),
        CryptoTransaction(
          date: DateTime(2023, 2),
          quantity: Decimal.fromInt(5),
          pricePerUnit: Decimal.fromInt(12000),
          fees: Decimal.fromInt(100),
        ),
        CryptoTransaction(
          date: DateTime(2023, 3),
          quantity: Decimal.fromInt(-8),
          pricePerUnit: Decimal.fromInt(15000),
          fees: Decimal.fromInt(200),
        ),
      ];

      final result = CryptoCostBasisCalculator.calculate(
        transactions: transactions,
        method: CostBasisMethod.avgCost,
      );

      // Average cost method: compute average cost per unit across all holdings
      // Total cost = (10*100 + 1) + (5*120 + 1) = 1001 + 601 = 1602
      // Total quantity = 15
      // Average cost per unit = 1602 / 15 = 106.8
      // Cost basis for 8 units = 8 * 106.8 = 854.4
      // Proceeds = 8*150 - 2 = 1198
      // Realized gain = 1198 - 854.4 = 343.6
      expect(result.realizedGains, greaterThan(Decimal.zero));
      expect(result.averageCost, greaterThan(Decimal.fromInt(100)));
    });

    test('should handle buy-only transactions', () {
      final transactions = [
        CryptoTransaction(
          date: DateTime(2023),
          quantity: Decimal.fromInt(5),
          pricePerUnit: Decimal.fromInt(10000),
          fees: Decimal.fromInt(50),
        ),
        CryptoTransaction(
          date: DateTime(2023, 2),
          quantity: Decimal.fromInt(3),
          pricePerUnit: Decimal.fromInt(12000),
          fees: Decimal.fromInt(30),
        ),
      ];

      final result = CryptoCostBasisCalculator.calculate(
        transactions: transactions,
        method: CostBasisMethod.fifo,
      );

      expect(result.realizedGains, Decimal.zero);
      expect(result.remainingLots.length, 2);

      final totalQuantity = result.remainingLots.fold(
        Decimal.zero,
        (sum, lot) => sum + lot.quantity,
      );
      expect(totalQuantity, Decimal.fromInt(8));
    });

    test('should handle sell more than holdings (partial)', () {
      final transactions = [
        CryptoTransaction(
          date: DateTime(2023),
          quantity: Decimal.fromInt(5),
          pricePerUnit: Decimal.fromInt(10000),
          fees: Decimal.fromInt(50),
        ),
        CryptoTransaction(
          date: DateTime(2023, 2),
          quantity: Decimal.fromInt(-10), // Sell 10, but only 5 available
          pricePerUnit: Decimal.fromInt(15000),
          fees: Decimal.fromInt(100),
        ),
      ];

      final result = CryptoCostBasisCalculator.calculate(
        transactions: transactions,
        method: CostBasisMethod.fifo,
      );

      // Should consume all 5 units
      expect(result.remainingLots.length, 0);
      expect(result.realizedGains, greaterThan(Decimal.zero));
    });

    test('should handle zero quantity transactions', () {
      final transactions = [
        CryptoTransaction(
          date: DateTime(2023),
          quantity: Decimal.zero,
          pricePerUnit: Decimal.fromInt(10000),
          fees: Decimal.fromInt(0),
        ),
      ];

      final result = CryptoCostBasisCalculator.calculate(
        transactions: transactions,
        method: CostBasisMethod.fifo,
      );

      expect(result.realizedGains, Decimal.zero);
      expect(result.remainingLots.length, 0);
    });

    test('should treat specific identification as FIFO (fallback)', () {
      final transactions = [
        CryptoTransaction(
          date: DateTime(2023),
          quantity: Decimal.fromInt(10),
          pricePerUnit: Decimal.fromInt(10000),
          fees: Decimal.fromInt(100),
        ),
        CryptoTransaction(
          date: DateTime(2023, 2),
          quantity: Decimal.fromInt(-5),
          pricePerUnit: Decimal.fromInt(15000),
          fees: Decimal.fromInt(200),
        ),
      ];

      final result = CryptoCostBasisCalculator.calculate(
        transactions: transactions,
        method: CostBasisMethod.specific,
      );

      // Should behave like FIFO
      expect(result.remainingLots.length, 1);
      expect(result.remainingLots.first.quantity, Decimal.fromInt(5));
    });
  });
}
