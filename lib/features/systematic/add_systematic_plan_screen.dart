import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../data/db/database.dart';
import '../../data/db/daos.dart';
import '../../domain/money.dart';
import '../../providers/providers.dart';
import '../../core/theme.dart';
import '../../services/systematic/systematic_plan_service.dart';

class AddSystematicPlanScreen extends ConsumerStatefulWidget {
  const AddSystematicPlanScreen({super.key, this.holdingId});
  final String? holdingId;

  @override
  ConsumerState<AddSystematicPlanScreen> createState() =>
      _AddSystematicPlanScreenState();
}

class _AddSystematicPlanScreenState
    extends ConsumerState<AddSystematicPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedKind = 'sip';
  String _selectedFrequency = 'monthly';
  String? _selectedHoldingId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _dayOfMonth;
  String? _fundingAccount;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedHoldingId = widget.holdingId;
    _dayOfMonth = DateTime.now().day;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Systematic Plan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // Plan Type
            _buildSectionTitle('Plan Type'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeTile(
                  label: 'SIP',
                  icon: Icons.trending_up_rounded,
                  value: 'sip',
                ),
                const SizedBox(width: 12),
                _buildTypeTile(
                  label: 'SWP',
                  icon: Icons.trending_down_rounded,
                  value: 'swp',
                ),
                const SizedBox(width: 12),
                _buildTypeTile(
                  label: 'STP',
                  icon: Icons.swap_horiz_rounded,
                  value: 'stp',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Holding Selection
            _buildSectionTitle('Source Holding'),
            const SizedBox(height: 12),
            _buildHoldingDropdown(),
            const SizedBox(height: 24),

            // Amount
            _buildSectionTitle('Plan Amount'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Frequency
            _buildSectionTitle('Frequency'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['daily', 'weekly', 'monthly', 'quarterly', 'yearly']
                  .map((freq) {
                    final isSelected = _selectedFrequency == freq;
                    return ChoiceChip(
                      label: Text(freq.capitalize()),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedFrequency = freq);
                      },
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Day of Month (for monthly frequency)
            if (_selectedFrequency == 'monthly') ...[
              _buildSectionTitle('Execution Day'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? WealthColors.cardDarkElevated
                      : const Color(0xFFF0F1F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Slider(
                      value: (_dayOfMonth ?? 1).toDouble(),
                      min: 1,
                      max: 28,
                      divisions: 27,
                      onChanged: (value) =>
                          setState(() => _dayOfMonth = value.toInt()),
                    ),
                    Text(
                      'Occurs on the $_dayOfMonth${_getOrdinal(_dayOfMonth!)} of each month',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: WealthColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Schedule
            _buildSectionTitle('Schedule'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _selectStartDate(context),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    label: 'End Date (Optional)',
                    date: _endDate,
                    onTap: () => _selectEndDate(context),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notes
            _buildSectionTitle('Notes (Optional)'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Internal Notes'),
              maxLines: 2,
            ),
            const SizedBox(height: 40),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Initialize Plan'),
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

  Widget _buildTypeTile({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedKind == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedKind = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? WealthColors.primary.withValues(alpha: 0.1)
                : (isDark
                      ? WealthColors.cardDarkElevated
                      : const Color(0xFFF0F1F5)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? WealthColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? WealthColors.primary
                    : WealthColors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? WealthColors.primary
                      : WealthColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingDropdown() {
    return FutureBuilder<List<Holding>>(
      future: ref.watch(holdingDaoProvider).getAll(),
      builder: (context, snapshot) {
        final holdings = snapshot.data ?? [];
        if (holdings.isEmpty) return const Text('No holdings available');

        return DropdownButtonFormField<String>(
          initialValue: _selectedHoldingId,
          decoration: const InputDecoration(labelText: 'Select Holding'),
          items: holdings.map((h) {
            return DropdownMenuItem(
              value: h.id,
              child: FutureBuilder<Instrument?>(
                future: ref.read(instrumentDaoProvider).getById(h.instrumentId),
                builder: (context, iSnapshot) =>
                    Text(iSnapshot.data?.name ?? h.id),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedHoldingId = val),
          validator: (val) => val == null ? 'Required' : null,
        );
      },
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedHoldingId == null) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(systematicPlanServiceProvider);
      final holding = await ref
          .read(holdingDaoProvider)
          .getById(_selectedHoldingId!);
      final instrument = await ref
          .read(instrumentDaoProvider)
          .getById(holding!.instrumentId);
      final amount = Money.fromDouble(
        double.parse(_amountController.text),
        currency: instrument!.currency,
      );

      await service.createPlan(
        holdingId: _selectedHoldingId!,
        kind: _selectedKind,
        amount: amount,
        frequency: _selectedFrequency,
        startDate: _startDate,
        endDate: _endDate,
        dayOfMonth: _selectedFrequency == 'monthly' ? _dayOfMonth : null,
        fundingAccount: _fundingAccount,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  color: WealthColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date != null ? date!.toString().split(' ')[0] : 'None',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
