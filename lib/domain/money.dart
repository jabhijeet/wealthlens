import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Represents an amount of money in a specific currency.
/// Stored as integer minor units (e.g., paise, cents) to avoid floating-point errors.
@immutable
class Money extends Equatable {
  const Money({required this.minor, required this.currency});

  /// Creates a Money instance from a major unit (e.g., dollars) and minor unit fraction.
  /// Example: Money.fromMajor(10, 50, 'USD') → $10.50 (1050 minor units).
  factory Money.fromMajor(int major, int minorFraction, String currency) {
    // Assuming 100 minor units per major unit (standard for most currencies)
    const minorPerMajor = 100;
    return Money(
      minor: major * minorPerMajor + minorFraction,
      currency: currency,
    );
  }

  /// Creates a Money instance from a decimal value.
  /// Example: Money.fromDecimal(Decimal.parse('10.50'), 'USD') → 1050 minor units.
  factory Money.fromDecimal(Decimal decimal, String currency) {
    const minorPerMajor = 100;
    final minor = (decimal * Decimal.fromInt(minorPerMajor)).toBigInt().toInt();
    return Money(minor: minor, currency: currency);
  }

  /// Creates a Money instance from a double value.
  factory Money.fromDouble(double value, {required String currency}) {
    return Money.fromDecimal(Decimal.parse(value.toString()), currency);
  }

  /// The amount in the smallest unit of the currency (e.g., cents for USD, paise for INR).
  final int minor;

  /// ISO 4217 currency code (e.g., 'USD', 'INR', 'SGD').
  final String currency;

  /// Returns the major unit (integer part).
  int get major => minor ~/ 100;

  /// Returns the minor fraction (-99 to 99).
  int get fraction {
    final remainder = minor % 100;
    // For negative amounts, we want negative fraction
    if (minor < 0 && remainder != 0) {
      return remainder - 100;
    }
    return remainder;
  }

  /// Returns the decimal representation with 10 significant decimal places.
  Decimal get decimal => (Decimal.fromInt(minor) / Decimal.fromInt(100))
      .toDecimal(scaleOnInfinitePrecision: 10);

  /// Formats the money according to locale.
  /// Example: format('en_US') → '$10.50'
  String format([String locale = 'en_US']) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: _currencySymbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(decimal.toDouble());
  }

  /// Formats the money in a compact way for large amounts.
  /// Example: 4560000 -> 4.56m, 3450000000 -> 3.45b
  String formatCompact() {
    final value = decimal.toDouble();
    final symbol = _currencySymbol(currency);
    final absValue = value.abs();

    if (absValue >= 1000000000) {
      return '$symbol${(value / 1000000000).toStringAsFixed(2)}b';
    } else if (absValue >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(2)}m';
    }
    return format();
  }

  /// Adds two Money amounts if they have the same currency.
  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot add Money with different currencies');
    }
    return Money(minor: minor + other.minor, currency: currency);
  }

  /// Subtracts two Money amounts if they have the same currency.
  Money operator -(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot subtract Money with different currencies');
    }
    return Money(minor: minor - other.minor, currency: currency);
  }

  /// Multiplies by a scalar (int or Decimal).
  Money multiply(dynamic scalar) {
    if (scalar is int) {
      return Money(minor: minor * scalar, currency: currency);
    } else if (scalar is Decimal) {
      final result = (Decimal.fromInt(minor) * scalar).toBigInt().toInt();
      return Money(minor: result, currency: currency);
    } else {
      throw ArgumentError('Scalar must be int or Decimal');
    }
  }

  /// Divides by a scalar (int or Decimal).
  Money divide(dynamic scalar) {
    if (scalar is int) {
      return Money(minor: minor ~/ scalar, currency: currency);
    } else if (scalar is Decimal) {
      final result = (Decimal.fromInt(minor) / scalar)
          .toDecimal(scaleOnInfinitePrecision: 10)
          .toBigInt()
          .toInt();
      return Money(minor: result, currency: currency);
    } else {
      throw ArgumentError('Scalar must be int or Decimal');
    }
  }

  /// Returns true if this amount is zero.
  bool get isZero => minor == 0;

  /// Returns a copy with the same currency but different minor amount.
  Money copyWith({int? minor}) {
    return Money(minor: minor ?? this.minor, currency: currency);
  }

  @override
  List<Object?> get props => [minor, currency];

  @override
  String toString() => 'Money(${format()})';

  static String _currencySymbol(String currency) {
    final map = {
      'USD': r'$',
      'INR': '₹',
      'SGD': r'S$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
    };
    return map[currency] ?? currency;
  }
}
