import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../logging/error_handler.dart';
import '../logging/logger_service.dart';
import '../../llm/llm_provider.dart';
import '../../llm/llm_service.dart';

abstract class FxFeed {
  String get name;
  Future<Decimal> getRate(String base, String quote);
  Future<Map<String, Decimal>> getRates(String base, List<String> quotes);
}

class FrankfurterFeed implements FxFeed {
  @override
  String get name => 'frankfurter.app';

  final Dio _dio = DioClient.create();

  @override
  Future<Decimal> getRate(String base, String quote) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.frankfurter.app/latest',
        queryParameters: {'from': base, 'to': quote},
      );
      final data = response.data as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>;
      final rate = rates[quote] as num;
      return Decimal.parse(rate.toString());
    } catch (e) {
      throw Exception('Failed to fetch FX rate from Frankfurter: $e');
    }
  }

  @override
  Future<Map<String, Decimal>> getRates(
    String base,
    List<String> quotes,
  ) async {
    final results = <String, Decimal>{};
    for (final quote in quotes) {
      try {
        results[quote] = await getRate(base, quote);
      } catch (e) {
        // Skip
      }
    }
    return results;
  }
}

class YahooFxFeed implements FxFeed {
  @override
  String get name => 'Yahoo Finance';

  final Dio _dio = DioClient.create(
    headers: kIsWeb
        ? null
        : {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
  );

  @override
  Future<Decimal> getRate(String base, String quote) async {
    try {
      final symbol = '$base$quote=X';
      final response = await _dio.get<Map<String, dynamic>>(
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol',
        queryParameters: {'interval': '1d', 'range': '1d'},
      );
      final data = response.data!;
      final chart = data['chart'] as Map<String, dynamic>;
      final resultList = chart['result'] as List<dynamic>;
      final result = resultList[0] as Map<String, dynamic>;
      final meta = result['meta'] as Map<String, dynamic>;
      final price = meta['regularMarketPrice'] as num;
      return Decimal.parse(price.toString());
    } catch (e) {
      throw Exception('Failed to fetch FX rate from Yahoo Finance: $e');
    }
  }

  @override
  Future<Map<String, Decimal>> getRates(
    String base,
    List<String> quotes,
  ) async {
    final results = <String, Decimal>{};
    for (final quote in quotes) {
      try {
        results[quote] = await getRate(base, quote);
      } catch (e) {
        // Skip
      }
    }
    return results;
  }
}

class ExchangeRateHostFeed implements FxFeed {
  @override
  String get name => 'ExchangeRate-API';

  final Dio _dio = DioClient.create();

  @override
  Future<Decimal> getRate(String base, String quote) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.exchangerate-api.com/v4/latest/$base',
      );
      final data = response.data as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>;
      final rate = rates[quote] as num;
      return Decimal.parse(rate.toString());
    } catch (e) {
      throw Exception('Failed to fetch FX rate from ExchangeRate-API: $e');
    }
  }

  @override
  Future<Map<String, Decimal>> getRates(
    String base,
    List<String> quotes,
  ) async {
    final results = <String, Decimal>{};
    for (final quote in quotes) {
      try {
        results[quote] = await getRate(base, quote);
      } catch (e) {
        // Skip
      }
    }
    return results;
  }
}

class LlmFxFeed implements FxFeed {
  LlmFxFeed(this._ref);
  final Ref _ref;

  @override
  String get name => 'AI Intelligence';

  @override
  Future<Decimal> getRate(String base, String quote) async {
    final llmService = _ref.read(llmServiceProvider);
    final provider = _ref.read(activeLlmProvider);

    if (provider == null || !provider.isConfigured) {
      throw ConfigurationException(
        'AI Provider is not configured for FX feed.',
        code: 'MISSING_LLM_PROVIDER',
      );
    }

    try {
      final prompt =
          '''
Return the current exchange rate for $base to $quote. 
Provide only the numerical value as a decimal.
No text, no units, just the number.
If you don't know the exact current rate, provide your best recent estimate.
''';

      final response = await llmService.chatCompletion(
        provider: provider,
        prompt: prompt,
        task: LlmTask.marketData,
      );

      // Extract number from potential markdown or extra text
      final match = RegExp(r'(\d+\.?\d*)').firstMatch(response);
      if (match != null) {
        return Decimal.parse(match.group(1)!);
      }
      throw Exception('AI returned invalid rate format: $response');
    } catch (e) {
      throw Exception('AI FX Fetch failed: $e');
    }
  }

  @override
  Future<Map<String, Decimal>> getRates(
    String base,
    List<String> quotes,
  ) async {
    final results = <String, Decimal>{};
    for (final quote in quotes) {
      try {
        results[quote] = await getRate(base, quote);
      } catch (e) {
        // Skip
      }
    }
    return results;
  }
}

