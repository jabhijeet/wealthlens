import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import 'widgets/add_transaction_dialog.dart';
import 'package:drift/drift.dart' hide Column;
import '../../providers/providers.dart';
import '../../domain/money.dart';

import 'package:decimal/decimal.dart';
import '../../core/theme.dart';
import '../../common/widgets/money_text.dart';
import '../../utils/currency_formatter.dart';
import 'providers/holdings_market_data_provider.dart';


class HoldingDetailScreen extends ConsumerStatefulWidget {
  const HoldingDetailScreen({super.key, required this.holdingId});
  final String holdingId;

  @override
  ConsumerState<HoldingDetailScreen> createState() =>
      _HoldingDetailScreenState();
}

class _HoldingDetailScreenState extends ConsumerState<HoldingDetailScreen> {
  bool _isEditing = false;
  bool _isFetchingPrice = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _symbolController;
  late TextEditingController _accountController;
  late TextEditingController _quantityController;
  late TextEditingController _avgCostController;
  late TextEditingController _notesController;
  late TextEditingController _isinController;
  late TextEditingController _exchangeController;
  late TextEditingController _currencyController;

  Country? _selectedCountry;
  String? _selectedCurrency;
  AssetClass? _selectedAssetClass;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _symbolController = TextEditingController();
    _accountController = TextEditingController();
    _quantityController = TextEditingController();
    _avgCostController = TextEditingController();
    _notesController = TextEditingController();
    _isinController = TextEditingController();
    _exchangeController = TextEditingController();
    _currencyController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _accountController.dispose();
    _quantityController.dispose();
    _avgCostController.dispose();
    _notesController.dispose();
    _isinController.dispose();
    _exchangeController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _initControllers(HoldingWithInstrument item) {
    _nameController.text = item.instrument.name;
    _symbolController.text = item.instrument.symbol ?? '';
    _accountController.text = item.holding.account ?? '';
    _quantityController.text = item.holding.quantity;
    _avgCostController.text = (item.holding.avgCostMinor / 100).toString();
    _notesController.text = item.holding.notes ?? '';
    _isinController.text = item.instrument.isin ?? '';
    _exchangeController.text = item.instrument.exchange ?? '';
    _currencyController.text = item.instrument.currency;
    _selectedCountry = item.instrument.country;
    _selectedCurrency = item.instrument.currency;
    _selectedAssetClass = item.instrument.assetClass;
  }

