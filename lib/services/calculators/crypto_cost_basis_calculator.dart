import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

/// Helper to convert Rational (result of division) to Decimal
Decimal _rationalToDecimal(dynamic rational) {
  if (rational is Decimal) return rational;
  if (rational is Rational) {
    // Convert Rational to Decimal with scale of 10 decimal places
    return rational.toDecimal(scaleOnInfinitePrecision: 10);
  }
  // Convert via string representation as fallback
  return Decimal.parse(rational.toString());
}

enum CostBasisMethod { fifo, lifo, avgCost, specific }

class CryptoTransaction {
  CryptoTransaction({
    required this.date,
    required this.quantity,
    required this.pricePerUnit,
    required this.fees,
  });
  final DateTime date;
  final Decimal quantity; // positive for buy, negative for sell
  final Decimal pricePerUnit; // in minor units per unit
  final Decimal fees;
}

class Lot {
  Lot({
    required this.acquisitionDate,
    required this.quantity,
    required this.costPerUnit,
    required this.totalCost,
  });
  final DateTime acquisitionDate;
  Decimal quantity;
  final Decimal costPerUnit; // including fees allocated
  Decimal totalCost;
}

class CryptoCostBasisCalculator {
  /// Calculate cost basis and realized gains using specified method.
  /// [transactions] list of buy/sell transactions sorted by date.
  /// [method] cost basis method (FIFO, LIFO, AvgCost, Specific).
  /// Returns remaining lots, realized gains, and average cost.
  static ({List<Lot> remainingLots, Decimal realizedGains, Decimal averageCost})
  calculate({
    required List<CryptoTransaction> transactions,
    required CostBasisMethod method,
  }) {
    switch (method) {
      case CostBasisMethod.fifo:
        return _calculateFifo(transactions);
      case CostBasisMethod.lifo:
        return _calculateLifo(transactions);
      case CostBasisMethod.avgCost:
        return _calculateAvgCost(transactions);
      case CostBasisMethod.specific:
        // Specific identification not implemented; treat as FIFO
        return _calculateFifo(transactions);
    }
  }

  static ({List<Lot> remainingLots, Decimal realizedGains, Decimal averageCost})
  _calculateFifo(List<CryptoTransaction> transactions) {
    final lots = <Lot>[];
    var realizedGains = Decimal.zero;

    for (final tx in transactions) {
      if (tx.quantity > Decimal.zero) {
        // Buy: create a new lot
        final totalCost = tx.quantity * tx.pricePerUnit + tx.fees;
        final costPerUnit = _rationalToDecimal(totalCost / tx.quantity);
        lots.add(
          Lot(
            acquisitionDate: tx.date,
            quantity: tx.quantity,
            costPerUnit: costPerUnit,
            totalCost: totalCost,
          ),
        );
      } else {
        // Sell: consume from earliest lots
        var remainingSell = -tx.quantity;
        final proceeds = -tx.quantity * tx.pricePerUnit - tx.fees;

        var costBasis = Decimal.zero;
        while (remainingSell > Decimal.zero && lots.isNotEmpty) {
          final lot = lots.first;
          if (lot.quantity <= remainingSell) {
            // Consume entire lot
            costBasis += lot.totalCost;
            remainingSell -= lot.quantity;
            lots.removeAt(0);
          } else {
            // Consume partial lot
            final fraction = _rationalToDecimal(remainingSell / lot.quantity);
            final costAllocation = _rationalToDecimal(lot.totalCost * fraction);
            costBasis += costAllocation;
            lot
              ..quantity -= remainingSell
              ..totalCost -= costAllocation;
            remainingSell = Decimal.zero;
          }
        }

        realizedGains += proceeds - costBasis;
      }
    }

    final averageCost = lots.isNotEmpty
        ? _rationalToDecimal(
            lots
                    .map((l) => l.costPerUnit * l.quantity)
                    .reduce((a, b) => a + b) /
                lots.map((l) => l.quantity).reduce((a, b) => a + b),
          )
        : Decimal.zero;

    return (
      remainingLots: lots,
      realizedGains: realizedGains,
      averageCost: averageCost,
    );
  }

