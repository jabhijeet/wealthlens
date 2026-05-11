import 'package:decimal/decimal.dart';
import '../../../domain/money.dart';
import '../../../data/db/database.dart';
import 'holding_with_instrument.dart';

class EnrichedHolding {
  EnrichedHolding({
    required this.holdingWithInstrument,
    required this.valueInNative,
    required this.valueInBase,
    this.latestPrice,
  });

  final HoldingWithInstrument holdingWithInstrument;
  final Money valueInNative;
  final Money valueInBase;
  final Money? latestPrice;

  Holding get holding => holdingWithInstrument.holding;
  Instrument get instrument => holdingWithInstrument.instrument;

  Money get bookValue => Money(
        minor: (Decimal.parse(holding.quantity) *
                Decimal.fromInt(holding.avgCostMinor))
            .toBigInt()
            .toInt(),
        currency: instrument.currency,
      );
}
