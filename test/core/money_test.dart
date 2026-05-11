import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/domain/money.dart';

void main() {
  group('Money', () {
    test('should create Money from minor units', () {
      final money = Money(minor: 1050, currency: 'USD');
      expect(money.minor, 1050);
      expect(money.currency, 'USD');
      expect(money.major, 10);
      expect(money.fraction, 50);
    });

    test('should create Money from major and fraction', () {
      final money = Money.fromMajor(10, 50, 'USD');
      expect(money.minor, 1050);
      expect(money.currency, 'USD');
    });

    test('should create Money from decimal', () {
      final money = Money.fromDecimal(Decimal.parse('10.50'), 'USD');
      expect(money.minor, 1050);
      expect(money.currency, 'USD');
    });

    test('should return correct decimal representation', () {
      final money = Money(minor: 1050, currency: 'USD');
      expect(money.decimal, Decimal.parse('10.50'));
    });

    test('should format money correctly', () {
      final money = Money(minor: 1050, currency: 'USD');
      expect(money.format(), '\$10.50');
    });

    test('should handle zero amount', () {
      final money = Money(minor: 0, currency: 'USD');
      expect(money.major, 0);
      expect(money.fraction, 0);
      expect(money.decimal, Decimal.zero);
    });

    test('should handle negative amount', () {
      final money = Money(minor: -1050, currency: 'USD');
      expect(money.major, -10);
      expect(money.fraction, -50);
      expect(money.decimal, Decimal.parse('-10.50'));
    });

    test('should be equatable', () {
      final money1 = Money(minor: 1050, currency: 'USD');
      final money2 = Money(minor: 1050, currency: 'USD');
      final money3 = Money(minor: 2000, currency: 'USD');

      expect(money1, money2);
      expect(money1 == money3, false);
    });

    test('should handle different currencies', () {
      final usd = Money(minor: 1050, currency: 'USD');
      final inr = Money(minor: 1050, currency: 'INR');

      expect(usd.currency, 'USD');
      expect(inr.currency, 'INR');
      expect(usd == inr, false);
    });
  });
}
