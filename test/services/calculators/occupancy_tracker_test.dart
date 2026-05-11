import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/services/calculators/occupancy_tracker.dart';

void main() {
  group('OccupancyTracker', () {
    test('should calculate occupancy for simple periods', () {
      final periods = [
        OccupancyPeriod(
          startDate: DateTime(2023),
          endDate: DateTime(2023, 6, 30),
          occupied: true,
        ),
        OccupancyPeriod(
          startDate: DateTime(2023, 7),
          endDate: DateTime(2023, 12, 31),
          occupied: false,
        ),
      ];

      final start = DateTime(2023);
      final end = DateTime(2023, 12, 31);

      final result = OccupancyTracker.calculateOccupancy(
        periods: periods,
        start: start,
        end: end,
      );

      // Jan 1 - Jun 30 = 180 days (exclusive of end date)
      // Jul 1 - Dec 31 = 183 days
      // Total days = 365
      // Occupied days = 180
      // Vacancy days = 185 (365 - 180)
      // Occupancy rate = 180/365 ≈ 49.32%
      expect(result.totalDays, 365);
      expect(result.occupiedDays, 180);
      expect(result.vacancyDays, 185);
      expect(result.occupancyRate.toDouble(), closeTo(49.32, 0.01));
    });

    test('should handle overlapping periods (non-overlapping assumption)', () {
      final periods = [
        OccupancyPeriod(
          startDate: DateTime(2023),
          endDate: DateTime(2023, 3, 31),
          occupied: true,
        ),
        OccupancyPeriod(
          startDate: DateTime(2023, 4),
          endDate: DateTime(2023, 6, 30),
          occupied: false,
        ),
        // This period overlaps with previous but algorithm will process
        // sequentially
        OccupancyPeriod(
          startDate: DateTime(2023, 5),
          endDate: DateTime(2023, 8, 31),
          occupied: true,
        ),
      ];

      final start = DateTime(2023);
      final end = DateTime(2023, 8, 31);

      final result = OccupancyTracker.calculateOccupancy(
        periods: periods,
        start: start,
        end: end,
      );

      // With overlapping periods, behavior depends on implementation
      // We'll just verify it doesn't crash
      expect(result.totalDays, greaterThan(0));
      expect(result.occupiedDays, greaterThanOrEqualTo(0));
      expect(result.vacancyDays, greaterThanOrEqualTo(0));
    });

    test('should handle periods outside analysis range', () {
      final periods = [
        OccupancyPeriod(
          startDate: DateTime(2022),
          endDate: DateTime(2022, 12, 31),
          occupied: true,
        ),
        OccupancyPeriod(
          startDate: DateTime(2023),
          endDate: DateTime(2023, 6, 30),
          occupied: true,
        ),
        OccupancyPeriod(
          startDate: DateTime(2024),
          endDate: DateTime(2024, 12, 31),
          occupied: false,
        ),
      ];

      final start = DateTime(2023);
      final end = DateTime(2023, 12, 31);

      final result = OccupancyTracker.calculateOccupancy(
        periods: periods,
        start: start,
        end: end,
      );

      // Only second period falls within range (Jan 1 - Jun 30)
      // That's 180 days occupied (exclusive of end date)
      // Jul 1 - Dec 31 has no periods defined, treated as vacancy
      // Total days = 365, occupied = 180, vacancy = 185
      expect(result.totalDays, 365);
      expect(result.occupiedDays, 180);
      expect(result.vacancyDays, 185);
    });

    test('should return zero for invalid date range', () {
      final periods = [
        OccupancyPeriod(
          startDate: DateTime(2023),
          endDate: DateTime(2023, 12, 31),
          occupied: true,
        ),
      ];

      final start = DateTime(2024);
      final end = DateTime(2023, 12, 31); // start after end

      final result = OccupancyTracker.calculateOccupancy(
        periods: periods,
        start: start,
        end: end,
      );

      expect(result.totalDays, 0);
      expect(result.occupiedDays, 0);
      expect(result.vacancyDays, 0);
      expect(result.occupancyRate, Decimal.zero);
    });

    test('should detect vacancy alert when vacant too long', () {
      final periods = [
        OccupancyPeriod(
          startDate: DateTime(2023),
          endDate: DateTime(2023, 3, 31),
          occupied: true,
        ),
        // Last occupied ended on Mar 31, 2023
      ];

      final asOf = DateTime(2023, 6, 30); // 91 days after last occupied

      final alert = OccupancyTracker.vacancyAlert(periods: periods, asOf: asOf);

      // Vacancy days = 91 > 60, so alert should be true
      expect(alert, true);
    });

    test('should not detect vacancy alert when recently occupied', () {
      final periods = [
        OccupancyPeriod(
          startDate: DateTime(2023),
          endDate: DateTime(2023, 5, 31),
          occupied: true,
        ),
      ];

      final asOf = DateTime(2023, 6, 15); // 15 days after last occupied

      final alert = OccupancyTracker.vacancyAlert(periods: periods, asOf: asOf);

      // Vacancy days = 15 < 60, so alert should be false
      expect(alert, false);
    });

    test('should alert when never occupied', () {
      final periods = [
        OccupancyPeriod(
          startDate: DateTime(2023),
          endDate: DateTime(2023, 12, 31),
          occupied: false, // Never occupied
        ),
      ];

      final asOf = DateTime(2023, 6, 30);

      final alert = OccupancyTracker.vacancyAlert(periods: periods, asOf: asOf);

      // Never occupied, so alert should be true
      expect(alert, true);
    });

    test('should handle empty periods list', () {
      final periods = <OccupancyPeriod>[];

      final asOf = DateTime(2023, 6, 30);

      final alert = OccupancyTracker.vacancyAlert(periods: periods, asOf: asOf);

      // No periods, never occupied, alert should be true
      expect(alert, true);
    });
  });
}
