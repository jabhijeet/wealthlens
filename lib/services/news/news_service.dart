import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/db/daos.dart';
import '../../llm/llm_service.dart';
import '../../llm/llm_provider.dart';
import '../logging/error_handler.dart';

class NewsArticle {
  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.publishedAt,
    this.imageUrl,
    this.symbols = const [],
    this.sentimentScore,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'].toString(),
      title: json['title'].toString(),
      description: json['description'].toString(),
      url: json['url'].toString(),
      source: json['source'].toString(),
      publishedAt: DateTime.parse(json['publishedAt'].toString()),
      imageUrl: json['imageUrl']?.toString(),
      symbols: List<String>.from(json['symbols'] as List? ?? []),
      sentimentScore: json['sentimentScore'] is num
          ? (json['sentimentScore'] as num).toDouble()
          : null,
    );
  }

  final String id;
  final String title;
  final String description;
  final String url;
  final String source;
  final DateTime publishedAt;
  final String? imageUrl;
  final List<String> symbols;
  final double? sentimentScore;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'url': url,
    'source': source,
    'publishedAt': publishedAt.toIso8601String(),
    'imageUrl': imageUrl,
    'symbols': symbols,
    'sentimentScore': sentimentScore,
  };
}

abstract class NewsAdapter {
  Future<List<NewsArticle>> fetchNews({
    required List<String> symbols,
    DateTime? fromDate,
    int limit = 50,
  });

  Future<List<NewsArticle>> fetchMarketNews({
    required String category,
    int limit = 50,
  });
}

class FinnhubNewsItem {
  FinnhubNewsItem({
    required this.id,
    required this.headline,
    required this.summary,
    required this.url,
    required this.source,
    required this.datetime,
    this.image,
    this.related,
  });

  factory FinnhubNewsItem.fromJson(Map<String, dynamic> json) {
    return FinnhubNewsItem(
      id: json['id'],
      headline: json['headline']?.toString(),
      summary: json['summary']?.toString(),
      url: json['url']?.toString(),
      source: json['source']?.toString(),
      datetime: json['datetime'] is num ? json['datetime'] as num : null,
      image: json['image']?.toString(),
      related: json['related']?.toString(),
    );
  }

  final dynamic id;
  final String? headline;
  final String? summary;
  final String? url;
  final String? source;
  final num? datetime;
  final String? image;
  final String? related;
}

class FinnhubNewsAdapter implements NewsAdapter {
  FinnhubNewsAdapter({required String apiKey, http.Client? client})
    : _apiKey = apiKey,
      _client = client ?? http.Client();
  final String _apiKey;
  final http.Client _client;

  @override
  Future<List<NewsArticle>> fetchNews({
    required List<String> symbols,
    DateTime? fromDate,
    int limit = 50,
  }) async {
    if (symbols.isEmpty) return [];

    final symbol = symbols.first; // Finnhub supports single symbol per request
    final from = fromDate ?? DateTime.now().subtract(const Duration(days: 7));
    final to = DateTime.now();

    final url = Uri.parse(
      'https://finnhub.io/api/v1/company-news?'
      'symbol=$symbol&'
      'from=${from.toIso8601String().split('T')[0]}&'
      'to=${to.toIso8601String().split('T')[0]}&'
      'token=$_apiKey',
    );

    final response = await _client
        .get(url)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.take(limit).map((json) {
        final item = FinnhubNewsItem.fromJson(json as Map<String, dynamic>);
        return NewsArticle(
          id: item.id.toString(),
          title: item.headline ?? 'No title',
          description: item.summary ?? '',
          url: item.url ?? '',
          source: item.source ?? 'Unknown',
          publishedAt: DateTime.fromMillisecondsSinceEpoch(
            (item.datetime?.toInt() ?? 0) * 1000,
          ),
          imageUrl: item.image,
          symbols: [symbol],
        );
      }).toList();
    } else {
      if (response.statusCode == 401) {
        throw ConfigurationException(
          'Invalid Finnhub API key. Please check your key in Settings.',
          code: 'INVALID_API_KEY',
        );
      }
      throw Exception('Failed to fetch news: ${response.statusCode}');
    }
  }

  @override
  Future<List<NewsArticle>> fetchMarketNews({
    required String category,
    int limit = 50,
  }) async {
    final url = Uri.parse(
      'https://finnhub.io/api/v1/news?'
      'category=$category&'
      'token=$_apiKey',
    );

    final response = await _client
        .get(url)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.take(limit).map((json) {
        final item = FinnhubNewsItem.fromJson(json as Map<String, dynamic>);
        return NewsArticle(
          id: item.id.toString(),
          title: item.headline ?? 'No title',
          description: item.summary ?? '',
          url: item.url ?? '',
          source: item.source ?? 'Unknown',
          publishedAt: DateTime.fromMillisecondsSinceEpoch(
            (item.datetime?.toInt() ?? 0) * 1000,
          ),
          imageUrl: item.image,
          symbols: (item.related ?? '')
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList(),
        );
      }).toList();
    } else {
      if (response.statusCode == 401) {
        throw ConfigurationException(
          'Invalid Finnhub API key. Please check your key in Settings.',
          code: 'INVALID_API_KEY',
        );
      }
      throw Exception('Failed to fetch market news: ${response.statusCode}');
    }
  }
}

