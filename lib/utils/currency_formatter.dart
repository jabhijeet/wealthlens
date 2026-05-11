import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Keep only numbers and decimal point
    var newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Handle multiple decimal points
    if (newText.contains('.')) {
      var parts = newText.split('.');
      if (parts.length > 2) {
        newText = '${parts[0]}.${parts.sublist(1).join()}';
      }
    }

    if (newText.isEmpty) {
      return newValue;
    }

    // Don't format if it ends with a decimal or starts with 0.
    if (newText.endsWith('.') ||
        (newText.startsWith('0') &&
            newText.length > 1 &&
            !newText.startsWith('0.'))) {
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    try {
      final value = double.parse(newText);
      final formattedValue = _formatter.format(value);

      // If the user typed a decimal, preserve the decimal part exactly
      if (newText.contains('.')) {
        final decimalPart = newText.split('.')[1];
        final formattedWithDecimal =
            '${_formatter.format(value.floor())}.$decimalPart';
        return TextEditingValue(
          text: formattedWithDecimal,
          selection: TextSelection.collapsed(
            offset: formattedWithDecimal.length,
          ),
        );
      }

      return TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}
