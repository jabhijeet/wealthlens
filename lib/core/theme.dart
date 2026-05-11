import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

class WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

/// WealthLens Design System
/// A premium, modern fintech design language.

// ─── Color Palette ────────────────────────────────────────────────────────────

class WealthColors {
  WealthColors._();

  // Primary — Deep Indigo-Violet
  static const primary = Color(0xFF6C5CE7);
  static const primaryDark = Color(0xFF5A4FCF);
  static const primaryLight = Color(0xFF8B7EF8);

  // Accent — Warm Gold
  static const accent = Color(0xFFFDCB6E);
  static const accentDark = Color(0xFFF0B429);

  // Semantic
  static const success = Color(0xFF00B894);
  static const successLight = Color(0xFFE6F9F3);
  static const warning = Color(0xFFFDCB6E);
  static const warningLight = Color(0xFFFFF8E7);
  static const error = Color(0xFFFF6B6B);
  static const errorLight = Color(0xFFFFEBEB);

  // Surfaces — Light
  static const surfaceLight = Color(0xFFF8F9FC);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE8ECF4);

  // Surfaces — Dark
  static const surfaceDark = Color(0xFF0F0F1A);
  static const cardDark = Color(0xFF1A1A2E);
  static const cardDarkElevated = Color(0xFF222240);
  static const borderDark = Color(0xFF2A2A4A);

  // Text
  static const textDark = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF8E8EA0);
  static const textLight = Color(0xFFF0F0F5);
  static const textMutedDark = Color(0xFF6C6C80);

  // Asset class colors (vibrant, distinguishable)
  static const equity = Color(0xFF6C5CE7);
  static const fixedDeposit = Color(0xFF00B894);
  static const ppf = Color(0xFFFDCB6E);
  static const insurance = Color(0xFFFF6B6B);
  static const realEstate = Color(0xFFE17055);
  static const crypto = Color(0xFF00CEC9);
  static const gold = Color(0xFFF0B429);
  static const cash = Color(0xFF74B9FF);
  static const fixedIncome = Color(0xFF00B894);
  static const bond = Color(0xFF74B9FF);
  static const mutualFund = Color(0xFFA29BFE);
  static const other = Color(0xFFB2BEC3);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF8B7EF8)],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2B55), Color(0xFF6C5CE7)],
    stops: [0.0, 0.5, 1.0],
  );

  static const darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2B55)],
  );
}

// ─── Text Theme ───────────────────────────────────────────────────────────────

TextTheme _buildTextTheme(Brightness brightness, {double fontScale = 1.0}) {
  final baseColor = brightness == Brightness.dark
      ? WealthColors.textLight
      : WealthColors.textDark;
  final mutedColor = brightness == Brightness.dark
      ? WealthColors.textMutedDark
      : WealthColors.textMuted;

  return TextTheme(
    displayLarge: GoogleFonts.outfit(
      fontSize: 40 * fontScale,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      color: baseColor,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 32 * fontScale,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: baseColor,
    ),
    displaySmall: GoogleFonts.outfit(
      fontSize: 24 * fontScale,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: baseColor,
    ),
    headlineLarge: GoogleFonts.outfit(
      fontSize: 24 * fontScale,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: baseColor,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 20 * fontScale,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: baseColor,
    ),
    headlineSmall: GoogleFonts.outfit(
      fontSize: 16 * fontScale,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: baseColor,
    ),
    titleLarge: GoogleFonts.outfit(
      fontSize: 20 * fontScale,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: baseColor,
    ),
    titleMedium: GoogleFonts.outfit(
      fontSize: 16 * fontScale,
      fontWeight: FontWeight.w600,
      color: baseColor,
    ),
    titleSmall: GoogleFonts.outfit(
      fontSize: 14 * fontScale,
      fontWeight: FontWeight.w600,
      color: baseColor,
    ),
    bodyLarge: GoogleFonts.sora(
      fontSize: 16 * fontScale,
      fontWeight: FontWeight.w400,
      color: baseColor,
    ),
    bodyMedium: GoogleFonts.sora(
      fontSize: 14 * fontScale,
      fontWeight: FontWeight.w400,
      color: baseColor,
    ),
    bodySmall: GoogleFonts.sora(
      fontSize: 12 * fontScale,
      fontWeight: FontWeight.w400,
      color: mutedColor,
    ),
    labelLarge: GoogleFonts.sora(
      fontSize: 14 * fontScale,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: baseColor,
    ),
    labelMedium: GoogleFonts.sora(
      fontSize: 12 * fontScale,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      color: mutedColor,
    ),
    labelSmall: GoogleFonts.sora(
      fontSize: 10 * fontScale,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: mutedColor,
    ),
  );
}

// ─── Light Theme ──────────────────────────────────────────────────────────────

