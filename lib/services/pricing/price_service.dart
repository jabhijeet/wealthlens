import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../domain/money.dart';
import 'price_feed.dart';

class PriceService {
  PriceService(this._dao, this._router);
  final PriceSnapshotDao _dao;
  final PriceFeedRouter _router;

  /// Get the latest price for an instrument, fetching if necessary.
  Future<Money> getLatestPrice(Instrument instrument) async {
    // Check cache first
    final cached = await _dao.getLatest(instrument.id);
    if (cached != null) {
      // If cache is less than 1 hour old, use it
      if (DateTime.now().difference(cached.date).inHours < 1) {
        return Money(minor: cached.closeMinor, currency: cached.currency);
      }
    }

    // Fetch fresh price
    try {
      final price = await _router.quote(instrument);
      // Store in cache
      await _dao.insertOrUpdate(
        PriceSnapshotsCompanion(
          instrumentId: Value(instrument.id),
          date: Value(DateTime.now()),
          closeMinor: Value(price.minor),
          currency: Value(price.currency),
          source: Value(_getSourceName(instrument.assetClass)),
        ),
      );
      return price;
    } catch (e) {
      // If fetch fails, return cached price (even if stale) or throw
      if (cached != null) {
        return Money(minor: cached.closeMinor, currency: cached.currency);
      }
      rethrow;
    }
  }

  /// Batch fetch prices for multiple instruments.
  Future<Map<String, Money>> getLatestPrices(
    List<Instrument> instruments,
  ) async {
    final results = <String, Money>{};
    final toFetch = <Instrument>[];

    // Check cache first
    for (final instrument in instruments) {
      final cached = await _dao.getLatest(instrument.id);
      if (cached != null &&
          DateTime.now().difference(cached.date).inHours < 1) {
        results[instrument.id] = Money(
          minor: cached.closeMinor,
          currency: cached.currency,
        );
      } else {
        toFetch.add(instrument);
      }
    }

    if (toFetch.isEmpty) return results;

    // Fetch batch
    final batchResults = await _router.quoteBatch(toFetch);

    for (final instrument in toFetch) {
      final price = batchResults[instrument.id];
      if (price != null) {
        results[instrument.id] = price;
        // Store in cache
        await _dao.insertOrUpdate(
          PriceSnapshotsCompanion(
            instrumentId: Value(instrument.id),
            date: Value(DateTime.now()),
            closeMinor: Value(price.minor),
            currency: Value(price.currency),
            source: Value(_getSourceName(instrument.assetClass)),
          ),
        );
      } else {
        // Fallback to old cache
        final cached = await _dao.getLatest(instrument.id);
        if (cached != null) {
          results[instrument.id] = Money(
            minor: cached.closeMinor,
            currency: cached.currency,
          );
        }
      }
    }

    return results;
  }

  /// Refresh all prices in background (called by workmanager).
  Future<void> refreshAllPrices(List<Instrument> instruments) async {
    await getLatestPrices(instruments);
  }

  String _getSourceName(AssetClass assetClass) {
    switch (assetClass) {
      case AssetClass.equity:
      case AssetClass.etf:
      case AssetClass.realEstateReit:
        return 'yahoo';
      case AssetClass.mutualFund:
        return 'amfi';
      case AssetClass.cryptoSpot:
      case AssetClass.cryptoStaked:
      case AssetClass.cryptoLpToken:
        return 'coingecko';
      default:
        return 'manual';
    }
  }
}

final priceServiceProvider = Provider<PriceService>((ref) {
  final dao = ref.watch(priceSnapshotDaoProvider);
  final router = ref.watch(priceFeedRouterProvider);
  return PriceService(dao, router);
});
