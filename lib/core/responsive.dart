import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Utility class for responsive design in WealthLens.
/// Handles screen scaling, breakpoints, and adaptive layouts.
class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;

  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  static late double textScaleFactor;
  static late double devicePixelRatio;

  /// Standard design width and height (e.g., iPhone 13)
  static const double _designWidth = 390.0;
  static const double _designHeight = 844.0;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;

    textScaleFactor = _mediaQueryData.textScaler.scale(1.0);
    devicePixelRatio = _mediaQueryData.devicePixelRatio;
  }

  /// Scale size based on screen width relative to design width
  static double scaleW(double size) {
    return (size * screenWidth) / _designWidth;
  }

  /// Scale size based on screen height relative to design height
  static double scaleH(double size) {
    return (size * screenHeight) / _designHeight;
  }

  /// Scale font size based on screen width, capped for large screens
  static double scaleFont(double size) {
    // We use a slightly more conservative scaling for fonts to avoid them becoming huge on tablets
    // but still responsive on smaller phones.
    double scale = math.min(screenWidth / _designWidth, 1.2);
    return size * scale;
  }

  /// Returns true if the screen is considered a tablet/desktop
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  /// Returns a value based on the current breakpoint
  static T valueByBreakpoint<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024 && desktop != null) return desktop;
    if (width >= 600 && tablet != null) return tablet;
    return mobile;
  }
}

/// A wrapper widget that initializes the [Responsive] utility.
class ResponsiveWrapper extends StatelessWidget {
  const ResponsiveWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Responsive().init(context);
        return child;
      },
    );
  }
}
