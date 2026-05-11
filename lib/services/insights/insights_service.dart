import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../llm/llm_provider.dart';
import '../../llm/llm_service.dart';
import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../news/news_service.dart';
import '../logging/error_handler.dart';
import '../../features/holdings/models/holding_with_instrument.dart';
import '../../models/insights.dart';


class InsightsService {
  InsightsService({
    required HoldingDao holdingDao,
    required InstrumentDao instrumentDao,
    required TransactionDao transactionDao,
    required NewsService newsService,
    required LlmService llmService,
    required FundamentalSnapshotDao fundamentalDao,
  }) : _holdingDao = holdingDao,
       _instrumentDao = instrumentDao,
       _transactionDao = transactionDao,
       _newsService = newsService,
       _llmService = llmService,
       _fundamentalDao = fundamentalDao;
  final HoldingDao _holdingDao;
  final InstrumentDao _instrumentDao;
  final TransactionDao _transactionDao;
  final NewsService _newsService;
  final LlmService _llmService;
  final FundamentalSnapshotDao _fundamentalDao;

  Future<List<PortfolioInsight>> generateInsights({
    LlmProvider? provider,
    bool includeNewsAnalysis = true,
  }) async {
    final insights = <PortfolioInsight>[];

    // Get portfolio data
    final holdings = await _holdingDao.getAll();
    final instruments = await _instrumentDao.getAll();
    final recentTransactions = await _transactionDao.getRecent();

    if (holdings.isEmpty) {
      insights.add(
        PortfolioInsight(
          id: 'no-holdings',
          title: 'No Holdings Found',
          description:
              'Start by adding your first holding to get personalized insights.',
          category: 'opportunity',
          generatedAt: DateTime.now(),
          confidence: 1.0,
        ),
      );
      return insights;
    }

    // Generate basic portfolio insights
    insights
      ..addAll(
        await _generatePortfolioAnalysis(
          holdings: holdings,
          instruments: instruments,
        ),
      )
      // Generate allocation insights
      ..addAll(
        await _generateAllocationInsights(
          holdings: holdings,
          instruments: instruments,
        ),
      )
      // Generate performance insights
      ..addAll(
        await _generatePerformanceInsights(
          holdings: holdings,
          transactions: recentTransactions,
        ),
      )
      // Generate fundamental insights
      ..addAll(
        await _generateFundamentalInsights(
          holdings: holdings,
          instruments: instruments,
        ),
      );
    // Generate news-based insights if enabled
    if (includeNewsAnalysis) {
      insights.addAll(
        await _generateNewsInsights(
          holdings: holdings,
          instruments: instruments,
          provider: provider,
        ),
      );
    }

    // Sort by confidence and category
    insights.sort((a, b) {
      final categoryOrder = {
        'warning': 0,
        'opportunity': 1,
        'risk': 2,
        'performance': 3,
        'allocation': 4,
      };
      final aOrder = categoryOrder[a.category] ?? 5;
      final bOrder = categoryOrder[b.category] ?? 5;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return b.confidence.compareTo(a.confidence);
    });

    return insights;
  }

