import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/database.dart';
import '../../domain/money.dart';

abstract class PriceFeed {
  Future<Money> quote(Instrument instrument);
  Future<Map<String, Money>> batchQuote(List<Instrument> instruments);
}

class YahooChartResult {
  YahooChartResult({required this.regularMarketPrice, required this.currency});

  factory YahooChartResult.fromJson(Map<String, dynamic> json) {
    final chart = json['chart'] as Map<String, dynamic>;
    final result = chart['result'] as List<dynamic>;
    final firstResult = result[0] as Map<String, dynamic>;
    final meta = firstResult['meta'] as Map<String, dynamic>;
    return YahooChartResult(
      regularMarketPrice: (meta['regularMarketPrice'] as num).toDouble(),
      currency: meta['currency'].toString(),
    );
  }

  final double regularMarketPrice;
  final String currency;
}

class YahooQuoteResult {
  YahooQuoteResult({
    required this.symbol,
    required this.regularMarketPrice,
    required this.currency,
  });

  factory YahooQuoteResult.fromJson(Map<String, dynamic> json) {
    return YahooQuoteResult(
      symbol: json['symbol'].toString(),
      regularMarketPrice: (json['regularMarketPrice'] as num).toDouble(),
      currency: json['currency'].toString(),
    );
  }

  final String symbol;
  final double regularMarketPrice;
  final String currency;
}

class YahooBatchResult {
  YahooBatchResult({required this.prices});

  factory YahooBatchResult.fromJson(Map<String, dynamic> json) {
    final priceData = json['prices'] as Map<String, dynamic>;
    return YahooBatchResult(
      prices: priceData.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  final Map<String, double> prices;
}

class CoinGeckoPriceResult {
  CoinGeckoPriceResult({required this.prices});

  factory CoinGeckoPriceResult.fromJson(Map<String, dynamic> json, String id) {
    final priceData = json[id] as Map<String, dynamic>;
    return CoinGeckoPriceResult(
      prices: priceData.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  final Map<String, double> prices;
}

class YahooFinanceFeed implements PriceFeed {
  final Dio _dio = DioClient.create();

  @override
  Future<Money> quote(Instrument instrument) async {
    final symbol = instrument.symbol;
    if (symbol == null || symbol.isEmpty) {
      throw Exception('Instrument missing symbol');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol',
        queryParameters: {
          'range': '1d',
          'interval': '1d',
          'includePrePost': 'false',
        },
      );

      final data = response.data;
      if (data == null) throw Exception('No response data');

      final result = YahooChartResult.fromJson(data);
      final price = result.regularMarketPrice;
      final currency = result.currency;

      return Money.fromDecimal(Decimal.parse(price.toString()), currency);
    } catch (e) {
      throw Exception('Yahoo Finance failed: $e');
    }
  }

  @override
  Future<Map<String, Money>> batchQuote(List<Instrument> instruments) async {
    // Yahoo doesn't have a great batch chart API, but we can use the quotes API
    final symbols = instruments
        .map((i) => i.symbol)
        .where((s) => s != null && s.isNotEmpty)
        .join(',');
    if (symbols.isEmpty) return {};

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://query1.finance.yahoo.com/v7/finance/quote',
        queryParameters: {'symbols': symbols},
      );

      final data = response.data;
      if (data == null) throw Exception('No response data');

      final quoteResponse = data['quoteResponse'] as Map<String, dynamic>;
      final resultList = quoteResponse['result'] as List<dynamic>;

      final quotes = resultList
          .map((q) => YahooQuoteResult.fromJson(q as Map<String, dynamic>))
          .toList();

      final resultMap = <String, Money>{};
      for (final instrument in instruments) {
        final quote = quotes
            .where((q) => q.symbol == instrument.symbol)
            .firstOrNull;
        if (quote != null) {
          resultMap[instrument.id] = Money.fromDecimal(
            Decimal.parse(quote.regularMarketPrice.toString()),
            quote.currency,
          );
        }
      }

      return resultMap;
    } catch (e) {
      throw Exception('Yahoo Finance batch failed: $e');
    }
  }
}

class IndiaMutualFundFeed implements PriceFeed {
  final Dio _dio = DioClient.create();

  @override
  Future<Money> quote(Instrument instrument) async {
    final symbol = instrument.symbol;
    if (symbol == null) throw Exception('MF scheme code required');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.mfapi.in/mf/$symbol',
      );

      final data = response.data;
      if (data == null) throw Exception('No response data');

      final dataset = data['data'] as List<dynamic>;
      final latest = dataset[0] as Map<String, dynamic>;
      final nav = latest['nav'].toString();

      return Money.fromDecimal(Decimal.parse(nav), 'INR');
    } catch (e) {
      throw Exception('MF API failed: $e');
    }
  }

  @override
  Future<Map<String, Money>> batchQuote(List<Instrument> instruments) async {
    final results = <String, Money>{};
    for (final instrument in instruments) {
      try {
        results[instrument.id] = await quote(instrument);
      } catch (e) {
        // Continue with other instruments
      }
    }
    return results;
  }
}

class FixedIncomeFeed implements PriceFeed {
  @override
  Future<Money> quote(Instrument instrument) async {
    // Fixed income doesn't change price, just accrues interest
    // For now return par value (1.0)
    return Money.fromDecimal(Decimal.one, instrument.currency);
  }