class NoApiKeyNewsAdapter implements NewsAdapter {
  @override
  Future<List<NewsArticle>> fetchNews({
    required List<String> symbols,
    DateTime? fromDate,
    int limit = 50,
  }) async {
    throw ConfigurationException(
      'Finnhub API key not configured. Please add it in Settings -> API Configuration.',
      code: 'MISSING_API_KEY',
    );
  }

  @override
  Future<List<NewsArticle>> fetchMarketNews({
    required String category,
    int limit = 50,
  }) async {
    throw ConfigurationException(
      'Finnhub API key not configured. Please add it in Settings -> API Configuration.',
      code: 'MISSING_API_KEY',
    );
  }
}

class NewsService {
  NewsService({
    required NewsAdapter adapter,
    required InstrumentDao instrumentDao,
    required LlmService llmService,
    required Ref ref,
  }) : _adapter = adapter,
       _instrumentDao = instrumentDao,
       _llmService = llmService,
       _ref = ref;
  final NewsAdapter _adapter;
  final InstrumentDao _instrumentDao;
  final LlmService _llmService;
  final Ref _ref;

  Future<List<NewsArticle>> getNewsForHoldings({
    int limitPerHolding = 10,
    DateTime? fromDate,
  }) async {
    if (_adapter is NoApiKeyNewsAdapter) {
      // Throw immediately to avoid unnecessary database queries
      await _adapter.fetchMarketNews(category: 'general');
    }

    final holdings = await _instrumentDao.getAll();
    final symbols = holdings
        .map((h) => h.symbol)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toList();

    if (symbols.isEmpty) {
      return await _adapter.fetchMarketNews(
        category: 'general',
        limit: limitPerHolding * 3,
      );
    }

    final futures = symbols.take(5).map((symbol) async {
      try {
        return await _adapter.fetchNews(
          symbols: [symbol],
          fromDate: fromDate,
          limit: limitPerHolding,
        );
      } catch (e, stackTrace) {
        if (e is ConfigurationException) rethrow;

        // Log error but continue with other symbols for non-config errors
        errorHandler.handleError(
          e,
          stackTrace: stackTrace,
          context: 'fetching news for $symbol',
        );
        return <NewsArticle>[];
      }
    });

    final results = await Future.wait(futures);
    final allNews = results.expand((news) => news).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    return allNews.take(limitPerHolding * 3).toList();
  }

  Future<List<NewsArticle>> getMarketNews({
    String category = 'general',
    int limit = 50,
  }) async {
    return await _adapter.fetchMarketNews(category: category, limit: limit);
  }

  Future<List<NewsArticle>> searchNews({
    required String query,
    int limit = 50,
  }) async {
    // Filter existing news for low-latency search
    final allNews = await getMarketNews(limit: 100);
    return allNews
        .where(
          (article) =>
              article.title.toLowerCase().contains(query.toLowerCase()) ||
              article.description.toLowerCase().contains(query.toLowerCase()),
        )
        .take(limit)
        .toList();
  }

  Future<Map<String, dynamic>> getNewsSummary({
    required List<NewsArticle> articles,
    int summaryLength = 3,
  }) async {
    // Group by sentiment
    final positive = articles
        .where((a) => (a.sentimentScore ?? 0) > 0.2)
        .length;
    final negative = articles
        .where((a) => (a.sentimentScore ?? 0) < -0.2)
        .length;
    final neutral = articles.length - positive - negative;

    // Get top symbols mentioned
    final symbolCount = <String, int>{};
    for (final article in articles) {
      for (final symbol in article.symbols) {
        symbolCount[symbol] = (symbolCount[symbol] ?? 0) + 1;
      }
    }

    final topSymbols = symbolCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalArticles': articles.length,
      'sentiment': {
        'positive': positive,
        'negative': negative,
        'neutral': neutral,
        'overall': articles.isEmpty
            ? 0.0
            : articles
                      .map((a) => a.sentimentScore ?? 0)
                      .fold(0.0, (sum, score) => sum + score) /
                  articles.length,
      },
      'topSymbols': topSymbols
          .take(5)
          .map((e) => {'symbol': e.key, 'count': e.value})
          .toList(),
      'timeRange': {
        'oldest': articles.lastOrNull?.publishedAt.toIso8601String(),
        'newest': articles.firstOrNull?.publishedAt.toIso8601String(),
      },
      'aiSummary': await _generateAiSummary(articles),
    };
  }

  Future<String> _generateAiSummary(List<NewsArticle> articles) async {
    if (articles.isEmpty) return 'No news available for summary.';

    final provider = _ref.read(activeLlmProvider);
    if (provider == null) {
      return 'AI Summary requires an LLM provider to be configured.';
    }

    final newsText = articles
        .take(5)
        .map((a) => '- ${a.title}: ${a.description}')
        .join('\n');
    final prompt =
        'Summarize the following market news in 2-3 sentences, highlighting potential impacts on a portfolio:\n\n$newsText';

    try {
      return await _llmService.chatCompletion(
        provider: provider,
        prompt: prompt,
        task: LlmTask.newsSummary,
      );
    } catch (e, stack) {
      errorHandler.handleError(
        e,
        context: 'News AI Summary Error',
        stackTrace: stack,
      );
      if (e is WealthLensException && e.isSilent) {
        return 'AI Summary unavailable: configuration required.';
      }
      return 'Failed to generate AI summary: $e';
    }
  }
}

class FinnhubApiKeyNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() async {
    final dao = ref.read(settingDaoProvider);
    return await dao.getValue('finnhub_api_key');
  }

  Future<void> updateKey(String? value) async {
    final trimmedValue = value?.trim();
    final dao = ref.read(settingDaoProvider);

    if (trimmedValue != null && trimmedValue.isNotEmpty) {
      await dao.setValue('finnhub_api_key', trimmedValue);
      state = AsyncValue.data(trimmedValue);
    } else {
      await dao.delete('finnhub_api_key');
      state = const AsyncValue.data(null);
    }
  }
}

final finnhubApiKeyProvider =
    AsyncNotifierProvider<FinnhubApiKeyNotifier, String?>(
      FinnhubApiKeyNotifier.new,
    );

final newsAdapterProvider = Provider<NewsAdapter>((ref) {
  final apiKeyAsync = ref.watch(finnhubApiKeyProvider);

  return apiKeyAsync.maybeWhen(
    data: (apiKey) => (apiKey != null && apiKey.isNotEmpty)
        ? FinnhubNewsAdapter(apiKey: apiKey)
        : NoApiKeyNewsAdapter(),
    orElse: NoApiKeyNewsAdapter.new,
  );
});

final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService(
    adapter: ref.watch(newsAdapterProvider),
    instrumentDao: ref.watch(instrumentDaoProvider),
    llmService: ref.watch(llmServiceProvider),
    ref: ref,
  );
});

class NewsCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'general';
  @override
  set state(String value) => super.state = value;
}

final newsCategoryProvider = NotifierProvider<NewsCategoryNotifier, String>(
  NewsCategoryNotifier.new,
);

class NewsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String value) => super.state = value;
}

final newsSearchProvider = NotifierProvider<NewsSearchNotifier, String>(
  NewsSearchNotifier.new,
);

final newsFeedProvider = FutureProvider<Map<String, List<NewsArticle>>>((
  ref,
) async {
  final searchQuery = ref.watch<String>(newsSearchProvider);
  final selectedCategory = ref.watch<String>(newsCategoryProvider);

  final apiKeyAsync = ref.watch(finnhubApiKeyProvider);

  // Fast path: if the key is already loaded and empty, throw immediately without awaiting future
  if (apiKeyAsync.hasValue &&
      (apiKeyAsync.value == null || apiKeyAsync.value!.trim().isEmpty)) {
    throw ConfigurationException(
      'Finnhub API key not configured. Please add it in Settings -> API Configuration.',
      code: 'MISSING_API_KEY',
    );
  }

  // Wait for API key to be loaded from database if still loading
  final apiKey = await ref.watch(finnhubApiKeyProvider.future);
  if (apiKey == null || apiKey.trim().isEmpty) {
    throw ConfigurationException(
      'Finnhub API key not configured. Please add it in Settings -> API Configuration.',
      code: 'MISSING_API_KEY',
    );
  }

  final service = ref.watch(newsServiceProvider);

  if (searchQuery.isNotEmpty) {
    final searchResults = await service.searchNews(query: searchQuery);
    return {'market': searchResults, 'holdings': []};
  } else if (selectedCategory == 'holdings') {
    final holdingNews = await service.getNewsForHoldings();
    return {'market': [], 'holdings': holdingNews};
  } else {
    // Watch holdings to ensure news refresh when portfolio changes
    ref.watch(holdingsWithInstrumentsProvider);

    final results = await Future.wait([
      service.getMarketNews(category: selectedCategory),
      service.getNewsForHoldings(),
    ]);

    return {'market': results[0], 'holdings': results[1]};
  }
});

final newsSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, List<NewsArticle>>((
      ref,
      articles,
    ) async {
      final service = ref.watch(newsServiceProvider);
      return service.getNewsSummary(articles: articles);
    });
