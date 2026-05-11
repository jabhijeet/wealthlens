import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../data/db/daos.dart';
import '../../../data/db/database.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({
    super.key,
    required this.holdingId,
    this.currency = 'USD',
  });
  final String holdingId;
  final String currency;

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _feesController = TextEditingController();
  final _notesController = TextEditingController();
  TransactionType _type = TransactionType.buy;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _feesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _toMinor(String text) =>
      ((double.tryParse(text) ?? 0.0) * 100).round();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<TransactionType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: TransactionType.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price per unit',
                  suffixText: widget.currency,
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feesController,
                decoration: InputDecoration(
                  labelText: 'Fees (optional)',
                  suffixText: widget.currency,
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(_date.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _date = date);
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final navigator = Navigator.of(context);
            final dao = ref.read(transactionDaoProvider);

            await dao.insert(
              TransactionsCompanion(
                holdingId: Value(widget.holdingId),
                type: Value(_type),
                date: Value(_date),
                quantity: Value(_quantityController.text),
                priceMinor: Value(_toMinor(_priceController.text)),
                feesMinor: Value(_toMinor(_feesController.text)),
                notes: Value(
                  _notesController.text.isNotEmpty
                      ? _notesController.text
                      : null,
                ),
              ),
            );

            if (mounted) navigator.pop(true);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