  @override
  Widget build(BuildContext context) {
    final holdingAsync = ref.watch(
      holdingDetailWithInstrumentProvider(widget.holdingId),
    );
    final activeCurrency = ref.watch(activeCurrencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return holdingAsync.when(
      data: (item) {
        if (item != null && !_isEditing && _nameController.text.isEmpty) {
          _initControllers(item);
        }

        return Scaffold(
          appBar: AppBar(
            title: _isEditing
                ? const Text('Edit Holding')
                : Text(item?.instrument.name ?? 'Holding Details'),
            actions: [
              if (item != null) ...[
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.check_rounded),
                    onPressed: () => _saveChanges(item),
                    color: WealthColors.success,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () {
                      _initControllers(item);
                      setState(() => _isEditing = true);
                    },
                  ),
                IconButton(
                  icon: Icon(
                    _isEditing
                        ? Icons.close_rounded
                        : Icons.delete_outline_rounded,
                  ),
                  onPressed: () {
                    if (_isEditing) {
                      setState(() => _isEditing = false);
                    } else {
                      _confirmDelete(context, ref, item);
                    }
                  },
                ),
              ],
            ],
          ),
          body: item == null
              ? const Center(child: Text('Holding not found'))
              : _buildContent(context, ref, item, activeCurrency, isDark),
          floatingActionButton: item == null || _isEditing
              ? null
              : FloatingActionButton(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AddTransactionDialog(
                        holdingId: widget.holdingId,
                        currency: item.instrument.currency,
                      ),
                    );
                    if (result == true) {
                      ref
                        ..invalidate(transactionsProvider(widget.holdingId))
                        ..invalidate(
                          holdingDetailWithInstrumentProvider(widget.holdingId),
                        )
                        ..invalidate(holdingsWithInstrumentsProvider);
                    }
                  },
                  child: const Icon(Icons.add_rounded),
                ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(
          child: CircularProgressIndicator(color: WealthColors.primary),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HoldingWithInstrument item,
    String activeCurrency,
    bool isDark,
  ) {
    final holding = item.holding;
    final instrument = item.instrument;
    final color = _getColor(instrument.assetClass);

    final bookValue = Money(
      minor:
          (Decimal.parse(holding.quantity) *
                  Decimal.fromInt(holding.avgCostMinor))
              .toBigInt()
              .toInt(),
      currency: instrument.currency,
    );

    final isDifferentCurrency = instrument.currency != activeCurrency;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_isEditing)
          _buildEditForm(context, item, isDark)
        else ...[
          // ── Hero Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        instrument.assetClass.name.toUpperCase(),
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      instrument.currency,
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  instrument.name,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                if (instrument.symbol != null &&
                    instrument.symbol!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    instrument.symbol!,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                MoneyText(
                  money: bookValue,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _buildMarketValueCard(context, ref, item, bookValue, isDark),

          const SizedBox(height: 12),
          _buildLatestPriceCard(context, ref, item, isDark),

          if (isDifferentCurrency) ...[
            const SizedBox(height: 12),
            _buildFxCard(
              context,
              ref,
              instrument.currency,
              activeCurrency,
              bookValue,
              isDark,
            ),
          ],

          const SizedBox(height: 20),

          // ── Details Grid ──
          _MetricsGrid(
            items: [
              _MetricItem('Account', holding.account ?? 'N/A'),
              _MetricItem('Quantity', holding.quantity),
              _MetricItem(
                'Avg Cost',
                '',
                valueWidget: MoneyText(
                  money: Money(
                    minor: holding.avgCostMinor,
                    currency: instrument.currency,
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (instrument.isin != null && instrument.isin!.isNotEmpty)
                _MetricItem('ISIN', instrument.isin!),
              if (instrument.exchange != null &&
                  instrument.exchange!.isNotEmpty)
                _MetricItem('Exchange', instrument.exchange!),
              _MetricItem('Country', instrument.country.name.toUpperCase()),
            ],
            isDark: isDark,
          ),

          if (holding.notes != null && holding.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? WealthColors.borderDark
                      : WealthColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Text(
                    holding.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          _buildFundamentals(ref, instrument, isDark),
          const SizedBox(height: 24),
          Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildTransactions(ref, instrument, isDark),
        ],
      ],
    );
  }

  Widget _buildEditForm(
    BuildContext context,
    HoldingWithInstrument item,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Instrument Details'),
        _buildTextField(_nameController, 'Name'),
        _buildTextField(_symbolController, 'Symbol'),
        _buildDropdown<AssetClass>(
          context: context,
          label: 'Asset Class',
          value: _selectedAssetClass,
          items: AssetClass.values,
          onChanged: (val) => setState(() => _selectedAssetClass = val),
          itemLabel: (e) => e.name.toUpperCase(),
        ),
        _buildDropdown<Country>(
          context: context,
          label: 'Country',
          value: _selectedCountry,
          items: Country.values,
          onChanged: (val) => setState(() => _selectedCountry = val),
          itemLabel: (e) => e.name.toUpperCase(),
        ),
        _buildTextField(_isinController, 'ISIN'),
        _buildTextField(_exchangeController, 'Exchange'),
        _buildTextField(
          _currencyController,
          'Currency (ISO)',
          onChanged: (val) =>
              setState(() => _selectedCurrency = val.toUpperCase()),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Holding Details'),
        _buildTextField(_accountController, 'Account / Folio'),
        _buildTextField(
          _quantityController,
          'Quantity',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
        ),
        _buildTextField(
          _avgCostController,
          'Avg Cost (${item.instrument.currency})',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
        ),
        _buildTextField(_notesController, 'Notes', maxLines: 2),

        const SizedBox(height: 80), // Space for bottom
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: WealthColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        onChanged: onChanged,
        style: GoogleFonts.sora(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.sora(fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T) onChanged,
    required String Function(T) itemLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: BoxDecoration(
                color: isDark
                    ? WealthColors.surfaceDark
                    : WealthColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Select $label',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = item == value;
                          return ListTile(
                            title: Text(
                              itemLabel(item),
                              style: GoogleFonts.sora(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? WealthColors.primary : null,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: WealthColors.primary,
                                  )
                                : null,
                            onTap: () {
                              onChanged(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.sora(fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value != null ? itemLabel(value) : 'Select',
                style: GoogleFonts.sora(fontSize: 14),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges(HoldingWithInstrument item) async {
    final name = _nameController.text;
    final symbol = _symbolController.text;
    final account = _accountController.text;
    final rawQuantity = _quantityController.text.replaceAll(',', '');
    final quantity = rawQuantity.isEmpty ? '0' : rawQuantity;
    final rawAvgCost = _avgCostController.text.replaceAll(',', '');
    final avgCost = double.tryParse(rawAvgCost) ?? 0.0;
    final notes = _notesController.text;
    final isin = _isinController.text;
    final exchange = _exchangeController.text;

    final instrumentDao = ref.read(instrumentDaoProvider);
    final holdingDao = ref.read(holdingDaoProvider);

    try {
      await instrumentDao.updateInstrument(
        item.instrument.id,
        InstrumentsCompanion(
          name: Value(name),
          symbol: Value(symbol.isEmpty ? null : symbol),
          country: Value(_selectedCountry ?? item.instrument.country),
          currency: Value(_selectedCurrency ?? item.instrument.currency),
          assetClass: Value(_selectedAssetClass ?? item.instrument.assetClass),
          isin: Value(isin.isEmpty ? null : isin),
          exchange: Value(exchange.isEmpty ? null : exchange),
        ),
      );

      await holdingDao.updateHolding(
        item.holding.id,
        HoldingsCompanion(
          account: Value(account.isEmpty ? null : account),
          quantity: Value(quantity),
          avgCostMinor: Value((avgCost * 100).toInt()),
          notes: Value(notes.isEmpty ? null : notes),
        ),
      );

      ref
        ..invalidate(holdingDetailWithInstrumentProvider(widget.holdingId))
        ..invalidate(holdingsWithInstrumentsProvider);

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
      }
    }
  }

  Color _getColor(AssetClass assetClass) {
    switch (assetClass) {
      case AssetClass.equity:
        return WealthColors.equity;
      case AssetClass.fixedDeposit:
      case AssetClass.recurringDeposit:
        return WealthColors.fixedIncome;
      case AssetClass.cryptoSpot:
        return WealthColors.crypto;
      case AssetClass.realEstateResidentialSelfUse:
      case AssetClass.realEstateResidentialRented:
        return WealthColors.realEstate;
      case AssetClass.cash:
        return WealthColors.cash;
      case AssetClass.commodity:
        return WealthColors.gold;
      default:
        return WealthColors.primary;
    }
  }

  Widget _buildMarketValueCard(
    BuildContext context,
    WidgetRef ref,
    HoldingWithInstrument item,
    Money bookValue,
    bool isDark,
  ) {
    final latestPriceAsync = ref.watch(
      _latestPriceSnapshotProvider(item.instrument.id),
    );

    return latestPriceAsync.when(
      data: (snapshot) {
        if (snapshot == null) return const SizedBox.shrink();

        final quantity = Decimal.parse(item.holding.quantity);
        final marketMinor = (quantity * Decimal.fromInt(snapshot.closeMinor))
            .toBigInt()
            .toInt();
        final marketValue = Money(
          minor: marketMinor,
          currency: item.instrument.currency,
        );

        final pnlMinor = marketMinor - bookValue.minor;
        final isGain = pnlMinor >= 0;
        final pnlColor = isGain ? WealthColors.success : WealthColors.error;
        final pnlPct = bookValue.minor != 0
            ? (pnlMinor / bookValue.minor) * 100
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? WealthColors.borderDark
                  : WealthColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market Value',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    MoneyText(
                      money: marketValue,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('P&L', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  MoneyText(
                    money: Money(
                      minor: pnlMinor,
                      currency: item.instrument.currency,
                    ),
                    showPlusSign: true,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: pnlColor,
                    ),
                  ),
                  Text(
                    '${isGain ? '+' : ''}${pnlPct.toStringAsFixed(2)}%',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: pnlColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildLatestPriceCard(
    BuildContext context,
    WidgetRef ref,
    HoldingWithInstrument item,
    bool isDark,
  ) {
    final instrument = item.instrument;
    final hasPriceable =
        (instrument.isin?.isNotEmpty ?? false) ||
        (instrument.symbol?.isNotEmpty ?? false) ||
        (instrument.exchange?.isNotEmpty ?? false);

    if (!hasPriceable) return const SizedBox.shrink();

    final snapshotAsync = ref.watch(
      _latestPriceSnapshotProvider(instrument.id),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WealthColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: WealthColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Market Price',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (_isFetchingPrice)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: WealthColors.primary,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: WealthColors.primary,
                  ),
                  tooltip: 'Fetch latest price',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    setState(() => _isFetchingPrice = true);
                    try {
                      final priceService = ref.read(priceServiceProvider);
                      await priceService.forceRefreshPrice(instrument);
                      ref
                        ..invalidate(
                          _latestPriceSnapshotProvider(instrument.id),
                        )
                        ..invalidate(holdingsMarketDataProvider);
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not fetch price. Check symbol/ISIN.'),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isFetchingPrice = false);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          snapshotAsync.when(
            data: (snapshot) {
              if (snapshot == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No price data yet',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: WealthColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap refresh to fetch from market data',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: WealthColors.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                );
              }

              final price = Money(
                minor: snapshot.closeMinor,
                currency: snapshot.currency,
              );
              final priceDate = snapshot.date.toLocal();
              final now = DateTime.now();
              final diff = now.difference(priceDate);
              final ageStr = diff.inMinutes < 60
                  ? '${diff.inMinutes}m ago'
                  : diff.inHours < 24
                  ? '${diff.inHours}h ago'
                  : '${priceDate.day}/${priceDate.month}/${priceDate.year}';
              final isStale = diff.inHours >= 24;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Price',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            MoneyText(
                              money: price,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: WealthColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isStale
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_rounded,
                                size: 12,
                                color: isStale
                                    ? WealthColors.warning
                                    : WealthColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ageStr,
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isStale
                                      ? WealthColors.warning
                                      : WealthColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'via ${snapshot.source}',
                            style: GoogleFonts.sora(
                              fontSize: 10,
                              color: WealthColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 40,
              child: Center(
                child: LinearProgressIndicator(color: WealthColors.primary),
              ),
            ),
            error: (_, e2) => Text(
              'Unable to load price',
              style: GoogleFonts.sora(color: WealthColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundamentals(WidgetRef ref, Instrument instrument, bool isDark) {

    if (instrument.assetClass != AssetClass.equity) {
      return const SizedBox.shrink();
    }

    final fundamentalAsync = ref.watch(
      fundamentalSnapshotProvider(instrument.id),
    );

    return fundamentalAsync.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fundamentals',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _MetricsGrid(
              items: [
                if (data.peRatio != null) _MetricItem('P/E', data.peRatio!),
                if (data.pbRatio != null) _MetricItem('P/B', data.pbRatio!),
                if (data.roe != null) _MetricItem('ROE', '${data.roe}%'),
                if (data.roce != null) _MetricItem('ROCE', '${data.roce}%'),
                if (data.debtToEquity != null)
                  _MetricItem('D/E', data.debtToEquity!),
              ],
              isDark: isDark,
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(color: WealthColors.primary),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildTransactions(WidgetRef ref, Instrument instrument, bool isDark) {
    final transactionsAsync = ref.watch(transactionsProvider(widget.holdingId));

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? WealthColors.borderDark
                    : WealthColors.borderLight,
              ),
            ),
            child: Center(
              child: Text(
                'No transactions yet',
                style: GoogleFonts.sora(color: WealthColors.textMuted),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isBuy = tx.type == TransactionType.buy;
            final color = isBuy ? WealthColors.success : WealthColors.error;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? WealthColors.borderDark
                      : WealthColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  // Timeline dot
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (index < transactions.length - 1)
                        Container(
                          width: 2,
                          height: 30,
                          color: color.withValues(alpha: 0.2),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.type.name.toUpperCase(),
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        Text(
                          '${tx.quantity} units on ${tx.date.toLocal().toString().split(' ')[0]}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  MoneyText(
                    money: Money(
                      minor:
                          (Decimal.parse(tx.quantity) *
                                  Decimal.fromInt(tx.priceMinor))
                              .toBigInt()
                              .toInt(),
                      currency: instrument.currency,
                    ),
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: WealthColors.primary),
      ),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildFxCard(
    BuildContext context,
    WidgetRef ref,
    String from,
    String to,
    Money bookValue,
    bool isDark,
  ) {
    final fxRateAsync = ref.watch(conversionRateProvider((from: from, to: to)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WealthColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.currency_exchange_rounded,
                  color: WealthColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Currency Conversion',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              fxRateAsync.when(
                data: (rate) => IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: () =>
                      _showFxEditSheet(context, ref, from, to, rate),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit FX Rate',
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          fxRateAsync.when(
            data: (rate) {
              final convertedValueMinor =
                  (Decimal.parse(bookValue.minor.toString()) * rate)
                      .toBigInt()
                      .toInt();
              final convertedValue = Money(
                minor: convertedValueMinor,
                currency: to,
              );

              return Column(
                children: [
                  _ConversionRow(
                    label: 'Exchange Rate',
                    value: '1 $from = ${rate.toStringAsFixed(4)} $to',
                    icon: Icons.info_outline_rounded,
                    onIconTap: () => _showFxInfo(context, from, to, rate),
                  ),
                  const Divider(height: 24),
                  _ConversionRow(
                    label: 'Value in $to',
                    value: '',
                    valueWidget: MoneyText(
                      money: convertedValue,
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: WealthColors.primary,
                      ),
                    ),
                    isHighlight: true,
                  ),
                ],
              );
            },
            loading: () => const Center(child: LinearProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Failed to load FX rate. Tap to retry.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: WealthColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFxInfo(BuildContext context, String from, String to, Decimal rate) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exchange Rate Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Base: $from', style: Theme.of(context).textTheme.bodyMedium),
            Text('Target: $to', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Current Rate: ${rate.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: WealthColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rates are fetched from Frankfurter API or manual overrides. They are updated every 24 hours.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showFxEditSheet(
    BuildContext context,
    WidgetRef ref,
    String from,
    String to,
    Decimal currentRate,
  ) {
    final controller = TextEditingController(text: currentRate.toString());

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit FX Rate', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Manually set the rate for 1 $from to $to',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Exchange Rate',
                suffixText: to,
                prefixText: '1 $from = ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newRate = Decimal.tryParse(controller.text);
                  if (newRate != null) {
                    final dao = ref.read(fxRateDaoProvider);
                    await dao.insertOrUpdate(
                      FxRatesCompanion(
                        base: Value(from),
                        quote: Value(to),
                        rate: Value(newRate.toString()),
                        date: Value(DateTime.now()),
                      ),
                    );
                    ref.invalidate(conversionRateProvider);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Save Rate'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HoldingWithInstrument item,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.instrument.name}?'),
        content: const Text(
          'This will move the holding to Trash. You can restore it later from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final dao = ref.read(holdingDaoProvider);
              await dao.updateHolding(
                widget.holdingId,
                HoldingsCompanion(isActive: const Value(false)),
              );
              if (context.mounted) {
                ref.invalidate(holdingsWithInstrumentsProvider);
                Navigator.pop(context); // Close dialog
                context.pop(); // Close detail screen
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WealthColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _MetricItem {
  const _MetricItem(this.label, this.value, {this.valueWidget});
  final String label;
  final String value;
  final Widget? valueWidget;
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.items, required this.isDark});
  final List<_MetricItem> items;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 50) / 2,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? WealthColors.borderDark
                    : WealthColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                if (item.valueWidget != null)
                  item.valueWidget!
                else
                  Text(
                    item.value,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Providers (kept as-is) ───────────────────────────────────────────────────

final _latestPriceSnapshotProvider =
    FutureProvider.family<PriceSnapshot?, String>((ref, instrumentId) async {
      final dao = ref.watch(priceSnapshotDaoProvider);
      return dao.getLatest(instrumentId);
    });

final holdingDetailWithInstrumentProvider =
    FutureProvider.family<HoldingWithInstrument?, String>((
      ref,
      holdingId,
    ) async {
      final holdingDao = ref.watch(holdingDaoProvider);
      final instrumentDao = ref.watch(instrumentDaoProvider);

      final holding = await holdingDao.getById(holdingId);
      if (holding == null) return null;

      final instrument = await instrumentDao.getById(holding.instrumentId);
      if (instrument == null) return null;

      return HoldingWithInstrument(holding: holding, instrument: instrument);
    });

final transactionsProvider = FutureProvider.family<List<Transaction>, String>((
  ref,
  holdingId,
) async {
  final dao = ref.watch(transactionDaoProvider);
  return dao.getByHoldingId(holdingId);
});

final fundamentalSnapshotProvider =
    FutureProvider.family<FundamentalSnapshot?, String>((
      ref,
      instrumentId,
    ) async {
      final dao = ref.watch(fundamentalSnapshotDaoProvider);
      return dao.getLatest(instrumentId);
    });

final conversionRateProvider =
    FutureProvider.family<Decimal, ({String from, String to})>((
      ref,
      arg,
    ) async {
      final service = ref.watch(fxServiceProvider);
      return service.getRate(arg.from, arg.to);
    });

class _ConversionRow extends StatelessWidget {
  const _ConversionRow({
    required this.label,
    required this.value,
    this.valueWidget,
    this.icon,
    this.onIconTap,
    this.isHighlight = false,
  });
  final String label;
  final String value;
  final Widget? valueWidget;
  final IconData? icon;
  final VoidCallback? onIconTap;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: WealthColors.textMuted),
        ),
        if (icon != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onIconTap,
            child: Icon(icon, size: 14, color: WealthColors.textMuted),
          ),
        ],
        const Spacer(),
        if (valueWidget != null)
          valueWidget!
        else
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? WealthColors.primary : null,
            ),
          ),
      ],
    );
  }
}