  Future<List<PortfolioInsight>> _generatePortfolioAnalysis({
    required List<Holding> holdings,
    required List<Instrument> instruments,
  }) async {
    final insights = <PortfolioInsight>[];

    // Calculate total value
    double totalValue = 0;
    final currencyValues = <String, double>{};
    final assetClassCount = <String, int>{};
    final countryExposure = <String, double>{};

    for (final holding in holdings) {
      final qty = double.tryParse(holding.quantity) ?? 0.0;
      final value = qty * holding.avgCostMinor / 100;
      totalValue += value;

      final instrument = instruments.firstWhereOrNull(
        (i) => i.id == holding.instrumentId,
      );
      if (instrument != null) {
        currencyValues[instrument.currency] =
            (currencyValues[instrument.currency] ?? 0) + value;
        assetClassCount[instrument.assetClass.name] =
            (assetClassCount[instrument.assetClass.name] ?? 0) + 1;
        countryExposure[instrument.country.name] =
            (countryExposure[instrument.country.name] ?? 0) + value;
      }
    }

    // Portfolio size insight
    if (totalValue > 0) {
      insights.add(
        PortfolioInsight(
          id: 'portfolio-size',
          title: 'Portfolio Value',
          description:
              'Your portfolio is valued at \$${totalValue.toStringAsFixed(2)} across ${holdings.length} holdings.',
          category: 'performance',
          generatedAt: DateTime.now(),
          metadata: {'totalValue': totalValue, 'holdingCount': holdings.length},
          confidence: 1.0,
        ),
      );
    }

    // Currency diversification insight
    if (currencyValues.length > 1) {
      insights.add(
        PortfolioInsight(
          id: 'currency-diversification',
          title: 'Multi-Currency Portfolio',
          description:
              'Your portfolio spans ${currencyValues.length} currencies: ${currencyValues.keys.join(', ')}.',
          category: 'allocation',
          generatedAt: DateTime.now(),
          metadata: {'currencies': currencyValues.keys.toList()},
          confidence: 0.9,
        ),
      );
    } else if (currencyValues.length == 1) {
      insights.add(
        PortfolioInsight(
          id: 'single-currency',
          title: 'Single Currency Exposure',
          description:
              'Your portfolio is entirely in ${currencyValues.keys.first}. Consider diversifying across currencies.',
          category: 'risk',
          generatedAt: DateTime.now(),
        ),
      );
    }

    // Asset class diversification
    if (assetClassCount.length >= 3) {
      insights.add(
        PortfolioInsight(
          id: 'good-diversification',
          title: 'Well-Diversified Portfolio',
          description:
              'Your portfolio spans ${assetClassCount.length} different asset classes.',
          category: 'allocation',
          generatedAt: DateTime.now(),
          metadata: {'assetClasses': assetClassCount.keys.toList()},
          confidence: 0.85,
        ),
      );
    } else if (assetClassCount.length == 1) {
      insights.add(
        PortfolioInsight(
          id: 'single-asset-class',
          title: 'Concentrated in Single Asset Class',
          description:
              'Your portfolio is concentrated in ${assetClassCount.keys.first}. Consider diversifying across different asset types.',
          category: 'risk',
          generatedAt: DateTime.now(),
          confidence: 0.9,
        ),
      );
    }

    // Country exposure
    final topCountry = countryExposure.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topCountry.isNotEmpty && topCountry.first.value / totalValue > 0.7) {
      insights.add(
        PortfolioInsight(
          id: 'country-concentration',
          title: 'High Country Concentration',
          description:
              '${((topCountry.first.value / totalValue) * 100).toStringAsFixed(1)}% of your portfolio is exposed to ${topCountry.first.key}.',
          category: 'risk',
          generatedAt: DateTime.now(),
        ),
      );
    }

