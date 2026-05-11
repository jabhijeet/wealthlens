import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../logging/error_handler.dart';

class FundamentalService {
  FundamentalService({
    required FundamentalSnapshotDao dao,
    required InstrumentDao instrumentDao,
  }) : _dao = dao,
       _instrumentDao = instrumentDao;

  final FundamentalSnapshotDao _dao;
  final InstrumentDao _instrumentDao;
  final Dio _dio = DioClient.create(
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    },
  );

  /// Refresh fundamental data for all equity instruments.
  Future<void> refreshAllFundamentals() async {
    final instruments = await _instrumentDao.getAll();
    final equities = instruments
        .where((i) => i.assetClass == AssetClass.equity)
        .toList();

    for (final instrument in equities) {
      try {
        await refreshFundamentalsForInstrument(instrument);
      } catch (e, stackTrace) {
        errorHandler.handleError(
          e,
          stackTrace: stackTrace,
          context: 'refreshing fundamentals for ${instrument.symbol}',
        );
      }
    }
  }

  Future<void> refreshFundamentalsForInstrument(Instrument instrument) async {
    if (instrument.assetClass != AssetClass.equity) return;

    final symbol = instrument.symbol;
    if (symbol == null || symbol.isEmpty) return;

    // Try Yahoo Finance for common ratios
    final data = await _fetchYahooFundamentals(symbol);

    // If it's an Indian stock, try Screener for deep metrics
    if (symbol.endsWith('.NS') || symbol.endsWith('.BO')) {
      final screenerData = await _fetchScreenerFundamentals(symbol);
      data.addAll(screenerData);
    }

    if (data.isNotEmpty) {
      await _dao.insertOrUpdate(
        FundamentalSnapshotsCompanion(
          instrumentId: Value(instrument.id),
          date: Value(DateTime.now()),
          peRatio: Value(data['pe']),
          pbRatio: Value(data['pb']),
          roe: Value(data['roe']),
          roce: Value(data['roce']),
          marketCap: Value(data['marketCap']),
          debtToEquity: Value(data['debtToEquity']),
          source: Value(
            symbol.endsWith('.NS') || symbol.endsWith('.BO')
                ? 'hybrid'
                : 'yahoo',
          ),
        ),
      );
    }
  }

  Future<Map<String, String?>> _fetchYahooFundamentals(String symbol) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://query1.finance.yahoo.com/v7/finance/quote',
        queryParameters: {'symbols': symbol},
      );

      final data = response.data;
      if (data == null) return {};

      final quoteResponse = data['quoteResponse'];
      if (quoteResponse is! Map<String, dynamic>) return {};

      final result = quoteResponse['result'] as List<dynamic>?;
      if (result == null || result.isEmpty) return {};

      final quote = result[0] as Map<String, dynamic>;
      return {
        'pe': quote['trailingPE']?.toString(),
        'pb': quote['priceToBook']?.toString(),
        'marketCap': quote['marketCap']?.toString(),
      };
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, String?>> _fetchScreenerFundamentals(String symbol) async {
    final cleanSymbol = symbol.split('.')[0]; // RELIANCE.NS -> RELIANCE

    try {
      // 1. Search for company ID
      final searchResponse = await _dio.get<List<dynamic>>(
        'https://www.screener.in/api/company/search/',
        queryParameters: {'q': cleanSymbol},
      );

      if (searchResponse.data == null || searchResponse.data!.isEmpty) {
        return {};
      }

      final company = searchResponse.data![0] as Map<String, dynamic>;
      final id = company['id']?.toString();
      if (id == null) return {};

      // 2. Fetch specific metrics from Chart API
      final metrics = ['ROE', 'ROCE', 'P/E+Ratio', 'Debt+to+equity'];
      final results = <String, String?>{};

      for (final metric in metrics) {
        try {
          final chartResponse = await _dio.get<Map<String, dynamic>>(
            'https://www.screener.in/api/company/$id/chart/',
            queryParameters: {'q': metric, 'days': 1},
          );

          final datasets = chartResponse.data?['datasets'] as List<dynamic>?;
          if (datasets != null && datasets.isNotEmpty) {
            final dataset = datasets[0];
            if (dataset is! Map<String, dynamic>) continue;

            final values = dataset['values'] as List<dynamic>?;
            if (values != null && values.isNotEmpty) {
              final lastEntry = values.last;
              if (lastEntry is! Map<String, dynamic>) continue;

              final latestValue = lastEntry['avg']?.toString();
              if (metric == 'ROE') results['roe'] = latestValue;
              if (metric == 'ROCE') results['roce'] = latestValue;
              if (metric == 'P/E+Ratio') results['pe'] = latestValue;
              if (metric == 'Debt+to+equity') {
                results['debtToEquity'] = latestValue;
              }
            }
          }
        } catch (e) {
          // Continue with other metrics
        }
      }

      return results;
    } catch (e) {
      return {};
    }
  }
}

final fundamentalServiceProvider = Provider<FundamentalService>((ref) {
  return FundamentalService(
    dao: ref.watch(fundamentalSnapshotDaoProvider),
    instrumentDao: ref.watch(instrumentDaoProvider),
  );
});
