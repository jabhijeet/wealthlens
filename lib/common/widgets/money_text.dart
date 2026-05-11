import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/money.dart';
import '../../providers/providers.dart';

class MoneyText extends ConsumerWidget {
  const MoneyText({
    super.key,
    required this.money,
    this.style,
    this.maskChar = '•',
    this.maskCount = 6,
    this.useCompact = false,
    this.showPlusSign = false,
  });

  final Money money;
  final TextStyle? style;
  final String maskChar;
  final int maskCount;
  final bool useCompact;
  final bool showPlusSign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivacyEnabled = ref.watch(privacyModeProvider);

    if (isPrivacyEnabled) {
      return Text('${money.currency} ${maskChar * maskCount}', style: style);
    }

    final formatted = useCompact ? money.formatCompact() : money.format();
    final prefix = (showPlusSign && money.minor > 0) ? '+' : '';

    return Text(
      '$prefix$formatted',
      style: style,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
