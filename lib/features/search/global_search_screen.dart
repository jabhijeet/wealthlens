import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/db/database.dart';
import '../../data/db/daos.dart';
import '../../core/theme.dart';
import '../holdings/models/holding_with_instrument.dart';
import '../holdings/widgets/instrument_picker.dart' show CreateInstrumentDialog;

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';
  List<dynamic> _onlineResults = [];
  bool _isSearchingOnline = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(_focusNode.requestFocus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchOnline(value);
    });
  }

  Future<void> _searchOnline(String query) async {
    if (query.trim().length < 2) {
      if (mounted) {
        setState(() {
          _onlineResults = [];
          _isSearchingOnline = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isSearchingOnline = true);
    }

    try {
      final url = Uri.parse(
        'https://query2.finance.yahoo.com/v1/finance/search?q=${Uri.encodeComponent(query)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _onlineResults = data['quotes'] as List<dynamic>? ?? [];
            _isSearchingOnline = false;
          });
        }
      } else {
        if (mounted) setState(() => _isSearchingOnline = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSearchingOnline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allHoldingsAsync = ref.watch(holdingsWithInstrumentsProvider);

    return Scaffold(
      backgroundColor: isDark ? WealthColors.surfaceDark : WealthColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: GoogleFonts.inter(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search holdings & market...',
            border: InputBorder.none,
            hintStyle: GoogleFonts.inter(
              color: WealthColors.textMuted.withValues(alpha: 0.5),
            ),
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: _searchQuery.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: WealthColors.textMuted.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for your holdings or explore the market',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: WealthColors.textMuted,
                        ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                allHoldingsAsync.when(
                  data: (holdings) {
                    final filteredHoldings = holdings.where((h) {
                      final nameMatch = h.instrument.name.toLowerCase().contains(_searchQuery.toLowerCase());
                      final symbolMatch = h.instrument.symbol?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
                      return nameMatch || symbolMatch;
                    }).toList();

                    if (filteredHoldings.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == 0) {
                            return _buildSectionHeader('Your Holdings');
                          }
                          final holding = filteredHoldings[index - 1];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: WealthColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: WealthColors.primary, size: 20),
                            ),
                            title: Text(holding.instrument.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${holding.instrument.symbol ?? 'No Symbol'} • Qty: ${holding.holding.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            onTap: () => context.push('/holdings/${holding.holding.id}'),
                          );
                        },
                        childCount: filteredHoldings.length + 1,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                if (_onlineResults.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return _buildSectionHeader('Market Results');
                        }
                        final result = _onlineResults[index - 1] as Map<String, dynamic>;
                        final symbol = result['symbol']?.toString() ?? '';
                        final shortname = result['shortname']?.toString() ?? result['longname']?.toString() ?? 'Unknown';
                        final typeDisp = result['typeDisp']?.toString() ?? '';
                        final exchDisp = result['exchDisp']?.toString() ?? '';

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: WealthColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.public_rounded, color: WealthColors.success, size: 20),
                          ),
                          title: Text(shortname, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('$symbol • $typeDisp • $exchDisp', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: const Icon(Icons.add_circle_outline_rounded, color: WealthColors.primary),
                          onTap: () {
                            _createAndAddHolding(context, shortname, symbol, typeDisp);
                          },
                        );
                      },
                      childCount: _onlineResults.length + 1,
                    ),
                  ),

                if (_isSearchingOnline)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: WealthColors.textMuted,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  AssetClass _mapYahooTypeToAssetClass(String typeDisp) {
    final t = typeDisp.toLowerCase();
    if (t == 'equity' || t == 'stock') return AssetClass.equity;
    if (t == 'etf') return AssetClass.equity;
    if (t == 'mutualfund') return AssetClass.mutualFund;
    if (t == 'cryptocurrency') return AssetClass.cryptoSpot;
    return AssetClass.other;
  }

  Country _mapYahooSuffixToCountry(String symbol) {
    if (symbol.endsWith('.NS') || symbol.endsWith('.BO')) return Country.india;
    if (symbol.endsWith('.L')) return Country.uk;
    if (symbol.endsWith('.SI')) return Country.singapore;
    return Country.usa;
  }

  void _createAndAddHolding(BuildContext context, String name, String symbol, String typeDisp) {
    showDialog<void>(
      context: context,
      builder: (context) => CreateInstrumentDialog(
        initialName: name,
        initialSymbol: symbol,
        initialAssetClass: _mapYahooTypeToAssetClass(typeDisp),
        initialCountry: _mapYahooSuffixToCountry(symbol),
        onCreated: (instrument) {
          Navigator.pop(context); // Close dialog
          context.push('/holdings/new', extra: instrument);
        },
      ),
    );
  }
}

// Provider to get all holdings with instruments
final holdingsWithInstrumentsProvider = FutureProvider<List<HoldingWithInstrument>>((ref) async {
  final holdingDao = ref.read(holdingDaoProvider);
  final allHoldings = await holdingDao.getAllWithInstruments();
  return allHoldings;
});
