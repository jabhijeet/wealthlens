import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../llm/llm_provider.dart';
import '../core/theme.dart';
import '../app/router.dart';

class LlmStatusBox extends ConsumerWidget {
  const LlmStatusBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProvider = ref.watch(activeLlmProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeProvider == null) {
      return _buildBox(
        context,
        color: WealthColors.error,
        icon: Icons.warning_rounded,
        label: 'LLM',
        value: 'Not Configured',
        isDark: isDark,
      );
    }

    if (!activeProvider.isConfigured) {
      return _buildBox(
        context,
        color: WealthColors.accent,
        icon: Icons.key_off_rounded,
        label: activeProvider.kind.name.toUpperCase(),
        value: 'Missing Key',
        isDark: isDark,
      );
    }

    return _buildBox(
      context,
      color: WealthColors.success,
      icon: Icons.check_circle_rounded,
      label: activeProvider.kind.name.toUpperCase(),
      value: activeProvider.model,
      isDark: isDark,
    );
  }

  Widget _buildBox(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => router.push('/settings/llm-providers'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.35,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (isDark ? WealthColors.cardDark : Colors.white).withValues(
              alpha: 0.9,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.sora(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: GoogleFonts.sora(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
