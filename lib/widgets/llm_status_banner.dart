import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../llm/llm_provider.dart';
import '../core/theme.dart';

class LlmStatusBanner extends ConsumerStatefulWidget {
  const LlmStatusBanner({super.key});

  @override
  ConsumerState<LlmStatusBanner> createState() => _LlmStatusBannerState();
}

class _LlmStatusBannerState extends ConsumerState<LlmStatusBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final activeProvider = ref.watch(activeLlmProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeProvider == null) {
      return _buildBanner(
        color: WealthColors.error,
        icon: Icons.warning_rounded,
        text: 'LLM not configured — visit Settings',
        isDark: isDark,
      );
    }

    if (!activeProvider.isConfigured) {
      return _buildBanner(
        color: WealthColors.accent,
        icon: Icons.key_off_rounded,
        text: '${activeProvider.kind.name.toUpperCase()} — Missing API Key',
        isDark: isDark,
      );
    }

    // All good — show nothing (no permanent green banner cluttering the UI)
    return const SizedBox.shrink();
  }

  Widget _buildBanner({
    required Color color,
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => context.push('/settings/llm-providers'),
      child: Container(
        width: double.infinity,
        color: color.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                child: Icon(Icons.close_rounded, color: color, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