ThemeData buildLightTheme({double fontScale = 1.0}) {
  final textTheme = _buildTextTheme(Brightness.light, fontScale: fontScale);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: WealthColors.primary,
      primaryContainer: WealthColors.primaryLight.withValues(alpha: 0.15),
      onPrimaryContainer: WealthColors.primaryDark,
      secondary: WealthColors.accent,
      onSecondary: WealthColors.textDark,
      secondaryContainer: WealthColors.accent.withValues(alpha: 0.15),
      onSecondaryContainer: WealthColors.accentDark,
      surface: WealthColors.surfaceLight,
      onSurface: WealthColors.textDark,
      surfaceContainerLow: WealthColors.cardLight,
      surfaceContainerHighest: const Color(0xFFEEEFF5),
      outline: WealthColors.borderLight,
      outlineVariant: WealthColors.borderLight,
      error: WealthColors.error,
    ),
    scaffoldBackgroundColor: WealthColors.surfaceLight,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: WealthColors.surfaceLight,
      foregroundColor: WealthColors.textDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20 * fontScale,
        fontWeight: FontWeight.w700,
        color: WealthColors.textDark,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: WealthColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: WealthColors.borderLight),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WealthColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WealthColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: WealthColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: WealthColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F1F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WealthColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WealthColors.error),
      ),
      labelStyle: GoogleFonts.sora(
        color: WealthColors.textMuted,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.sora(
        color: WealthColors.textMuted.withValues(alpha: 0.5),
        fontSize: 14,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: WealthColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: StadiumBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF0F1F5),
      selectedColor: WealthColors.primary,
      labelStyle: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    dividerTheme: const DividerThemeData(
      color: WealthColors.borderLight,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: WealthColors.cardLight,
      surfaceTintColor: Colors.transparent,
      indicatorColor: WealthColors.primary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: WealthColors.primary,
          );
        }
        return GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: WealthColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: WealthColors.primary, size: 24);
        }
        return const IconThemeData(color: WealthColors.textMuted, size: 24);
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: WealthColors.cardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: WealthColors.textDark,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: WealthColors.textDark,
      contentTextStyle: GoogleFonts.sora(fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: WealthColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}

// ─── Dark Theme ───────────────────────────────────────────────────────────────

ThemeData buildDarkTheme({double fontScale = 1.0}) {
  final textTheme = _buildTextTheme(Brightness.dark, fontScale: fontScale);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: WealthColors.primaryLight,
      onPrimary: WealthColors.textDark,
      primaryContainer: WealthColors.primary.withValues(alpha: 0.2),
      onPrimaryContainer: WealthColors.primaryLight,
      secondary: WealthColors.accent,
      onSecondary: WealthColors.textDark,
      secondaryContainer: WealthColors.accent.withValues(alpha: 0.15),
      onSecondaryContainer: WealthColors.accent,
      surface: WealthColors.surfaceDark,
      onSurface: WealthColors.textLight,
      surfaceContainerLow: WealthColors.cardDark,
      surfaceContainerHighest: WealthColors.cardDarkElevated,
      outline: WealthColors.borderDark,
      outlineVariant: WealthColors.borderDark,
      error: WealthColors.error,
    ),
    scaffoldBackgroundColor: WealthColors.surfaceDark,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: WealthColors.surfaceDark,
      foregroundColor: WealthColors.textLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20 * fontScale,
        fontWeight: FontWeight.w700,
        color: WealthColors.textLight,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: WealthColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: WealthColors.borderDark),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WealthColors.primaryLight,
        foregroundColor: WealthColors.textDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WealthColors.primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: WealthColors.primaryLight, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: WealthColors.primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WealthColors.cardDarkElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: WealthColors.primaryLight,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WealthColors.error),
      ),
      labelStyle: GoogleFonts.sora(
        color: WealthColors.textMutedDark,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.sora(
        color: WealthColors.textMutedDark.withValues(alpha: 0.5),
        fontSize: 14,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: WealthColors.primaryLight,
      foregroundColor: WealthColors.textDark,
      elevation: 4,
      shape: StadiumBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: WealthColors.cardDarkElevated,
      selectedColor: WealthColors.primaryLight,
      labelStyle: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    dividerTheme: const DividerThemeData(
      color: WealthColors.borderDark,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: WealthColors.cardDark,
      surfaceTintColor: Colors.transparent,
      indicatorColor: WealthColors.primaryLight.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: WealthColors.primaryLight,
          );
        }
        return GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: WealthColors.textMutedDark,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: WealthColors.primaryLight,
            size: 24,
          );
        }
        return const IconThemeData(color: WealthColors.textMutedDark, size: 24);
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: WealthColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: WealthColors.textLight,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: WealthColors.cardDarkElevated,
      contentTextStyle: GoogleFonts.sora(
        fontSize: 14,
        color: WealthColors.textLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: WealthColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
