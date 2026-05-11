import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../data/db/daos.dart';
import '../../../data/db/database.dart';
import '../../../domain/money.dart';
import '../models/holding_with_instrument.dart';

class EditHoldingDialog extends ConsumerStatefulWidget {
  const EditHoldingDialog({super.key, required this.item});

  final HoldingWithInstrument item;

  @override
  ConsumerState<EditHoldingDialog> createState() => _EditHoldingDialogState();
}

class _EditHoldingDialogState extends ConsumerState<EditHoldingDialog> {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _accountController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.holding.quantity,
    );
    final avgPrice = Money(
      minor: widget.item.holding.avgCostMinor,
      currency: widget.item.instrument.currency,
    );
    _priceController = TextEditingController(
      text: (avgPrice.minor / 100).toString(),
    );
    _accountController = TextEditingController(
      text: widget.item.holding.account,
    );
    _notesController = TextEditingController(text: widget.item.holding.notes);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _accountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.item.instrument.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Average Price (${widget.item.instrument.currency})',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(labelText: 'Account / Folio'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save Changes')),
      ],
    );
  }

  Future<void> _save() async {
    final quantity = _quantityController.text;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final account = _accountController.text;
    final notes = _notesController.text;

    final dao = ref.read(holdingDaoProvider);

    await dao.updateHolding(
      widget.item.holding.id,
      HoldingsCompanion(
        quantity: Value(quantity),
        avgCostMinor: Value((price * 100).toInt()),
        account: Value(account),
        notes: Value(notes),
      ),
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}