  static ({List<Lot> remainingLots, Decimal realizedGains, Decimal averageCost})
  _calculateLifo(List<CryptoTransaction> transactions) {
    final lots = <Lot>[];
    var realizedGains = Decimal.zero;

    for (final tx in transactions) {
      if (tx.quantity > Decimal.zero) {
        // Buy: add to front (so latest is first)
        final totalCost = tx.quantity * tx.pricePerUnit + tx.fees;
        final costPerUnit = _rationalToDecimal(totalCost / tx.quantity);
        lots.insert(
          0,
          Lot(
            acquisitionDate: tx.date,
            quantity: tx.quantity,
            costPerUnit: costPerUnit,
            totalCost: totalCost,
          ),
        );
      } else {
        // Sell: consume from front (latest lots)
        var remainingSell = -tx.quantity;
        final proceeds = -tx.quantity * tx.pricePerUnit - tx.fees;

        var costBasis = Decimal.zero;
        while (remainingSell > Decimal.zero && lots.isNotEmpty) {
          final lot = lots.first;
          if (lot.quantity <= remainingSell) {
            costBasis += lot.totalCost;
            remainingSell -= lot.quantity;
            lots.removeAt(0);
          } else {
            final fraction = _rationalToDecimal(remainingSell / lot.quantity);
            final costAllocation = _rationalToDecimal(lot.totalCost * fraction);
            costBasis += costAllocation;
            lot
              ..quantity -= remainingSell
              ..totalCost -= costAllocation;
            remainingSell = Decimal.zero;
          }
        }

        realizedGains += proceeds - costBasis;
      }
    }

    final averageCost = lots.isNotEmpty
        ? _rationalToDecimal(
            lots
                    .map((l) => l.costPerUnit * l.quantity)
                    .reduce((a, b) => a + b) /
                lots.map((l) => l.quantity).reduce((a, b) => a + b),
          )
        : Decimal.zero;

    return (
      remainingLots: lots,
      realizedGains: realizedGains,
      averageCost: averageCost,
    );
  }

  static ({List<Lot> remainingLots, Decimal realizedGains, Decimal averageCost})
  _calculateAvgCost(List<CryptoTransaction> transactions) {
    var totalQuantity = Decimal.zero;
    var totalCost = Decimal.zero;
    var realizedGains = Decimal.zero;

    for (final tx in transactions) {
      if (tx.quantity > Decimal.zero) {
        // Buy: update average cost
        final buyCost = tx.quantity * tx.pricePerUnit + tx.fees;
        totalCost += buyCost;
        totalQuantity += tx.quantity;
      } else {
        // Sell: use average cost
        final sellQuantity = -tx.quantity;
        final avgCostPerUnit = totalQuantity > Decimal.zero
            ? _rationalToDecimal(totalCost / totalQuantity)
            : Decimal.zero;
        final costBasis = _rationalToDecimal(sellQuantity * avgCostPerUnit);
        final proceeds = sellQuantity * tx.pricePerUnit - tx.fees;

        realizedGains += proceeds - costBasis;
        totalQuantity -= sellQuantity;
        totalCost -= _rationalToDecimal(sellQuantity * avgCostPerUnit);
      }
    }

    final averageCost = totalQuantity > Decimal.zero
        ? _rationalToDecimal(totalCost / totalQuantity)
        : Decimal.zero;
    final remainingLots = totalQuantity > Decimal.zero
        ? [
            Lot(
              acquisitionDate: DateTime.now(),
              quantity: totalQuantity,
              costPerUnit: averageCost,
              totalCost: totalCost,
            ),
          ]
        : <Lot>[];

    return (
      remainingLots: remainingLots,
      realizedGains: realizedGains,
      averageCost: averageCost,
    );
  }
}
