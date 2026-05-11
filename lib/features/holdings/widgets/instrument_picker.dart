import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:google_fonts/google_fonts.dart';
import '../../../data/db/daos.dart';
import '../../../data/db/database.dart';

class InstrumentPicker extends ConsumerStatefulWidget {
  const InstrumentPicker({
    super.key,
    this.assetClass,
    required this.onSelected,
    this.onCreateCustom,
  });
  final AssetClass? assetClass;
  final void Function(Instrument) onSelected;
  final void Function({
    String? name,
    String? symbol,
    AssetClass? assetClass,
    Country? country,
  })? onCreateCustom;

  @override
  ConsumerState<InstrumentPicker> createState() => _InstrumentPickerState();
}

class _InstrumentPickerState extends ConsumerState<InstrumentPicker> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<dynamic> _onlineResults = [];
  bool _isSearchingOnline = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
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
    final instrumentsAsync = ref.watch(allInstrumentsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Instrument',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: instrumentsAsync.when(
            data: (instruments) {
              final filtered = instruments.where((i) {
                final matchesSearch =
                    i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (i.symbol?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false);
                final matchesClass =
                    widget.assetClass == null ||
                    i.assetClass == widget.assetClass;
                return matchesSearch && matchesClass;
              }).toList();

              final hasLocal = filtered.isNotEmpty;
              final hasOnline = _onlineResults.isNotEmpty;

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 32),
                itemCount:
                    1 + // The prominent "Create New" button at top
                    (hasLocal ? filtered.length + 1 : 0) +
                    (hasOnline ? _onlineResults.length + 1 : 0) +
                    (_isSearchingOnline ? 1 : 0),
                itemBuilder: (context, index) {
                  var currentIndex = 0;

                  // 1. Create New Custom Instrument Button (Prominent & At Top)
                  if (index == currentIndex) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: InkWell(
                        onTap: () {
                          if (widget.onCreateCustom != null) {
                            widget.onCreateCustom!(
                              name: _searchQuery.isNotEmpty ? _searchQuery : null,
                            );
                          } else {
                            _showCreateInstrumentDialog(
                              context,
                              prefilledName:
                                  _searchQuery.isNotEmpty ? _searchQuery : null,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF3A3A3C), const Color(0xFF1C1C1E)]
                                  : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                ),
                                child: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create Custom Instrument',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        letterSpacing: -0.5,
                                        color: isDark ? Colors.white : Colors.blue.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'Manually add an asset if not in our database'
                                          : 'Create "$_searchQuery" as a new asset',
                                      style: GoogleFonts.sora(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white70 : Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark ? Colors.white38 : Colors.blue.shade300,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  currentIndex++;

                  // 2. Local Instruments Section
                  if (hasLocal) {
                    if (index == currentIndex) {
                      return _buildSectionHeader('Your Instruments');
                    }
                    currentIndex++;

                    if (index < currentIndex + filtered.length) {
                      final instrument = filtered[index - currentIndex];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bookmark_added_rounded,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          instrument.name,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${instrument.symbol ?? 'No Symbol'} • ${instrument.assetClass.name.replaceAll('_', ' ').toUpperCase()}',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Text(
                          instrument.currency,
                          style: GoogleFonts.firaCode(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => widget.onSelected(instrument),
                      );
                    }
                    currentIndex += filtered.length;
                  }

                  // 3. Online Search Results Section
                  if (hasOnline) {
                    if (index == currentIndex) {
                      return _buildSectionHeader(
                        'Market Search (Yahoo Finance)',
                      );
                    }
                    currentIndex++;

                    if (index < currentIndex + _onlineResults.length) {
                      final result =
                          _onlineResults[index - currentIndex]
                              as Map<String, dynamic>;
                      final symbol = result['symbol']?.toString() ?? '';
                      final shortname =
                          result['shortname']?.toString() ??
                          result['longname']?.toString() ??
                          'Unknown';
                      final typeDisp = result['typeDisp']?.toString() ?? '';
                      final exchDisp = result['exchDisp']?.toString() ?? '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.public,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          shortname,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '$symbol • $typeDisp • $exchDisp',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.download_for_offline_rounded,
                          size: 22,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          if (widget.onCreateCustom != null) {
                            widget.onCreateCustom!(
                              name: shortname,
                              symbol: symbol,
                              assetClass: _mapYahooTypeToAssetClass(typeDisp),
                              country: _mapYahooSuffixToCountry(symbol),
                            );
                          } else {
                            _showCreateInstrumentDialog(
                              context,
                              prefilledName: shortname,
                              prefilledSymbol: symbol,
                              prefilledAssetClass: _mapYahooTypeToAssetClass(
                                typeDisp,
                              ),
                              prefilledCountry: _mapYahooSuffixToCountry(symbol),
                            );
                          }
                        },
                      );
                    }
                    currentIndex += _onlineResults.length;
                  }

                  if (_isSearchingOnline && index == currentIndex) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
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

  void _showCreateInstrumentDialog(
    BuildContext context, {
    String? prefilledName,
    String? prefilledSymbol,
    AssetClass? prefilledAssetClass,
    Country? prefilledCountry,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => CreateInstrumentDialog(
        initialAssetClass: prefilledAssetClass ?? widget.assetClass,
        initialName: prefilledName,
        initialSymbol: prefilledSymbol,
        initialCountry: prefilledCountry,
        onCreated: (instrument) {
          widget.onSelected(instrument);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class CreateInstrumentDialog extends ConsumerStatefulWidget {
  const CreateInstrumentDialog({
    super.key,
    this.initialAssetClass,
    this.initialName,
    this.initialSymbol,
    this.initialCountry,
    required this.onCreated,
  });
  final AssetClass? initialAssetClass;
  final String? initialName;
  final String? initialSymbol;
  final Country? initialCountry;
  final void Function(Instrument) onCreated;

  @override
  ConsumerState<CreateInstrumentDialog> createState() =>
      _CreateInstrumentDialogState();
}

class _CreateInstrumentDialogState
    extends ConsumerState<CreateInstrumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _isinController = TextEditingController();
  late AssetClass _assetClass;
  Country _country = Country.india;
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _assetClass = widget.initialAssetClass ?? AssetClass.equity;
    _country = widget.initialCountry ?? Country.india;

    if (widget.initialName != null) _nameController.text = widget.initialName!;
    if (widget.initialSymbol != null) {
      _symbolController.text = widget.initialSymbol!;
    }

    // Guess currency based on country
    if (_country == Country.india) {
      _currency = 'INR';
    } else if (_country == Country.usa) {
      _currency = 'USD';
    } else if (_country == Country.uk) {
      _currency = 'GBP';
    } else if (_country == Country.singapore) {
      _currency = 'SGD';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _isinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Instrument',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  required: true,
                  isDark: isDark,
                ),
                _buildTextField(
                  controller: _symbolController,
                  label: 'Symbol / Ticker',
                  isDark: isDark,
                ),
                _buildTextField(
                  controller: _isinController,
                  label: 'ISIN (Optional)',
                  isDark: isDark,
                ),
                _buildDropdown<AssetClass>(
                  initialSelection: _assetClass,
                  label: 'Asset Class',
                  entries: AssetClass.values
                      .map(
                        (e) => DropdownMenuEntry(
                          value: e,
                          label: _capitalize(e.name),
                        ),
                      )
                      .toList(),
                  onSelected: (v) {
                    if (v != null) setState(() => _assetClass = v);
                  },
                  isDark: isDark,
                ),
                _buildDropdown<Country>(
                  initialSelection: _country,
                  label: 'Country',
                  entries: Country.values
                      .map(
                        (e) => DropdownMenuEntry(
                          value: e,
                          label: _capitalize(e.name),
                        ),
                      )
                      .toList(),
                  onSelected: (v) {
                    if (v != null) setState(() => _country = v);
                  },
                  isDark: isDark,
                ),
                _buildDropdown<String>(
                  initialSelection: _currency,
                  label: 'Currency',
                  entries: [
                    'INR',
                    'USD',
                    'SGD',
                    'EUR',
                    'GBP',
                  ].map((e) => DropdownMenuEntry(value: e, label: e)).toList(),
                  onSelected: (v) {
                    if (v != null) setState(() => _currency = v);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create Instrument',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.sora(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.sora(fontSize: 14),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F1F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: required
            ? (v) => v?.isEmpty ?? true ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T initialSelection,
    required String label,
    required List<DropdownMenuEntry<T>> entries,
    required void Function(T?) onSelected,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownMenu<T>(
        initialSelection: initialSelection,
        label: Text(label),
        dropdownMenuEntries: entries,
        onSelected: onSelected,
        enableFilter: true,
        expandedInsets: EdgeInsets.zero,
        textStyle: GoogleFonts.sora(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F1F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final dao = ref.read(instrumentDaoProvider);
    final id = await dao.insert(
      InstrumentsCompanion(
        name: Value(_nameController.text),
        symbol: Value(
          _symbolController.text.isNotEmpty ? _symbolController.text : null,
        ),
        isin: Value(
          _isinController.text.isNotEmpty ? _isinController.text : null,
        ),
        assetClass: Value(_assetClass),
        country: Value(_country),
        currency: Value(_currency),
      ),
    );
    ref.invalidate(allInstrumentsProvider);
    final instrument = await dao.getById(id);
    if (instrument != null) {
      widget.onCreated(instrument);
    }
  }
}

final allInstrumentsProvider = FutureProvider<List<Instrument>>((ref) {
  return ref.watch(instrumentDaoProvider).getAll();
});
