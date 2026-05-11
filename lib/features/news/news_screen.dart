import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../services/news/news_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/theme.dart';
import '../../widgets/llm_status_box.dart';
import '../../services/logging/error_handler.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  String? _filterCountry;
  String? _filterCurrency;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refresh() async {
    return ref.refresh(newsFeedProvider.future);
  }


  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'holdings': return WealthColors.gold;
      case 'general': return WealthColors.primary;
      case 'forex': return WealthColors.success;
      case 'crypto': return WealthColors.crypto;
      case 'merger': return WealthColors.accent;
      case 'earnings': return WealthColors.equity;
      default: return WealthColors.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCategory = ref.watch(newsCategoryProvider);
    final searchQuery = ref.watch(newsSearchProvider);
    final newsAsync = ref.watch(newsFeedProvider);

    final categories = [
      'holdings',
      'general',
      'forex',
      'crypto',
      'merger',
      'earnings',
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'News',
                        style: GoogleFonts.outfit(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const LlmStatusBox(),
                  ],
                ),
              ),
            ),
          ),

          // ── Category Chips (Sticky) ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 58,
              maxHeight: 58,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = selectedCategory == cat;
                      final color = _getCategoryColor(cat);

                      return Material(
                        color: isSelected ? color : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () {
                            ref.read(newsCategoryProvider.notifier).state = cat;
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Center(
                              child: Text(
                                cat == 'holdings' ? 'MY HOLDINGS' : cat.toUpperCase(),
                                style: GoogleFonts.sora(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isSelected ? Colors.white : color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // ── Search Bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search news...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => ref.read(newsSearchProvider.notifier).state = '',
                        )
                      : null,
                ),
                onChanged: (val) => ref.read(newsSearchProvider.notifier).state = val,
                onSubmitted: (val) => ref.read(newsSearchProvider.notifier).state = val,
              ),
            ),
          ),

          // ── Country and Currency Filters ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? WealthColors.cardDark : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _filterCountry,
                          hint: Text(
                            'All Countries',
                            style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          items: [
                            DropdownMenuItem<String?>(
                              child: Text('All Countries', style: GoogleFonts.sora(fontSize: 10)),
                            ),
                            // Basic static options for news since we don't know all article origins natively
                            ...['US', 'UK', 'India', 'China', 'Europe'].map((c) => DropdownMenuItem<String?>(
                                  value: c,
                                  child: Text(c, style: GoogleFonts.sora(fontSize: 10)),
                                )),
                          ],
                          onChanged: (val) => setState(() => _filterCountry = val),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? WealthColors.cardDark : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _filterCurrency,
                          hint: Text(
                            'All Currencies',
                            style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          items: [
                            DropdownMenuItem<String?>(
                              child: Text('All Currencies', style: GoogleFonts.sora(fontSize: 10)),
                            ),
                            ...['USD', 'GBP', 'INR', 'EUR', 'CNY'].map((c) => DropdownMenuItem<String?>(
                                  value: c,
                                  child: Text(c, style: GoogleFonts.sora(fontSize: 10)),
                                )),
                          ],
                          onChanged: (val) => setState(() => _filterCurrency = val),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Fast-path Configuration Check ──
          Consumer(
            builder: (context, ref, child) {
              final apiKeyAsync = ref.watch(finnhubApiKeyProvider);
              if (apiKeyAsync.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: WealthLoadingIndicator()),
                );
              }
              
              if (apiKeyAsync.hasValue && (apiKeyAsync.value == null || apiKeyAsync.value!.trim().isEmpty)) {
                return SliverFillRemaining(
                  child: _buildErrorStateWidget(
                    ConfigurationException(
                      'Finnhub API key not configured. Please add it in Settings -> API Configuration.',
                      code: 'MISSING_API_KEY',
                    ),
                  ),
                );
              }
              
              // ── News Feed ──
              return newsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: WealthLoadingIndicator()),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: _buildErrorStateWidget(err),
                ),
                data: (data) {
                  var articles = data['market'] ?? [];
                  var holdingArticles = data['holdings'] ?? [];

                  // Apply Filters (Simple text matching since news API doesn't provide strict country/currency metadata)
                  bool passFilter(NewsArticle article) {
                    final text = '${article.title} ${article.description}'.toLowerCase();
                    if (_filterCountry != null && !text.contains(_filterCountry!.toLowerCase())) {
                      return false;
                    }
                    if (_filterCurrency != null && !text.contains(_filterCurrency!.toLowerCase())) {
                      return false;
                    }
                    return true;
                  }

                  if (_filterCountry != null || _filterCurrency != null) {
                    articles = articles.where(passFilter).toList();
                    holdingArticles = holdingArticles.where(passFilter).toList();
                  }

                  if (articles.isEmpty && holdingArticles.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.newspaper_rounded, size: 48, color: WealthColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No news found', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // Summary Section
                      if (searchQuery.isEmpty && articles.isNotEmpty)
                        Consumer(
                          builder: (context, ref, child) {
                            final summaryAsync = ref.watch(newsSummaryProvider(articles));
                            return summaryAsync.when(
                              data: (summary) => Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: _SummaryCard(
                                  summary: summary,
                                  articleCount: articles.length,
                                  isDark: isDark,
                                ),
                              ).animate().fadeIn(),
                              loading: () => const SizedBox.shrink(),
                              error: (err, stack) => const SizedBox.shrink(),
                            );
                          },
                        ),

                      // Holding Articles
                      if (holdingArticles.isNotEmpty && searchQuery.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: _buildSectionHeader('Your Holdings', Icons.account_balance_wallet_rounded),
                        ),
                        ...holdingArticles.map((article) => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                              child: _NewsCard(
                                article: article,
                                isDark: isDark,
                                onTap: () => _openArticle(article),
                              ),
                            ).animate().fadeIn()),
                      ],

                      // Market Articles
                      if (articles.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: _buildSectionHeader(
                            searchQuery.isNotEmpty ? 'Search Results' : 'Market News',
                            Icons.public_rounded,
                          ),
                        ),
                        ...articles.map((article) => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                              child: _NewsCard(
                                article: article,
                                isDark: isDark,
                                onTap: () => _openArticle(article),
                              ),
                            ).animate().fadeIn()),
                      ],
                      
                      const SizedBox(height: 40),
                    ]),
                  );
                },
              );
            },
          ),
          // End of CustomScrollView slivers
        ],
      ),
    ),
  );
}

  Widget _buildErrorStateWidget(Object err) {
    final error = err.toString();
    final lowercaseError = error.toLowerCase();
    
    final isConfigError = err is ConfigurationException || 
                         lowercaseError.contains('not configured') || 
                         lowercaseError.contains('missing_api_key') ||
                         lowercaseError.contains('finnhub');
                         
    final isAuthError = lowercaseError.contains('401') || 
                       lowercaseError.contains('invalid') || 
                       lowercaseError.contains('api key');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isConfigError || isAuthError ? Colors.orange : Colors.red).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConfigError || isAuthError ? Icons.key_off_rounded : Icons.error_outline_rounded,
                size: 48,
                color: isConfigError || isAuthError ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isConfigError ? 'API Key Required' : 'News Error',
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                color: WealthColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (isConfigError || isAuthError) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/settings/llm-providers'),
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Go to Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showFinnhubInfo,
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('How to get a key?'),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: WealthColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _showFinnhubInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Get Finnhub Key', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finnhub provides the market news and stock prices for WealthLens. To get your free API key:',
              style: GoogleFonts.sora(),
            ),
            const SizedBox(height: 16),
            Text('1. Visit finnhub.io', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
            Text('2. Create a free account', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
            Text('3. Copy your API Key from the dashboard', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://finnhub.io/dashboard')),
              child: Text(
                'Visit Finnhub Dashboard ↗',
                style: GoogleFonts.sora(
                  color: WealthColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _openArticle(NewsArticle article) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: WealthColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (article.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        article.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SelectableText(
                    article.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: WealthColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.source,
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: WealthColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        article.publishedAt.toLocal().toString().split(' ')[0],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SelectableText(
                    article.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                  if (article.symbols.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Related Symbols', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: article.symbols.map((s) {
                        return Chip(
                          label: Text(s),
                          backgroundColor: WealthColors.primary.withValues(alpha: 0.08),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final uri = Uri.tryParse(article.url);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: const Text('Read Full Article'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.articleCount,
    required this.isDark,
  });
  final Map<String, dynamic> summary;
  final int articleCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final sentiment = Map<String, dynamic>.from(summary['sentiment'] as Map? ?? {});
    final topSymbols = List<dynamic>.from(summary['topSymbols'] as List? ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? WealthColors.darkCardGradient : null,
        color: isDark ? null : WealthColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: WealthColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Market Pulse', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(
                '$articleCount articles',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SentimentChip(label: 'Positive', value: sentiment['positive'].toString(), color: WealthColors.success),
              const SizedBox(width: 12),
              _SentimentChip(label: 'Neutral', value: sentiment['neutral'].toString(), color: WealthColors.primary),
              const SizedBox(width: 12),
              _SentimentChip(label: 'Negative', value: sentiment['negative'].toString(), color: WealthColors.error),
            ],
          ),
          if (topSymbols.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: topSymbols.take(5).map((symbol) {
                final symbolMap = Map<String, dynamic>.from(symbol as Map? ?? {});
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: WealthColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    symbolMap['symbol'] as String,
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WealthColors.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SentimentChip extends StatelessWidget {
  const _SentimentChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.sora(fontSize: 10, color: WealthColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article, required this.isDark, required this.onTap});
  final NewsArticle article;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sentimentScore = article.sentimentScore ?? 0;
    final sentimentColor = sentimentScore > 0.2
        ? WealthColors.success
        : sentimentScore < -0.2
            ? WealthColors.error
            : WealthColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        article.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: WealthColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.article_rounded, color: WealthColors.primary, size: 20),
                        ),
                      ),
                    ),
                  if (article.imageUrl != null) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? WealthColors.textLight : WealthColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          article.description,
                          style: GoogleFonts.sora(
                            fontSize: 10,
                            color: WealthColors.textMuted,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: WealthColors.textMuted.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article.source,
                              style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (article.symbols.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: WealthColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                article.symbols.first,
                                style: GoogleFonts.sora(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: WealthColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    sentimentScore > 0.2
                        ? Icons.trending_up_rounded
                        : sentimentScore < -0.2
                            ? Icons.trending_down_rounded
                            : Icons.trending_flat_rounded,
                    color: sentimentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    article.publishedAt.toLocal().toString().split(' ')[0],
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
