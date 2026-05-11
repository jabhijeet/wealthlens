import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:google_fonts/google_fonts.dart';
import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import 'widgets/instrument_picker.dart';
import '../../core/theme.dart';

class AddHoldingScreen extends ConsumerStatefulWidget {
  const AddHoldingScreen({super.key, this.initialInstrument});
  final Instrument? initialInstrument;

  @override
  ConsumerState<AddHoldingScreen> createState() => _AddHoldingScreenState();
}

class _AddHoldingScreenState extends ConsumerState<AddHoldingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  final _accountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _avgCostController = TextEditingController();
  final _notesController = TextEditingController();

  // New Instrument Info (Merged from CreateInstrumentDialog)
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _isinController = TextEditingController();
  AssetClass _selectedAssetClass = AssetClass.equity;
  Country _selectedCountry = Country.india;
  String _selectedCurrency = 'INR';

  Instrument? _selectedInstrument;
  bool _isCreatingNewInstrument = true;

  @override
  void initState() {
    super.initState();
    _selectedInstrument = widget.initialInstrument;
    if (_selectedInstrument != null) {
      _isCreatingNewInstrument = false;
    }
    _avgCostController.text = '0';
    _quantityController.text = '1';
    if (_selectedInstrument?.assetClass == AssetClass.fixedDeposit) {
      _startDate = DateTime.now();
    }
  }

  // Specialized Info - FD/RD
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  DateTime? _startDate;
  DateTime? _maturityDate;
  final String _compounding = 'quarterly';

  // Specialized Info - PPF
  final _ppfContributionController = TextEditingController();

  // Specialized Info - Insurance
  final _policyNumberController = TextEditingController();
  final _insurerController = TextEditingController();
  final _premiumController = TextEditingController();
  final _sumAssuredController = TextEditingController();
  String _premiumFrequency = 'yearly';
  final int _premiumTerm = 15;

  // Specialized Info - Real Estate
  final _areaController = TextEditingController();
  final _valuationController = TextEditingController();
  final _loanController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _accountController.dispose();
    _quantityController.dispose();
    _avgCostController.dispose();
    _notesController.dispose();
    _nameController.dispose();
    _symbolController.dispose();
    _isinController.dispose();
    _principalController.dispose();
    _rateController.dispose();
    _ppfContributionController.dispose();
    _policyNumberController.dispose();
    _insurerController.dispose();
    _premiumController.dispose();
    _sumAssuredController.dispose();
    _areaController.dispose();
    _valuationController.dispose();
    _loanController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedInstrument == null && !_isCreatingNewInstrument) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an instrument first')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final holdingDao = ref.read(holdingDaoProvider);
    final instrumentDao = ref.read(instrumentDaoProvider);

    try {
      Instrument instrument;
      if (_isCreatingNewInstrument) {
        // Create the instrument first
        final id = await instrumentDao.insert(
          InstrumentsCompanion(
            name: Value(_nameController.text),
            symbol: Value(
              _symbolController.text.isNotEmpty ? _symbolController.text : null,
            ),
            isin: Value(
              _isinController.text.isNotEmpty ? _isinController.text : null,
            ),
            assetClass: Value(_selectedAssetClass),
            country: Value(_selectedCountry),
            currency: Value(_selectedCurrency),
          ),
        );
        ref.invalidate(allInstrumentsProvider);
        final created = await instrumentDao.getById(id);
        if (created == null) throw Exception('Failed to create instrument');
        instrument = created;
      } else {
        instrument = _selectedInstrument!;
      }

      final ac = instrument.assetClass;
      var avgCost = 0.0;
      var quantity = '1';

      if (_hasStandardQuantityAndPrice(ac)) {
        avgCost = double.tryParse(_avgCostController.text) ?? 0.0;
        quantity = _quantityController.text.isNotEmpty
            ? _quantityController.text
            : '1';
      } else if (ac == AssetClass.cash || ac == AssetClass.epf) {
        quantity = _quantityController.text.isNotEmpty
            ? _quantityController.text
            : '0';
        avgCost = 1.0;
      } else if (ac.name.contains('realEstate')) {
        avgCost = double.tryParse(_avgCostController.text) ?? 0.0;
        quantity = '1';
      } else if (ac == AssetClass.fixedDeposit ||
          ac == AssetClass.recurringDeposit) {
        avgCost = double.tryParse(_principalController.text) ?? 0.0;
        quantity = '1';
      } else if (ac == AssetClass.ppf) {
        avgCost = double.tryParse(_ppfContributionController.text) ?? 0.0;
        quantity = '1';
      } else if (ac.name.contains('insurance')) {
        avgCost = double.tryParse(_premiumController.text) ?? 0.0;
        quantity = '1';
      }

      final holdingId = await holdingDao.insert(
        HoldingsCompanion(
          instrumentId: Value(instrument.id),
          account: Value(
            _accountController.text.isNotEmpty ? _accountController.text : null,
          ),
          quantity: Value(quantity),
          avgCostMinor: Value((avgCost * 100).round()),
          openedOn: Value(_startDate ?? DateTime.now()),
          notes: Value(
            _notesController.text.isNotEmpty ? _notesController.text : null,
          ),
          source: const Value(InstrumentSource.manual),
        ),
      );

      // Handle Specialized Data
      if (instrument.assetClass == AssetClass.fixedDeposit ||
          instrument.assetClass == AssetClass.recurringDeposit) {
        final fdDao = ref.read(fdRdAccountDaoProvider);
        final principal = double.tryParse(_principalController.text) ?? 0.0;
        await fdDao.insert(
          FdRdAccountsCompanion(
            holdingId: Value(holdingId),
            principalMinor: Value((principal * 100).round()),
            annualRatePct: Value(_rateController.text),
            compoundingFrequency: Value(_compounding),
            startDate: Value(_startDate ?? DateTime.now()),
            maturityDate: Value(
              _maturityDate ?? DateTime.now().add(const Duration(days: 365)),
            ),
            payoutType: const Value('cumulative'),
          ),
        );
      } else if (instrument.assetClass == AssetClass.ppf) {
        final ppfDao = ref.read(ppfAccountDaoProvider);
        final contribution =
            double.tryParse(_ppfContributionController.text) ?? 0.0;
        await ppfDao.insert(
          PpfAccountsCompanion(
            holdingId: Value(holdingId),
            contributionsJson: Value(
              jsonEncode([
                {
                  'date': (_startDate ?? DateTime.now()).toIso8601String(),
                  'amountMinor': (contribution * 100).round(),
                },
              ]),
            ),
            rateHistoryJson: const Value('[]'),
            maturityDate: Value(
              _maturityDate ??
                  DateTime.now().add(const Duration(days: 15 * 365)),
            ),
          ),
        );
      } else if (instrument.assetClass.name.contains('insurance')) {
        final insDao = ref.read(insurancePolicyDaoProvider);
        final premium = double.tryParse(_premiumController.text) ?? 0.0;
        final sumAssured = double.tryParse(_sumAssuredController.text) ?? 0.0;
        await insDao.insert(
          InsurancePoliciesCompanion(
            holdingId: Value(holdingId),
            policyNumber: Value(_policyNumberController.text),
            insurer: Value(_insurerController.text),
            type: Value(instrument.assetClass.name),
            premiumMinor: Value((premium * 100).round()),
            premiumFrequency: Value(_premiumFrequency),
            premiumPayingTermYears: Value(_premiumTerm),
            sumAssuredMinor: Value((sumAssured * 100).round()),
            startDate: Value(_startDate ?? DateTime.now()),
            maturityDate: Value(
              _maturityDate ??
                  DateTime.now().add(const Duration(days: 20 * 365)),
            ),
          ),
        );
      } else if (instrument.assetClass.name.contains('realEstate')) {
        final reDao = ref.read(realEstateHoldingDaoProvider);
        final val = double.tryParse(_valuationController.text) ?? 0.0;
        final loan = double.tryParse(_loanController.text) ?? 0.0;
        await reDao.insert(
          RealEstateHoldingsCompanion(
            holdingId: Value(holdingId),
            propertyType: Value(instrument.assetClass.name),
            addressLine: Value(_addressController.text),
            builtUpAreaSqft: Value(int.tryParse(_areaController.text)),
            acquisitionDate: Value(_startDate ?? DateTime.now()),
            acquisitionCostMinor: Value((avgCost * 100).round()),
            currentValuationMinor: Value((val * 100).round()),
            hasLoan: Value(_loanController.text.isNotEmpty),
            loanOutstandingMinor: Value((loan * 100).round()),
          ),
        );
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add holding: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedInstrument == null && !_isCreatingNewInstrument
              ? 'Select Asset'
              : 'Add Holding',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            if (_isCreatingNewInstrument) ...[
              _buildSectionTitle('Instrument Details'),
              const SizedBox(height: 12),
              _buildInstrumentCreationFields(isDark),
              const SizedBox(height: 32),
            ] else ...[
              _buildInstrumentHeader(isDark),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle('Holding Details'),
            const SizedBox(height: 12),
            ..._buildBasicFields(),
            if (_isSpecializedAsset()) ...[
              const SizedBox(height: 32),
              _buildSectionTitle('Additional Details'),
              const SizedBox(height: 12),
              ..._buildSpecializedFields(isDark),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: WealthColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text(
                'Save Holding',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildInstrumentHeader(bool isDark) {
    final color = _getAssetColor(_selectedInstrument!.assetClass);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getAssetIcon(_selectedInstrument!.assetClass),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedInstrument!.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_selectedInstrument!.symbol ?? 'No Symbol'} • ${_selectedInstrument!.assetClass.name.toUpperCase()}',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: WealthColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
            onPressed: () {
              setState(() {
                _selectedInstrument = null;
                _isCreatingNewInstrument = false;
              });
            },
            tooltip: 'Change Instrument',
          ),
        ],
      ),
    );
  }

  void _showSearchModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: InstrumentPicker(
                onSelected: (instrument) {
                  setState(() {
                    _selectedInstrument = instrument;
                    _isCreatingNewInstrument = false;
                  });
                  Navigator.pop(context);
                },
                onCreateCustom: ({name, symbol, assetClass, country}) {
                  setState(() {
                    _isCreatingNewInstrument = true;
                    if (name != null) _nameController.text = name;
                    if (symbol != null) _symbolController.text = symbol;
                    if (assetClass != null) _selectedAssetClass = assetClass;
                    if (country != null) {
                      _selectedCountry = country;
                      _selectedCurrency = _guessCurrency(country);
                    }
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentCreationFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showSearchModal,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: WealthColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: WealthColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: WealthColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Search Market (Optional)',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: WealthColors.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _nameController,
          label: 'Instrument Name',
          required: true,
          isDark: isDark,
        ),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _symbolController,
                label: 'Symbol',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _isinController,
                label: 'ISIN (Optional)',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDropdown<AssetClass>(
                initialSelection: _selectedAssetClass,
                label: 'Asset Class',
                entries: AssetClass.values
                    .map(
                      (e) => DropdownMenuEntry(
                        value: e,
                        label: e.name.replaceAll('_', ' ').capitalize(),
                      ),
                    )
                    .toList(),
                onSelected: (v) {
                  if (v != null) setState(() => _selectedAssetClass = v);
                },
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown<Country>(
                initialSelection: _selectedCountry,
                label: 'Country',
                entries: Country.values
                    .map(
                      (e) => DropdownMenuEntry(
                        value: e,
                        label: e.name.capitalize(),
                      ),
                    )
                    .toList(),
                onSelected: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedCountry = v;
                      _selectedCurrency = _guessCurrency(v);
                    });
                  }
                },
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdown<String>(
          initialSelection: _selectedCurrency,
          label: 'Currency',
          entries: [
            'INR',
            'USD',
            'SGD',
            'EUR',
            'GBP',
          ].map((e) => DropdownMenuEntry(value: e, label: e)).toList(),
          onSelected: (v) {
            if (v != null) setState(() => _selectedCurrency = v);
          },
          isDark: isDark,
        ),
      ],
    );
  }

  String _guessCurrency(Country country) {
    switch (country) {
      case Country.india:
        return 'INR';
      case Country.usa:
        return 'USD';
      case Country.uk:
        return 'GBP';
      case Country.singapore:
        return 'SGD';
      default:
        return 'USD';
    }
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

  bool _hasStandardQuantityAndPrice(AssetClass ac) {
    return ac == AssetClass.equity ||
        ac == AssetClass.etf ||
        ac == AssetClass.mutualFund ||
        ac == AssetClass.bond ||
        ac == AssetClass.nps ||
        ac == AssetClass.cryptoSpot ||
        ac == AssetClass.cryptoStaked ||
        ac == AssetClass.cryptoLpToken ||
        ac == AssetClass.cryptoStablecoin ||
        ac == AssetClass.cryptoNft ||
        ac == AssetClass.commodity ||
        ac == AssetClass.custom ||
        ac == AssetClass.other;
  }

  List<Widget> _buildBasicFields() {
    final ac = _isCreatingNewInstrument
        ? _selectedAssetClass
        : _selectedInstrument!.assetClass;
    final currency = _isCreatingNewInstrument
        ? _selectedCurrency
        : _selectedInstrument!.currency;

    final fields = <Widget>[
      TextFormField(
        controller: _accountController,
        decoration: const InputDecoration(
          labelText: 'Account / Platform',
          hintText: 'e.g., Zerodha, ICICI Bank, Binance',
        ),
      ),
      const SizedBox(height: 16),
    ];

    if (_hasStandardQuantityAndPrice(ac)) {
      fields.addAll([
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: ac == AssetClass.bond ? 'Notional' : 'Quantity',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _avgCostController,
                decoration: InputDecoration(
                  labelText: ac == AssetClass.bond
                      ? 'Price %'
                      : 'Avg Cost ($currency)',
                  hintText: 'e.g. 150.25',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ]);
    } else if (ac == AssetClass.cash || ac == AssetClass.epf) {
      fields.addAll([
        TextFormField(
          controller: _quantityController,
          decoration: InputDecoration(
            labelText: 'Balance / Amount ($currency)',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
      ]);
    } else if (ac.name.contains('realEstate')) {
      fields.addAll([
        TextFormField(
          controller: _avgCostController,
          decoration: InputDecoration(
            labelText: 'Acquisition Cost ($currency)',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
      ]);
    }

    fields.add(
      TextFormField(
        controller: _notesController,
        decoration: const InputDecoration(labelText: 'Notes (Optional)'),
        maxLines: 2,
      ),
    );

    return fields;
  }

  bool _isSpecializedAsset() {
    final ac = _isCreatingNewInstrument
        ? _selectedAssetClass
        : _selectedInstrument!.assetClass;
    return ac == AssetClass.fixedDeposit ||
        ac == AssetClass.recurringDeposit ||
        ac == AssetClass.ppf ||
        ac == AssetClass.insuranceTerm ||
        ac == AssetClass.insuranceUlip;
  }

  List<Widget> _buildSpecializedFields(bool isDark) {
    final ac = _isCreatingNewInstrument
        ? _selectedAssetClass
        : _selectedInstrument!.assetClass;
    if (ac == AssetClass.fixedDeposit || ac == AssetClass.recurringDeposit) {
      return [
        TextFormField(
          controller: _principalController,
          decoration: const InputDecoration(labelText: 'Principal Amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _rateController,
          decoration: const InputDecoration(labelText: 'Interest Rate (%)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        _DatePickerField(
          label: 'Start Date',
          date: _startDate,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => _startDate = date);
          },
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _DatePickerField(
          label: 'Maturity Date',
          date: _maturityDate,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _maturityDate ??
                  DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => _maturityDate = date);
          },
          isDark: isDark,
        ),
      ];
    }
    if (ac == AssetClass.ppf) {
      return [
        TextFormField(
          controller: _ppfContributionController,
          decoration: const InputDecoration(labelText: 'Initial Contribution'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        _DatePickerField(
          label: 'Maturity Date (15 years default)',
          date: _maturityDate,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _maturityDate ??
                  DateTime.now().add(const Duration(days: 15 * 365)),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => _maturityDate = date);
          },
          isDark: isDark,
        ),
      ];
    }

    if (ac.name.contains('insurance')) {
      return [
        TextFormField(
          controller: _insurerController,
          decoration: const InputDecoration(labelText: 'Insurer'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _policyNumberController,
          decoration: const InputDecoration(labelText: 'Policy Number'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _premiumController,
                decoration: const InputDecoration(labelText: 'Premium'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _premiumFrequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items:
                    ['monthly', 'quarterly', 'half-yearly', 'yearly', 'single']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.capitalize()),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _premiumFrequency = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _sumAssuredController,
          decoration: const InputDecoration(labelText: 'Sum Assured'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ];
    }
    return [const Text('Specialized fields coming soon for this asset class')];
  }

  IconData _getAssetIcon(AssetClass assetClass) {
    switch (assetClass) {
      case AssetClass.equity:
        return Icons.show_chart_rounded;
      case AssetClass.fixedDeposit:
        return Icons.account_balance_wallet_rounded;
      case AssetClass.cryptoSpot:
        return Icons.currency_bitcoin_rounded;
      case AssetClass.realEstateLand:
        return Icons.landscape_rounded;
      default:
        return Icons.assessment_rounded;
    }
  }

  Color _getAssetColor(AssetClass assetClass) {
    switch (assetClass) {
      case AssetClass.equity:
        return WealthColors.equity;
      case AssetClass.fixedDeposit:
        return WealthColors.fixedDeposit;
      case AssetClass.cryptoSpot:
        return WealthColors.crypto;
      case AssetClass.realEstateLand:
        return WealthColors.realEstate;
      default:
        return WealthColors.primary;
    }
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? WealthColors.cardDarkElevated : const Color(0xFFF0F1F5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: WealthColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date != null ? date!.toString().split(' ')[0] : 'Not set',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: WealthColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