  @override
  Future<Map<String, Money>> batchQuote(List<Instrument> instruments) async {
    final results = <String, Money>{};
    for (final instrument in instruments) {
      results[instrument.id] = await quote(instrument);
    }
    return results;
  }
}

class CoinGeckoFeed implements PriceFeed {
  final Dio _dio = DioClient.create();

  @override
  Future<Money> quote(Instrument instrument) async {
    final symbol = instrument.symbol?.toLowerCase();
    if (symbol == null) throw Exception('Crypto symbol required');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.coingecko.com/api/v3/simple/price',
        queryParameters: {
          'ids': symbol,
          'vs_currencies': instrument.currency.toLowerCase(),
        },
      );

      final data = response.data;
      if (data == null) throw Exception('No response data');

      final result = CoinGeckoPriceResult.fromJson(data, symbol);
      final price = result.prices[instrument.currency.toLowerCase()];

      if (price == null) throw Exception('Price not found for $symbol');

      return Money.fromDecimal(
        Decimal.parse(price.toString()),
        instrument.currency,
      );
    } catch (e) {
      throw Exception('CoinGecko failed: $e');
    }
  }

  @override
  Future<Map<String, Money>> batchQuote(List<Instrument> instruments) async {
    final ids = instruments
        .map((i) => i.symbol?.toLowerCase())
        .where((s) => s != null)
        .join(',');
    final currencies = instruments
        .map((i) => i.currency.toLowerCase())
        .toSet()
        .join(',');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.coingecko.com/api/v3/simple/price',
        queryParameters: {'ids': ids, 'vs_currencies': currencies},
      );

      final data = response.data;
      if (data == null) throw Exception('No response data');

      final results = <String, Money>{};
      for (final instrument in instruments) {
        final symbol = instrument.symbol?.toLowerCase();
        if (symbol == null || !data.containsKey(symbol)) continue;

        final priceData = data[symbol] as Map<String, dynamic>;
        final price = priceData[instrument.currency.toLowerCase()];

        if (price != null) {
          results[instrument.id] = Money.fromDecimal(
            Decimal.parse(price.toString()),
            instrument.currency,
          );
        }
      }
      return results;
    } catch (e) {
      throw Exception('CoinGecko batch failed: $e');
    }
  }
}

class PriceFeedRouter {
  PriceFeedRouter({
    YahooFinanceFeed? yahoo,
    IndiaMutualFundFeed? mf,
    FixedIncomeFeed? fi,
    CoinGeckoFeed? coingecko,
  }) {
    // Cache single instances to avoid creating N identical HTTP clients
    final yahooFeed = yahoo ?? YahooFinanceFeed();
    final mfFeed = mf ?? IndiaMutualFundFeed();
    final fiFeed = fi ?? FixedIncomeFeed();
    final cryptoFeed = coingecko ?? CoinGeckoFeed();
    _feeds = {
      AssetClass.equity: yahooFeed,
      AssetClass.etf: yahooFeed,
      AssetClass.mutualFund: mfFeed,
      AssetClass.bond: fiFeed,
      AssetClass.fixedDeposit: fiFeed,
      AssetClass.recurringDeposit: fiFeed,
      AssetClass.ppf: fiFeed,
      AssetClass.epf: fiFeed,
      AssetClass.nps: mfFeed,
      AssetClass.insuranceTerm: fiFeed,
      AssetClass.insuranceEndowment: fiFeed,
      AssetClass.insuranceMoneyback: fiFeed,
      AssetClass.insuranceUlip: mfFeed,
      AssetClass.insuranceAnnuity: fiFeed,
      AssetClass.cryptoSpot: cryptoFeed,
      AssetClass.cryptoStaked: cryptoFeed,
      AssetClass.cryptoLpToken: cryptoFeed,
      AssetClass.cryptoNft: cryptoFeed,
      AssetClass.cryptoStablecoin: cryptoFeed,
      AssetClass.realEstateResidentialSelfUse: fiFeed,
      AssetClass.realEstateResidentialRented: fiFeed,
      AssetClass.realEstateCommercialRented: fiFeed,
      AssetClass.realEstateCommercialVacant: fiFeed,
      AssetClass.realEstateLand: fiFeed,
      AssetClass.realEstateReit: yahooFeed,
      AssetClass.cash: fiFeed,
      AssetClass.commodity: yahooFeed,
      AssetClass.custom: fiFeed,
    };
  }
  late final Map<AssetClass, PriceFeed> _feeds;

  PriceFeed getFeed(AssetClass assetClass) {
    return _feeds[assetClass] ?? _feeds[AssetClass.equity]!;
  }

  Future<Money> quote(Instrument instrument) {
    return getFeed(instrument.assetClass).quote(instrument);
  }

  Future<Map<String, Money>> quoteBatch(List<Instrument> instruments) async {
    final results = <String, Money>{};

    // Group by asset class
    final grouped = <AssetClass, List<Instrument>>{};
    for (final instrument in instruments) {
      grouped.putIfAbsent(instrument.assetClass, () => []).add(instrument);
    }

    // Fetch from each feed
    for (final entry in grouped.entries) {
      final feed = getFeed(entry.key);
      final feedResults = await feed.batchQuote(entry.value);
      results.addAll(feedResults);
    }

    return results;
  }
}

final priceFeedRouterProvider = Provider<PriceFeedRouter>((ref) {
  return PriceFeedRouter();
});
