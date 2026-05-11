import 'dart:async';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import '../../domain/money.dart';
import '../../features/holdings/models/holding_with_instrument.dart';
export 'daos_extra.dart';

part 'daos.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = openDatabase();
  ref.onDispose(db.close);
  return db;
}

class InstrumentDao {
  InstrumentDao(this._db);
  final AppDatabase _db;

  Future<List<Instrument>> getAll() => _db.select(_db.instruments).get();

  Future<Instrument?> getById(String id) => (_db.select(
    _db.instruments,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> insert(Insertable<Instrument> instrument) async {
    final row = await _db.into(_db.instruments).insertReturning(instrument);
    return row.id;
  }

  Future<bool> update(Insertable<Instrument> instrument) async {
    return await _db.update(_db.instruments).replace(instrument);
  }

  Future<void> updateInstrument(
    String id,
    InstrumentsCompanion companion,
  ) async {
    await (_db.update(
      _db.instruments,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  Future<int> delete(String id) =>
      (_db.delete(_db.instruments)..where((t) => t.id.equals(id))).go();

  Future<int> clearAll() => _db.delete(_db.instruments).go();

  Future<Instrument?> getInstrumentBySymbol(String symbol) => (_db.select(
    _db.instruments,
  )..where((t) => t.symbol.equals(symbol))).getSingleOrNull();

  Future<Instrument> getOrCreateInstrument({
    required String symbol,
    required String name,
    required String assetClass,
    required String currency,
    required String country,
    String? exchange,
    String? isin,
  }) async {
    final existing = await getInstrumentBySymbol(symbol);
    if (existing != null) return existing;

    final id = await insert(
      InstrumentsCompanion(
        symbol: Value(symbol),
        name: Value(name),
        assetClass: Value(
          AssetClass.values.firstWhere(
            (e) => e.name == assetClass,
            orElse: () => AssetClass.custom,
          ),
        ),
        currency: Value(currency),
        country: Value(
          Country.values.firstWhere(
            (e) => e.name == country,
            orElse: () => Country.other,
          ),
        ),
        exchange: Value(exchange),
        isin: Value(isin),
      ),
    );

    return (await getById(id))!;
  }
}

class HoldingDao {
  HoldingDao(this._db);
  final AppDatabase _db;

  Future<List<Holding>> getAll() => _db.select(_db.holdings).get();

  Future<List<Holding>> getByInstrumentId(String instrumentId) => (_db.select(
    _db.holdings,
  )..where((t) => t.instrumentId.equals(instrumentId))).get();

  Future<Holding?> getById(String id) => (_db.select(
    _db.holdings,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> insert(Insertable<Holding> holding) async {
    final row = await _db.into(_db.holdings).insertReturning(holding);
    return row.id;
  }

  Future<bool> update(Insertable<Holding> holding) async {
    return await _db.update(_db.holdings).replace(holding);
  }

  Future<int> delete(String id) =>
      (_db.delete(_db.holdings)..where((t) => t.id.equals(id))).go();

  Future<int> clearAll() => _db.delete(_db.holdings).go();

  Future<Instrument?> getInstrument(String instrumentId) async {
    return await (_db.select(
      _db.instruments,
    )..where((t) => t.id.equals(instrumentId))).getSingleOrNull();
  }

  Future<String> createHolding({
    required String instrumentId,
    required double quantity,
    required Money averagePrice,
    required String currency,
    String? accountNumber,
    String? folioNumber,
    DateTime? openedOn,
  }) async {
    return await insert(
      HoldingsCompanion(
        instrumentId: Value(instrumentId),
        quantity: Value(quantity.toString()),
        avgCostMinor: Value(averagePrice.minor),
        openedOn: Value(openedOn ?? DateTime.now()),
        source: const Value(InstrumentSource.importedPdf),
        account: Value(accountNumber ?? folioNumber),
      ),
    );
  }

  Future<void> updateQuantityAndAvgPrice(
    String id,
    double quantity,
    Money avgPrice,
  ) async {
    await (_db.update(_db.holdings)..where((t) => t.id.equals(id))).write(
      HoldingsCompanion(
        quantity: Value(quantity.toString()),
        avgCostMinor: Value(avgPrice.minor),
      ),
    );
  }

  Future<void> updateQuantity(String id, double quantity) async {
    await (_db.update(_db.holdings)..where((t) => t.id.equals(id))).write(
      HoldingsCompanion(quantity: Value(quantity.toString())),
    );
  }

  Future<List<HoldingWithInstrument>> getAllWithInstruments({
    bool activeOnly = true,
  }) async {
    final query = _db.select(_db.holdings).join([
      innerJoin(
        _db.instruments,
        _db.instruments.id.equalsExp(_db.holdings.instrumentId),
      ),
    ]);

    if (activeOnly) {
      query.where(_db.holdings.isActive.equals(true));
    }

    final rows = await query.get();
    return rows.map((row) {
      return HoldingWithInstrument(
        holding: row.readTable(_db.holdings),
        instrument: row.readTable(_db.instruments),
      );
    }).toList();
  }

  Stream<List<HoldingWithInstrument>> watchAllWithInstruments({
    bool activeOnly = true,
  }) {
    final query = _db.select(_db.holdings).join([
      innerJoin(
        _db.instruments,
        _db.instruments.id.equalsExp(_db.holdings.instrumentId),
      ),
    ]);

    if (activeOnly) {
      query.where(_db.holdings.isActive.equals(true));
    }

    return query.watch().map((rows) {
      return rows.map((row) {
        return HoldingWithInstrument(
          holding: row.readTable(_db.holdings),
          instrument: row.readTable(_db.instruments),
        );
      }).toList();
    });
  }

  Future<void> updateHolding(String id, HoldingsCompanion companion) async {
    await (_db.update(
      _db.holdings,
    )..where((t) => t.id.equals(id))).write(companion);
  }
}

class TransactionDao {
  TransactionDao(this._db);
  final AppDatabase _db;

  Future<List<Transaction>> getAll() => _db.select(_db.transactions).get();

  Future<List<Transaction>> getByHoldingId(String holdingId) => (_db.select(
    _db.transactions,
  )..where((t) => t.holdingId.equals(holdingId))).get();

  Future<String> insert(Insertable<Transaction> transaction) async {
    final row = await _db.into(_db.transactions).insertReturning(transaction);
    return row.id;
  }

  Future<bool> update(Insertable<Transaction> transaction) async {
    return await _db.update(_db.transactions).replace(transaction);
  }

  Future<int> delete(String id) =>
      (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();

  Future<int> clearAll() => _db.delete(_db.transactions).go();

  Future<List<Transaction>> getRecent({int limit = 50}) =>
      (_db.select(_db.transactions)
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ])
            ..limit(limit))
          .get();

  Future<String> createTransaction({
    required String? instrumentId,
    required String type,
    double? quantity,
    Money? price,
    required Money amount,
    required String currency,
    required DateTime date,
    Money? fee,
    String? description,
    String? account,
    String? holdingId,
  }) async {
    // If holdingId is not provided, try to find it from instrumentId
    var finalHoldingId = holdingId;
    if (finalHoldingId == null && instrumentId != null) {
      final query = _db.select(_db.holdings)
        ..where((t) => t.instrumentId.equals(instrumentId));
      final holdings = await query.get();
      if (holdings.isNotEmpty) {
        finalHoldingId = holdings.first.id;
      } else {
        // Create a shell holding on the fly
        final row = await _db
            .into(_db.holdings)
            .insertReturning(
              HoldingsCompanion(
                instrumentId: Value(instrumentId),
                quantity: const Value('0'),
                avgCostMinor: const Value(0),
                openedOn: Value(date),
                source: const Value(InstrumentSource.importedPdf),
                account: Value(account),
              ),
            );
        finalHoldingId = row.id;
      }
    }

    if (finalHoldingId == null) {
      throw StateError(
        'Cannot create transaction: holdingId is null and no instrumentId provided to find or create a holding',
      );
    }

    var finalQuantity = quantity ?? 0.0;
    var finalPriceMinor = price?.minor ?? 0;

    // For transactions where amount is provided but quantity/price is 0 (like dividends/fees)
    if (finalQuantity == 0 && amount.minor != 0) {
      finalQuantity = 1.0;
      finalPriceMinor = amount.minor;
    } else if (finalQuantity != 0 && finalPriceMinor == 0 && amount.minor != 0) {
      // If we have quantity and amount but no price, calculate price
      finalPriceMinor = (amount.minor / finalQuantity).round();
    }

    return await insert(
      TransactionsCompanion(
        holdingId: Value(finalHoldingId),
        type: Value(
          TransactionType.values.firstWhere(
            (e) => e.name == type,
            orElse: () => TransactionType.buy,
          ),
        ),
        date: Value(date),
        quantity: Value(finalQuantity.toString()),
        priceMinor: Value(finalPriceMinor),
        feesMinor: Value(fee?.minor ?? 0),
        notes: Value(description),
      ),
    );
  }
}

class PriceSnapshotDao {
  PriceSnapshotDao(this._db);
  final AppDatabase _db;

  Future<PriceSnapshot?> getLatest(String instrumentId) =>
      (_db.select(_db.priceSnapshots)
            ..where((t) => t.instrumentId.equals(instrumentId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ]))
          .getSingleOrNull();

  Future<List<PriceSnapshot>> getTwoLatest(String instrumentId) =>
      (_db.select(_db.priceSnapshots)
            ..where((t) => t.instrumentId.equals(instrumentId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ])
            ..limit(2))
          .get();

  /// Fetch the latest price snapshot for each of the given instrument IDs in one query.
  Future<Map<String, PriceSnapshot>> getLatestBatch(
    List<String> instrumentIds,
  ) async {
    if (instrumentIds.isEmpty) return {};
    final rows =
        await (_db.select(_db.priceSnapshots)
              ..where((t) => t.instrumentId.isIn(instrumentIds))
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
              ]))
            .get();
    // Keep only the most-recent row per instrument (list is already desc by date)
    final result = <String, PriceSnapshot>{};
    for (final row in rows) {
      result.putIfAbsent(row.instrumentId, () => row);
    }
    return result;
  }

  /// Fetch the two most-recent snapshots for each instrument in one query.
  Future<Map<String, List<PriceSnapshot>>> getTwoLatestBatch(
    List<String> instrumentIds,
  ) async {
    if (instrumentIds.isEmpty) return {};
    final rows =
        await (_db.select(_db.priceSnapshots)
              ..where((t) => t.instrumentId.isIn(instrumentIds))
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
              ]))
            .get();
    final result = <String, List<PriceSnapshot>>{};
    for (final row in rows) {
      result.putIfAbsent(row.instrumentId, () => []);
      if ((result[row.instrumentId]!.length) < 2) {
        result[row.instrumentId]!.add(row);
      }
    }
    return result;
  }

  Future<void> insertOrUpdate(Insertable<PriceSnapshot> snapshot) async {
    await _db.into(_db.priceSnapshots).insertOnConflictUpdate(snapshot);
  }

  Future<int> clearAll() => _db.delete(_db.priceSnapshots).go();
}

class FxRateDao {
  FxRateDao(this._db);
  final AppDatabase _db;

  Future<FxRate?> getLatest(String base, String quote) =>
      (_db.select(_db.fxRates)
            ..where((t) => t.base.equals(base) & t.quote.equals(quote))
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ]))
          .getSingleOrNull();