class FxService {
  FxService(this._dao, {List<FxFeed>? feeds, Ref? ref})
    : _feeds =
          feeds ??
          (kIsWeb
              ? [
                  ExchangeRateHostFeed(),
                  FrankfurterFeed(),
                  YahooFxFeed(),
                  if (ref != null) LlmFxFeed(ref),
                ]
              : [
                  FrankfurterFeed(),
                  YahooFxFeed(),
                  ExchangeRateHostFeed(),
                  if (ref != null) LlmFxFeed(ref),
                ]);

  final FxRateDao _dao;
  final List<FxFeed> _feeds;

  /// Force fetch a rate from network and update cache
  Future<Decimal> forceFetch(String base, String quote) async {
    if (base == quote) return Decimal.one;

    for (final feed in _feeds) {
      try {
        final rate = await feed.getRate(base, quote);
        await _saveToCache(base, quote, rate, feed.name);
        return rate;
      } catch (e) {
        continue;
      }
    }
    return getRate(base, quote); // Fallback to whatever we have
  }

  Future<void> _saveToCache(
    String base,
    String quote,
    Decimal rate,
    String source,
  ) async {
    await _dao.insertOrUpdate(
      FxRatesCompanion(
        date: Value(DateTime.now()),
        base: Value(base),
        quote: Value(quote),
        rate: Value(rate.toString()),
        source: Value(source),
      ),
    );
  }

  Future<Decimal?> _getValidCache(
    String base,
    String quote, {
    bool inverse = false,
  }) async {
    final cached = await _dao.getLatest(base, quote);
    if (cached == null) return null;

    final rate = Decimal.parse(cached.rate);
    final cacheLimit =
        (cached.source == 'manual' || cached.source == 'AI Intelligence')
        ? 168
        : 12;

    if (DateTime.now().difference(cached.date).inHours < cacheLimit) {
      if (inverse) {
        if (rate == Decimal.zero) return Decimal.one;
        return (Decimal.one / rate).toDecimal(scaleOnInfinitePrecision: 10);
      }
      return rate;
    }
    return null;
  }

  /// Get the latest FX rate, trying each feed in order until one succeeds.
  Future<Decimal> getRate(String base, String quote) async {
    if (base == quote) return Decimal.one;

    // Check cache first (direct)
    final cachedRate = await _getValidCache(base, quote);
    if (cachedRate != null) return cachedRate;

    // Check cache (inverse)
    final inverseCachedRate = await _getValidCache(quote, base, inverse: true);
    if (inverseCachedRate != null) return inverseCachedRate;

    // Fetch from feeds
    for (final feed in _feeds) {
      try {
        final rate = await feed.getRate(base, quote);
        await _saveToCache(base, quote, rate, feed.name);
        return rate;
      } catch (e) {
        // Log the failure for this specific feed
        final context = 'FX Feed ${feed.name} failed for $base/$quote';
        final isCors = kIsWeb && e.toString().contains('XMLHttpRequest');

        if (isCors) {
          // CORS is expected for some public APIs on Web, log as warning
          logger.w('$context (Likely CORS restriction on Web)', e);
        } else if (e is ConfigurationException) {
          // Expected config error, log as warning
          errorHandler.handleError(e, context: context);
        } else {
          // Real error or non-web environment, use standard error handler
          errorHandler.handleError(e, context: context);
        }
        continue;
      }
    }

    // Stale cache > nothing > 1:1 fallback
    final stale = await _dao.getLatest(base, quote);
    if (stale != null) {
      return Decimal.parse(stale.rate);
    }

    final staleInverse = await _dao.getLatest(quote, base);
    if (staleInverse != null) {
      final rate = Decimal.parse(staleInverse.rate);
      if (rate == Decimal.zero) return Decimal.one;
      return (Decimal.one / rate).toDecimal(scaleOnInfinitePrecision: 10);
    }

    return Decimal.one;
  }

  /// Convert an amount from one currency to another using the latest rate.
  Future<Decimal> convert(Decimal amount, String from, String to) async {
    if (from == to) return amount;
    final rate = await getRate(from, to);
    return amount * rate;
  }

  /// Get rates for multiple currency pairs in batch.
  Future<Map<String, Decimal>> getRates(
    String base,
    List<String> quotes,
  ) async {
    final results = <String, Decimal>{};
    for (final quote in quotes) {
      try {
        results[quote] = await getRate(base, quote);
      } catch (e) {
        // Skip failed pairs
      }
    }
    return results;
  }
}

final fxServiceProvider = Provider<FxService>((ref) {
  final dao = ref.watch(fxRateDaoProvider);
  return FxService(dao, ref: ref);
});