    return insights;
  }

  Future<List<PortfolioInsight>> _generateAllocationInsights({
    required List<Holding> holdings,
    required List<Instrument> instruments,
  }) async {
    final insights = <PortfolioInsight>[];

    // Calculate allocation percentages
    final assetClassAllocation = <String, double>{};
    double totalValue = 0;

    for (final holding in holdings) {
      final qty = double.tryParse(holding.quantity) ?? 0.0;
      final value = qty * holding.avgCostMinor / 100;
      totalValue += value;

      final instrument = instruments.firstWhereOrNull(
        (i) => i.id == holding.instrumentId,
      );
      if (instrument != null) {
        assetClassAllocation[instrument.assetClass.name] =
            (assetClassAllocation[instrument.assetClass.name] ?? 0) + value;
      }
    }

    if (totalValue > 0) {
      // Check for over-concentration
      for (final entry in assetClassAllocation.entries) {
        final percentage = (entry.value / totalValue) * 100;
        if (percentage > 40) {
          insights.add(
            PortfolioInsight(
              id: 'over-concentration-${entry.key}',
              title:
                  'High ${entry.key.replaceAll('_', ' ').toUpperCase()} Allocation',
              description:
                  '${percentage.toStringAsFixed(1)}% of your portfolio is in ${entry.key.replaceAll('_', ' ')}. Consider rebalancing.',
              category: 'warning',
              generatedAt: DateTime.now(),
              metadata: {'assetClass': entry.key, 'percentage': percentage},
              confidence: 0.85,
            ),
          );
        }
      }

      // Check for missing asset classes
      final commonAssetClasses = {
        'equity',
        'mutual_fund',
        'bond',
        'crypto',
        'real_estate',
      };
      final missingClasses = commonAssetClasses
          .where((cls) => !assetClassAllocation.containsKey(cls))
          .toList();

      if (missingClasses.isNotEmpty) {
        insights.add(
          PortfolioInsight(
            id: 'missing-asset-classes',
            title: 'Opportunity for Diversification',
            description:
                'Consider adding ${missingClasses.map((c) => c.replaceAll('_', ' ')).join(', ')} to your portfolio for better diversification.',
            category: 'opportunity',
            generatedAt: DateTime.now(),
            metadata: {'missingClasses': missingClasses},
            confidence: 0.7,
          ),
        );
      }
    }

    return insights;
  }

  Future<List<PortfolioInsight>> _generatePerformanceInsights({
    required List<Holding> holdings,
    required List<Transaction> transactions,
  }) async {
    final insights = <PortfolioInsight>[];

    if (transactions.isEmpty) {
      return insights;
    }

    // Analyze transaction patterns
    final buyCount = transactions
        .where((t) => t.type == TransactionType.buy)
        .length;
    final sellCount = transactions
        .where((t) => t.type == TransactionType.sell)
        .length;
    final totalTransactions = transactions.length;

    if (sellCount == 0 || buyCount > sellCount * 2) {
      insights.add(
        PortfolioInsight(
          id: 'accumulation-phase',
          title: 'Accumulation Phase',
          description:
              "You're in an accumulation phase with $buyCount buys vs $sellCount sells. This suggests a long-term investment strategy.",
          category: 'performance',
          generatedAt: DateTime.now(),
          metadata: {
            'buyCount': buyCount,
            'sellCount': sellCount,
            'ratio': sellCount > 0 ? buyCount / sellCount : null,
          },
        ),
      );
    }

    // Check transaction frequency
    if (totalTransactions > 20) {
      final firstDate = transactions.last.date;
      final lastDate = transactions.first.date;
      final days = lastDate.difference(firstDate).inDays;
      final transactionsPerMonth = totalTransactions / (days / 30);

      if (transactionsPerMonth > 10) {
        insights.add(
          PortfolioInsight(
            id: 'high-frequency-trading',
            title: 'Active Trading Pattern',
            description:
                "You're averaging ${transactionsPerMonth.toStringAsFixed(1)} transactions per month. Consider if this aligns with your investment strategy.",
            category: 'warning',
            generatedAt: DateTime.now(),
            metadata: {
              'transactionsPerMonth': transactionsPerMonth,
              'totalTransactions': totalTransactions,
            },
            confidence: 0.75,
          ),
        );
      }
    }

    return insights;
  }

  Future<List<PortfolioInsight>> _generateFundamentalInsights({
    required List<Holding> holdings,
    required List<Instrument> instruments,
  }) async {
    final insights = <PortfolioInsight>[];

    for (final holding in holdings) {
      final instrument = instruments.firstWhereOrNull(
        (i) => i.id == holding.instrumentId,
      );
      if (instrument == null || instrument.assetClass != AssetClass.equity) {
        continue;
      }

      final fundamental = await _fundamentalDao.getLatest(instrument.id);
      if (fundamental == null) continue;

      // 1. P/E Ratio Analysis
      final pe = double.tryParse(fundamental.peRatio ?? '');
      if (pe != null) {
        if (pe > 50) {
          insights.add(
            PortfolioInsight(
              id: 'high-pe-${instrument.id}',
              title: 'High Valuation: ${instrument.name}',
              description:
                  'The P/E ratio is ${pe.toStringAsFixed(1)}, which is relatively high. Monitor for potential overvaluation.',
              category: 'warning',
              generatedAt: DateTime.now(),
              metadata: {'symbol': instrument.symbol, 'pe': pe},
            ),
          );
        } else if (pe < 15 && pe > 0) {
          insights.add(
            PortfolioInsight(
              id: 'low-pe-${instrument.id}',
              title: 'Value Opportunity: ${instrument.name}',
              description:
                  'The P/E ratio is ${pe.toStringAsFixed(1)}, which might indicate a value opportunity.',
              category: 'opportunity',
              generatedAt: DateTime.now(),
              metadata: {'symbol': instrument.symbol, 'pe': pe},
              confidence: 0.7,
            ),
          );
        }
      }

      // 2. ROE Analysis
      final roe = double.tryParse(fundamental.roe ?? '');
      if (roe != null && roe > 20) {
        insights.add(
          PortfolioInsight(
            id: 'high-roe-${instrument.id}',
            title: 'High ROE: ${instrument.name}',
            description:
                'Excellent Return on Equity of ${roe.toStringAsFixed(1)}%. This indicates efficient capital use.',
            category: 'performance',
            generatedAt: DateTime.now(),
            metadata: {'symbol': instrument.symbol, 'roe': roe},
            confidence: 0.9,
          ),
        );
      }

      // 3. Debt to Equity Analysis
      final de = double.tryParse(fundamental.debtToEquity ?? '');
      if (de != null && de > 1.5) {
        insights.add(
          PortfolioInsight(
            id: 'high-debt-${instrument.id}',
            title: 'High Leverage Alert: ${instrument.name}',
            description:
                'The Debt-to-Equity ratio is ${de.toStringAsFixed(2)}. High leverage could increase financial risk.',
            category: 'risk',
            generatedAt: DateTime.now(),
            metadata: {'symbol': instrument.symbol, 'debtToEquity': de},
            confidence: 0.85,
          ),
        );
      }
    }

    return insights;
  }

  Future<List<PortfolioInsight>> _generateNewsInsights({
    required List<Holding> holdings,
    required List<Instrument> instruments,
    LlmProvider? provider,
  }) async {
    final insights = <PortfolioInsight>[];

    try {
      // Get news for holdings
      final news = await _newsService.getNewsForHoldings(limitPerHolding: 5);

      if (news.isEmpty) {
        return insights;
      }

      // Group news by sentiment
      final positiveNews = news.where((n) => (n.sentimentScore ?? 0) > 0.3);
      final negativeNews = news.where((n) => (n.sentimentScore ?? 0) < -0.3);

      if (positiveNews.isNotEmpty) {
        final symbols = positiveNews
            .expand((n) => n.symbols)
            .where(
              (s) => holdings.any((h) {
                final instrument = instruments.firstWhereOrNull(
                  (i) => i.id == h.instrumentId,
                );
                return instrument?.symbol == s;
              }),
            )
            .toSet()
            .take(3)
            .toList();

        if (symbols.isNotEmpty) {
          insights.add(
            PortfolioInsight(
              id: 'positive-news-exposure',
              title: 'Positive News Coverage',
              description:
                  '${symbols.join(', ')} ${symbols.length > 1 ? 'have' : 'has'} positive news coverage. Monitor for potential opportunities.',
              category: 'opportunity',
              generatedAt: DateTime.now(),
              metadata: {'symbols': symbols},
              confidence: 0.7,
            ),
          );
        }
      }

      if (negativeNews.isNotEmpty) {
        final symbols = negativeNews
            .expand((n) => n.symbols)
            .where(
              (s) => holdings.any((h) {
                final instrument = instruments.firstWhereOrNull(
                  (i) => i.id == h.instrumentId,
                );
                return instrument?.symbol == s;
              }),
            )
            .toSet()
            .take(3)
            .toList();

        if (symbols.isNotEmpty) {
          insights.add(
            PortfolioInsight(
              id: 'negative-news-exposure',
              title: 'Negative News Alert',
              description:
                  '${symbols.join(', ')} ${symbols.length > 1 ? 'have' : 'has'} negative news coverage. Consider reviewing your positions.',
              category: 'warning',
              generatedAt: DateTime.now(),
              metadata: {'symbols': symbols},
              confidence: 0.75,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      // Silently fail - news insights are optional
      errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'generating news insights',
      );
    }

    return insights;
  }

  Future<String> generateDetailedAnalysis({
    required List<PortfolioInsight> insights,
    LlmProvider? provider,
  }) async {
    if (provider != null) {
      try {
        final prompt =
            '''
Generate a comprehensive portfolio analysis based on the following insights:

${insights.map((i) => '- [${i.category}] ${i.title}: ${i.description}').join('\n')}

Provide key recommendations and summarize the portfolio's current state. Make the response professional and formatted.
''';
        return await _llmService.chatCompletion(
          provider: provider,
          prompt: prompt,
          task: LlmTask.insights,
        );
      } catch (e, stack) {
        errorHandler.handleError(e, context: 'Detailed Analysis LLM Error', stackTrace: stack);
        rethrow;
      }
    }

    return '''
Portfolio Analysis Summary:

Based on ${insights.length} insights generated for your portfolio:

${insights.take(5).map((i) => '• ${i.title}: ${i.description}').join('\n\n')}

Key Recommendations:
1. Review high-concentration positions
2. Consider diversifying across asset classes and currencies
3. Monitor news for your holdings
4. Rebalance periodically based on your investment goals

This analysis was generated on ${DateTime.now().toLocal().toString().split(' ')[0]}.
''';
  }
}

final insightsServiceProvider = Provider<InsightsService>((ref) {
  return InsightsService(
    holdingDao: ref.watch(holdingDaoProvider),
    instrumentDao: ref.watch(instrumentDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
    newsService: ref.watch(newsServiceProvider),
    llmService: ref.watch(llmServiceProvider),
    fundamentalDao: ref.watch(fundamentalSnapshotDaoProvider),
  );
});

final portfolioInsightsProvider = FutureProvider<List<PortfolioInsight>>((
  ref,
) async {
  // Watch holdings to ensure insights refresh when data changes
  ref.watch<AsyncValue<List<HoldingWithInstrument>>>(holdingsWithInstrumentsProvider);
  final service = ref.watch(insightsServiceProvider);
  return service.generateInsights();
});


class DetailedAnalysisNotifier extends Notifier<DetailedAnalysisState> {
  int? _lastHoldingCount;

  @override
  DetailedAnalysisState build() {
    // Listen to holdings to detect additions
    ref
      ..listen(holdingsWithInstrumentsProvider, (previous, next) {
        if (next.hasValue && next.value != null) {
          final currentCount = next.value!.length;

          // Only trigger if holdings count strictly increased
          if (_lastHoldingCount != null && currentCount > _lastHoldingCount!) {
            final insights = ref.read(portfolioInsightsProvider).value;
            if (insights != null && insights.isNotEmpty) {
              generate(insights, force: true);
            }
          }
          _lastHoldingCount = currentCount;
        }
      })
      ..listen(portfolioInsightsProvider, (previous, next) {
        if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
          if (state.analysis.isEmpty && !state.isGenerating) {
            generate(next.value!);
          }
        }
      }, fireImmediately: true);

    // Initialize _lastHoldingCount
    final holdings = ref.read(holdingsWithInstrumentsProvider).value;
    if (holdings != null) {
      _lastHoldingCount = holdings.length;
    }

    return DetailedAnalysisState();
  }

  Future<void> generate(List<PortfolioInsight> insights, {bool force = false}) async {
    if (state.isGenerating) return;
    if (!force && state.analysis.isNotEmpty && state.error == null) return;

    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      final service = ref.read(insightsServiceProvider);
      final provider = ref.read(activeLlmProvider);
      final analysis = await service.generateDetailedAnalysis(
        insights: insights,
        provider: provider,
      );

      state = DetailedAnalysisState(
        analysis: analysis,
        lastGenerated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }
}

final detailedAnalysisProvider =
    NotifierProvider<DetailedAnalysisNotifier, DetailedAnalysisState>(
      DetailedAnalysisNotifier.new,
    );
