import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/import/document_parser_service.dart';
import '../../models/import.dart';
import '../../providers/providers.dart';

class ImportReviewScreen extends ConsumerStatefulWidget {
  const ImportReviewScreen({
    super.key,
    required this.holdings,
    required this.transactions,
    required this.metadata,
  });
  final List<ParsedHolding> holdings;
  final List<ParsedTransaction> transactions;
  final DocumentMetadata metadata;

  @override
  ConsumerState<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends ConsumerState<ImportReviewScreen> {
  final Set<int> _selectedHoldings = {};
  final Set<int> _selectedTransactions = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Select all by default
    _selectedHoldings.addAll(List.generate(widget.holdings.length, (i) => i));
    _selectedTransactions.addAll(
      List.generate(widget.transactions.length, (i) => i),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Import'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _canSave ? _saveSelected : null,
              tooltip: 'Save selected items',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Metadata card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document: ${widget.metadata.documentType.replaceAll('_', ' ').toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Institution: ${widget.metadata.institution}'),
                  if (widget.metadata.accountHolder != null)
                    Text('Account Holder: ${widget.metadata.accountHolder}'),
                  if (widget.metadata.periodStart != null)
                    Text(
                      'Period: ${widget.metadata.periodStart!.toLocal().toString().split(' ')[0]} to ${widget.metadata.periodEnd!.toLocal().toString().split(' ')[0]}',
                    ),
                  if (widget.metadata.totalValue != null)
                    Text(
                      'Total Value: ${widget.metadata.totalValue!.toStringAsFixed(2)} ${widget.metadata.currency}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Holdings section
          if (widget.holdings.isNotEmpty) ...[
            _buildSectionHeader(
              'Holdings',
              _selectedHoldings.length,
              widget.holdings.length,
              (val) {
                setState(() {
                  if (val == true) {
                    _selectedHoldings.addAll(
                      List.generate(widget.holdings.length, (i) => i),
                    );
                  } else {
                    _selectedHoldings.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.holdings.length,
              itemBuilder: (context, index) {
                final holding = widget.holdings[index];
                final isSelected = _selectedHoldings.contains(index);
                return _buildHoldingCard(holding, index, isSelected);
              },
            ),
            const SizedBox(height: 24),
          ],

          // Transactions section
          if (widget.transactions.isNotEmpty) ...[
            _buildSectionHeader(
              'Transactions',
              _selectedTransactions.length,
              widget.transactions.length,
              (val) {
                setState(() {
                  if (val == true) {
                    _selectedTransactions.addAll(
                      List.generate(widget.transactions.length, (i) => i),
                    );
                  } else {
                    _selectedTransactions.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.transactions.length,
              itemBuilder: (context, index) {
                final transaction = widget.transactions[index];
                final isSelected = _selectedTransactions.contains(index);
                return _buildTransactionCard(transaction, index, isSelected);
              },
            ),
          ],

          if (widget.holdings.isEmpty && widget.transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No holdings or transactions found'),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canSave ? _saveSelected : null,
                  child: const Text('Save Selected'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int selected,
    int total,
    void Function(bool?) onToggle,
  ) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const Spacer(),
        Text('$selected/$total selected', style: const TextStyle(fontSize: 12)),
        Checkbox(value: selected == total && total > 0, onChanged: onToggle),
      ],
    );
  }

  Widget _buildHoldingCard(ParsedHolding holding, int index, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 1 : 0,
      color: isSelected ? Colors.blue.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedHoldings.add(index);
              } else {
                _selectedHoldings.remove(index);
              }
            });
          },
        ),
        title: Text(
          holding.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${holding.quantity} × ${holding.averagePrice.toStringAsFixed(2)} ${holding.currency}\n${holding.assetClass.toUpperCase()}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(holding.quantity * holding.averagePrice).toStringAsFixed(2)} ${holding.currency}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildConfidenceBadge(holding.confidence),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    ParsedTransaction transaction,
    int index,
    bool isSelected,
  ) {
    final isPositive = transaction.amount >= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 1 : 0,
      color: isSelected ? Colors.blue.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedTransactions.add(index);
              } else {
                _selectedTransactions.remove(index);
              }
            });
          },
        ),
        title: Text(
          transaction.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${transaction.date.toLocal().toString().split(' ')[0]} • ${transaction.type}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : ''}${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            _buildConfidenceBadge(transaction.confidence),
          ],
        ),
      ),
    );
  }

  bool get _canSave =>
      (_selectedHoldings.isNotEmpty || _selectedTransactions.isNotEmpty) &&
      !_isSaving;

  Future<void> _saveSelected() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);

    try {
      final parser = ref.read(documentParserServiceProvider);

      final selectedHoldings = widget.holdings
          .asMap()
          .entries
          .where((entry) => _selectedHoldings.contains(entry.key))
          .map((entry) => entry.value)
          .toList();
      if (selectedHoldings.isNotEmpty) {
        await parser.saveParsedHoldings(selectedHoldings);
      }

      final selectedTransactions = widget.transactions
          .asMap()
          .entries
          .where((entry) => _selectedTransactions.contains(entry.key))
          .map((entry) => entry.value)
          .toList();
      if (selectedTransactions.isNotEmpty) {
        await parser.saveParsedTransactions(
          selectedTransactions,
          metadata: widget.metadata,
        );
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Saved ${selectedHoldings.length} holdings and ${selectedTransactions.length} transactions',
            ),
            backgroundColor: Colors.green,
          ),
        );
        navigator.popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildConfidenceBadge(double confidence) {
    Color color = confidence >= 0.9
        ? Colors.green
        : (confidence >= 0.7 ? Colors.orange : Colors.red);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${(confidence * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
