import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'file_helper_stub.dart' if (dart.library.io) 'file_helper_native.dart';
import '../../services/logging/logger_service.dart';
import '../../services/import/document_parser_service.dart';
import '../../models/import.dart';
import '../../llm/llm_provider.dart';
import 'import_review_screen.dart';
import '../../core/theme.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportSource? _selectedSource;
  String? _filePath;
  String? _extractedText;
  Uint8List? _imageBytes;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Import Holdings')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Import Source',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSourceTile(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  source: ImportSource.pdf,
                  color: WealthColors.error,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildSourceTile(
                  label: 'Excel',
                  icon: Icons.table_chart_rounded,
                  source: ImportSource.excel,
                  color: WealthColors.success,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildSourceTile(
                  label: 'Image',
                  icon: Icons.image_rounded,
                  source: ImportSource.image,
                  color: WealthColors.primary,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_selectedSource != null) _buildSourceUI(isDark),
            if (_extractedText != null || _imageBytes != null)
              _buildExtractedText(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTile({
    required String label,
    required IconData icon,
    required ImportSource source,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedSource == source;
    return Expanded(
      child: Material(
        color: isSelected
            ? color.withValues(alpha: 0.15)
            : isDark
            ? WealthColors.cardDark
            : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => setState(() => _selectedSource = source),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color
                    : isDark
                    ? WealthColors.borderDark
                    : WealthColors.borderLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceUI(bool isDark) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: WealthColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STEP 1',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: WealthColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Pick your ${_selectedSource!.name.toUpperCase()} file',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _pickFile,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Choose File'),
            ),
          ),
          if (_filePath != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: WealthColors.success,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _filePath!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: WealthColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExtractedText(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: WealthColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'STEP 2',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WealthColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Review & Process',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_imageBytes!),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? WealthColors.cardDarkElevated
                            : const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _extractedText ?? '',
                          style: GoogleFonts.inter(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _sendToLlm,
                icon: const Icon(Icons.smart_toy_rounded, size: 18),
                label: const Text('Process with AI'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _isProcessing = true;
      _filePath = null;
      _extractedText = null;
      _imageBytes = null;
    });

    final provider = ref.read(activeLlmProvider);
    if (provider == null || !provider.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'LLM not configured. Please set up an API key in Settings first.',
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => context.push('/settings/llm-providers'),
            ),
          ),
        );
        setState(() => _isProcessing = false);
      }
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (_selectedSource!) {
        case ImportSource.pdf:
          await _pickPdf();
          break;
        case ImportSource.excel:
          await _pickExcel();
          break;
        case ImportSource.image:
          await _pickImage();
      }
    } catch (e, stack) {
      logger.e('File picking error', e, stack);
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );
    if (result == null) return;

    final fileName = result.files.single.name;
    final bytes =
        result.files.single.bytes ??
        (kIsWeb ? null : await _readFileAsBytes(result.files.single.path!));
    if (bytes == null) throw Exception('Could not read file bytes');

    setState(() {
      _isProcessing = true;
      _filePath = fileName;
    });

    PdfDocument? document;
    String? password;

    try {
      // First attempt without password
      document = PdfDocument(inputBytes: bytes);
    } catch (e) {
      if (e.toString().contains('password') ||
          e.toString().contains('encrypted') ||
          e.toString().contains('invalid password')) {
        if (mounted) {
          password = await _showPasswordDialog(bytes);
          if (password == null) {
            setState(() => _isProcessing = false);
            return; // User cancelled
          }
          // If password was returned, the dialog already verified it
          document = PdfDocument(inputBytes: bytes, password: password);
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final text = PdfTextExtractor(document).extractText(layoutText: true);
    document.dispose();

    setState(() {
      _extractedText = text;
      _isProcessing = false;
    });
  }

  Future<String?> _showPasswordDialog(Uint8List pdfBytes) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PdfPasswordDialog(pdfBytes: pdfBytes),
    );
  }

  Future<Uint8List?> _readFileAsBytes(String path) async {
    // This is only called on native
    // We use a separate file for this or just a dynamic call to avoid web compilation issues?
    // Modern Flutter usually handles this if guarded by kIsWeb.
    // ignore: undefined_identifier
    return await FileHelper.readAsBytes(path);
  }

  Future<void> _pickExcel() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: kIsWeb,
    );
    if (result == null) return;

    final fileName = result.files.single.name;
    final bytes =
        result.files.single.bytes ??
        (kIsWeb ? null : await _readFileAsBytes(result.files.single.path!));
    if (bytes == null) throw Exception('Could not read file bytes');

    setState(() => _filePath = fileName);

    final excel = excel_pkg.Excel.decodeBytes(bytes);
    final text = StringBuffer();

    for (final table in excel.tables.keys) {
      text.writeln('Sheet: $table');
      final sheet = excel.tables[table]!;
      for (final row in sheet.rows) {
        final rowText = row
            .map((cell) => cell?.value?.toString() ?? '')
            .join('\t');
        text.writeln(rowText);
      }
    }

    setState(() => _extractedText = text.toString());
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _filePath = image.name;
      _imageBytes = bytes;
      _extractedText = null;
    });
  }

  Future<void> _sendToLlm() async {
    if (_extractedText == null || _extractedText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text extracted to process')),
      );
      return;
    }

    final provider = ref.read(activeLlmProvider);
    if (provider == null || !provider.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'LLM provider not configured or missing API key. Please set up a provider in Settings.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => context.push('/settings/llm-providers'),
          ),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isProcessing = true);

    try {
      final parser = ref.read(documentParserServiceProvider);

      late DocumentMetadata metadata;
      var holdings = <ParsedHolding>[];
      var transactions = <ParsedTransaction>[];

      if (_selectedSource == ImportSource.image && _imageBytes != null) {
        // Use LLM Vision to parse image directly
        final base64Image = base64Encode(_imageBytes!);
        final result = await parser.parseImage([
          base64Image,
        ], provider: provider);

        metadata = DocumentMetadata.fromJson(
          result['metadata'] as Map<String, dynamic>,
        );

        if (result['holdings'] != null) {
          final list = result['holdings'] as List<dynamic>;
          holdings = list
              .map((h) => ParsedHolding.fromJson(h as Map<String, dynamic>))
              .toList();
        }

        if (result['transactions'] != null) {
          final list = result['transactions'] as List<dynamic>;
          transactions = list
              .map((t) => ParsedTransaction.fromJson(t as Map<String, dynamic>))
              .toList();
        }
      } else if (_extractedText != null) {
        // Use text-based parsing
        metadata = await parser.classifyDocument(
          _extractedText!,
          provider: provider,
        );

        if (metadata.containsHoldings) {
          holdings = await parser.extractHoldings(
            _extractedText!,
            provider: provider,
          );
        }

        if (metadata.containsTransactions) {
          transactions = await parser.extractTransactions(
            _extractedText!,
            provider: provider,
          );
        }
      } else {
        throw Exception('No data to process');
      }

      // Navigate to review screen
      if (mounted) {
        await navigator.push<void>(
          MaterialPageRoute<void>(
            builder: (context) => ImportReviewScreen(
              holdings: holdings,
              transactions: transactions,
              metadata: metadata,
            ),
          ),
        );
      }
    } catch (e, stack) {
      logger.e('LLM processing error', e, stack);
      if (mounted) {
        final errorStr = e.toString();
        final isAuthError =
            errorStr.contains('API key') ||
            errorStr.contains('401') ||
            errorStr.contains('Authentication');

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Error processing with LLM: ${errorStr.replaceFirst('Exception: ', '')}',
            ),
            action: isAuthError
                ? SnackBarAction(
                    label: 'SETTINGS',
                    onPressed: () => context.push('/settings/llm-providers'),
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

enum ImportSource { pdf, excel, image }

class _PdfPasswordDialog extends StatefulWidget {
  const _PdfPasswordDialog({required this.pdfBytes});
  final Uint8List pdfBytes;

  @override
  State<_PdfPasswordDialog> createState() => _PdfPasswordDialogState();
}

class _PdfPasswordDialogState extends State<_PdfPasswordDialog> {
  final _controller = TextEditingController();
  bool _isUnlocking = false;
  String? _errorMessage;

  Future<void> _handleUnlock() async {
    final password = _controller.text;
    if (password.isEmpty) return;

    setState(() {
      _isUnlocking = true;
      _errorMessage = null;
    });

    // Give UI a chance to show loading
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      PdfDocument(inputBytes: widget.pdfBytes, password: password).dispose();
      if (mounted) Navigator.pop(context, password);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUnlocking = false;
          _errorMessage = 'Invalid password or decryption failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Password Protected',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This PDF is encrypted. Please enter the password to unlock it.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: WealthColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter PDF password',
              errorText: _errorMessage,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            obscureText: true,
            autofocus: true,
            enabled: !_isUnlocking,
            onSubmitted: (_) => _handleUnlock(),
          ),
          if (_isUnlocking)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 3),
                    SizedBox(height: 12),
                    Text('Unlocking PDF...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUnlocking ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: WealthColors.textMuted),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUnlocking ? null : _handleUnlock,
          style: ElevatedButton.styleFrom(
            backgroundColor: WealthColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
