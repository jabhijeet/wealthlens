import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../widgets/quick_add_fab.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? WealthColors.surfaceDark
          : WealthColors.surfaceLight,
      body: Column(
        children: [
          Expanded(child: navigationShell),
          // Integrated Bottom Navigation Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? WealthColors.borderDark
                      : WealthColors.borderLight,
                  width: 0.5,
                ),
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
              ],
            ),
            child: SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavDestination(
                          index: 0,
                          icon: Icons.dashboard_outlined,
                          selectedIcon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          isSelected: navigationShell.currentIndex == 0,
                          onTap: () => _onTap(0),
                        ),
                      ),
                      Expanded(
                        child: _NavDestination(
                          index: 1,
                          icon: Icons.account_balance_wallet_outlined,
                          selectedIcon: Icons.account_balance_wallet_rounded,
                          label: 'Holdings',
                          isSelected: navigationShell.currentIndex == 1,
                          onTap: () => _onTap(1),
                        ),
                      ),
                      Expanded(
                        child: _NavDestination(
                          index: 2,
                          icon: Icons.newspaper_outlined,
                          selectedIcon: Icons.newspaper_rounded,
                          label: 'News',
                          isSelected: navigationShell.currentIndex == 2,
                          onTap: () => _onTap(2),
                        ),
                      ),
                      Expanded(
                        child: _NavDestination(
                          index: 3,
                          icon: Icons.insights_outlined,
                          selectedIcon: Icons.insights_rounded,
                          label: 'Insights',
                          isSelected: navigationShell.currentIndex == 3,
                          onTap: () => _onTap(3),
                        ),
                      ),
                      Expanded(
                        child: _NavDestination(
                          index: 4,
                          icon: Icons.more_horiz_outlined,
                          selectedIcon: Icons.more_horiz_rounded,
                          label: 'More',
                          isSelected: navigationShell.currentIndex == 4,
                          onTap: () => _onTap(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const QuickAddFab(),
      floatingActionButtonLocation: const _CustomFloatingActionButtonLocation(
        FloatingActionButtonLocation.endFloat,
        offsetY: -70,
      ),
    );
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    // Re-tapping current tab resets it to root; switching tabs preserves their history
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _CustomFloatingActionButtonLocation(this.location, {this.offsetY = 0});

  final FloatingActionButtonLocation location;
  final double offsetY;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final offset = location.getOffset(scaffoldGeometry);
    return Offset(offset.dx, offset.dy + offsetY);
  }
}

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? WealthColors.primary : WealthColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? WealthColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? selectedIcon : icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.sora(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