  Future<FxRate?> getLatestNonManual(String base, String quote) =>
      (_db.select(_db.fxRates)
            ..where(
              (t) =>
                  t.base.equals(base) &
                  t.quote.equals(quote) &
                  t.source.equals('manual').not(),
            )
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ]))
          .getSingleOrNull();

  Future<void> insertOrUpdate(Insertable<FxRate> rate) async {
    await _db.into(_db.fxRates).insertOnConflictUpdate(rate);
  }

  Future<void> deleteRate(String base, String quote) async {
    await (_db.delete(
      _db.fxRates,
    )..where((t) => t.base.equals(base) & t.quote.equals(quote))).go();
  }

  Future<int> clearAll() => _db.delete(_db.fxRates).go();

  Future<List<FxRate>> getAllLatest() async {
    // Get all rows, grouped by base/quote, with latest date
    final query = _db.select(_db.fxRates)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    final all = await query.get();
    final seen = <String>{};
    return all.where((r) {
      final key = '${r.base}:${r.quote}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }
}

class FdRdAccountDao {
  FdRdAccountDao(this._db);
  final AppDatabase _db;

  Future<FdRdAccount?> getByHoldingId(String holdingId) => (_db.select(
    _db.fdRdAccounts,
  )..where((t) => t.holdingId.equals(holdingId))).getSingleOrNull();

  Future<String> insert(Insertable<FdRdAccount> account) async {
    final row = await _db.into(_db.fdRdAccounts).insertReturning(account);
    return row.holdingId;
  }

  Future<bool> update(Insertable<FdRdAccount> account) async {
    return await _db.update(_db.fdRdAccounts).replace(account);
  }

  Future<int> delete(String holdingId) => (_db.delete(
    _db.fdRdAccounts,
  )..where((t) => t.holdingId.equals(holdingId))).go();
  Future<List<FdRdAccount>> getAll() => _db.select(_db.fdRdAccounts).get();
  Future<int> clearAll() => _db.delete(_db.fdRdAccounts).go();
}

class PpfAccountDao {
  PpfAccountDao(this._db);
  final AppDatabase _db;

  Future<PpfAccount?> getByHoldingId(String holdingId) => (_db.select(
    _db.ppfAccounts,
  )..where((t) => t.holdingId.equals(holdingId))).getSingleOrNull();

  Future<String> insert(Insertable<PpfAccount> account) async {
    final row = await _db.into(_db.ppfAccounts).insertReturning(account);
    return row.holdingId;
  }

  Future<bool> update(Insertable<PpfAccount> account) async {
    return await _db.update(_db.ppfAccounts).replace(account);
  }

  Future<int> delete(String holdingId) => (_db.delete(
    _db.ppfAccounts,
  )..where((t) => t.holdingId.equals(holdingId))).go();
  Future<List<PpfAccount>> getAll() => _db.select(_db.ppfAccounts).get();
  Future<int> clearAll() => _db.delete(_db.ppfAccounts).go();
}

class InsurancePolicyDao {
  InsurancePolicyDao(this._db);
  final AppDatabase _db;

  Future<InsurancePolicy?> getByHoldingId(String holdingId) => (_db.select(
    _db.insurancePolicies,
  )..where((t) => t.holdingId.equals(holdingId))).getSingleOrNull();

  Future<String> insert(Insertable<InsurancePolicy> policy) async {
    final row = await _db.into(_db.insurancePolicies).insertReturning(policy);
    return row.holdingId;
  }

  Future<bool> update(Insertable<InsurancePolicy> policy) async {
    return await _db.update(_db.insurancePolicies).replace(policy);
  }

  Future<int> delete(String holdingId) => (_db.delete(
    _db.insurancePolicies,
  )..where((t) => t.holdingId.equals(holdingId))).go();
  Future<List<InsurancePolicy>> getAll() =>
      _db.select(_db.insurancePolicies).get();
  Future<int> clearAll() => _db.delete(_db.insurancePolicies).go();
}

class CryptoHoldingDao {
  CryptoHoldingDao(this._db);
  final AppDatabase _db;

  Future<CryptoHolding?> getByHoldingId(String holdingId) => (_db.select(
    _db.cryptoHoldings,
  )..where((t) => t.holdingId.equals(holdingId))).getSingleOrNull();

  Future<List<CryptoHolding>> getBySymbol(String symbol) => (_db.select(
    _db.cryptoHoldings,
  )..where((t) => t.symbol.equals(symbol))).get();

  Future<String> insert(Insertable<CryptoHolding> crypto) async {
    final row = await _db.into(_db.cryptoHoldings).insertReturning(crypto);
    return row.holdingId;
  }

  Future<bool> update(Insertable<CryptoHolding> crypto) async {
    return await _db.update(_db.cryptoHoldings).replace(crypto);
  }

  Future<int> delete(String holdingId) => (_db.delete(
    _db.cryptoHoldings,
  )..where((t) => t.holdingId.equals(holdingId))).go();
  Future<List<CryptoHolding>> getAll() => _db.select(_db.cryptoHoldings).get();
  Future<int> clearAll() => _db.delete(_db.cryptoHoldings).go();
}

class RealEstateHoldingDao {
  RealEstateHoldingDao(this._db);
  final AppDatabase _db;

  Future<RealEstateHolding?> getByHoldingId(String holdingId) => (_db.select(
    _db.realEstateHoldings,
  )..where((t) => t.holdingId.equals(holdingId))).getSingleOrNull();

  Future<String> insert(Insertable<RealEstateHolding> realEstate) async {
    final row = await _db
        .into(_db.realEstateHoldings)
        .insertReturning(realEstate);
    return row.holdingId;
  }

  Future<bool> update(Insertable<RealEstateHolding> realEstate) async {
    return await _db.update(_db.realEstateHoldings).replace(realEstate);
  }

  Future<int> delete(String holdingId) => (_db.delete(
    _db.realEstateHoldings,
  )..where((t) => t.holdingId.equals(holdingId))).go();

  Future<List<RealEstateHolding>> getAll() =>
      _db.select(_db.realEstateHoldings).get();
  Future<int> clearAll() => _db.delete(_db.realEstateHoldings).go();
}

@riverpod
InstrumentDao instrumentDao(Ref ref) =>
    InstrumentDao(ref.watch(appDatabaseProvider));

@riverpod
HoldingDao holdingDao(Ref ref) => HoldingDao(ref.watch(appDatabaseProvider));

@riverpod
TransactionDao transactionDao(Ref ref) =>
    TransactionDao(ref.watch(appDatabaseProvider));

@riverpod
PriceSnapshotDao priceSnapshotDao(Ref ref) =>
    PriceSnapshotDao(ref.watch(appDatabaseProvider));

@riverpod
FxRateDao fxRateDao(Ref ref) => FxRateDao(ref.watch(appDatabaseProvider));

@riverpod
FdRdAccountDao fdRdAccountDao(Ref ref) =>
    FdRdAccountDao(ref.watch(appDatabaseProvider));

@riverpod
PpfAccountDao ppfAccountDao(Ref ref) =>
    PpfAccountDao(ref.watch(appDatabaseProvider));

@riverpod
InsurancePolicyDao insurancePolicyDao(Ref ref) =>
    InsurancePolicyDao(ref.watch(appDatabaseProvider));

@riverpod
CryptoHoldingDao cryptoHoldingDao(Ref ref) =>
    CryptoHoldingDao(ref.watch(appDatabaseProvider));

@riverpod
RealEstateHoldingDao realEstateHoldingDao(Ref ref) =>
    RealEstateHoldingDao(ref.watch(appDatabaseProvider));

final holdingsWithInstrumentsProvider =
    StreamProvider<List<HoldingWithInstrument>>((Ref ref) {
      final holdingDao = ref.watch(holdingDaoProvider);
      return holdingDao.watchAllWithInstruments();
    });
