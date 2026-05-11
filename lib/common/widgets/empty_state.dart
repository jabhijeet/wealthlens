import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';


class UnifiedEmptyPortfolioState extends StatelessWidget {
  const UnifiedEmptyPortfolioState({
    super.key,
    this.message = 'Add your first holding to see your portfolio breakdown, allocation chart, and performance metrics.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? WealthColors.borderDark : WealthColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: WealthColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: WealthColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No holdings yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: WealthColors.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => context.push('/holdings/new'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Holding'),
                  style: FilledButton.styleFrom(
                    backgroundColor: WealthColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/import'),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Import from PDF/Excel'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: WealthColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
