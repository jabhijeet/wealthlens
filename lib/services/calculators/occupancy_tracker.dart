import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

class OccupancyPeriod {
  OccupancyPeriod({
    required this.startDate,
    required this.endDate,
    required this.occupied,
  });
  final DateTime startDate;
  final DateTime endDate;
  final bool occupied;
}

class OccupancyTracker {
  /// Calculate occupancy statistics from a list of occupancy periods.
  /// [periods] sorted list of occupancy periods (can be overlapping? assume non-overlapping).
  /// [start] start date of analysis.
  /// [end] end date of analysis.
  /// Returns total days, occupied days, vacancy days, and occupancy rate.
  static ({
    int totalDays,
    int occupiedDays,
    int vacancyDays,
    Decimal occupancyRate,
  })
  calculateOccupancy({
    required List<OccupancyPeriod> periods,
    required DateTime start,
    required DateTime end,
  }) {
    if (start.isAfter(end)) {
      return (
        totalDays: 0,
        occupiedDays: 0,
        vacancyDays: 0,
        occupancyRate: Decimal.zero,
      );
    }

    var occupiedDays = 0;
    var current = start;

    // Sort periods by start date
    final sorted = List<OccupancyPeriod>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    for (final period in sorted) {
      // Skip periods that end before current date
      if (period.endDate.isBefore(current)) continue;
      // If period starts after end, break
      if (period.startDate.isAfter(end)) break;

      final periodStart = period.startDate.isAfter(current)
          ? period.startDate
          : current;
      final periodEnd = period.endDate.isBefore(end) ? period.endDate : end;
      if (periodStart.isAfter(periodEnd)) continue;

      final days = periodEnd.difference(periodStart).inDays;
      if (period.occupied) {
        occupiedDays += days;
      }
      current = periodEnd.add(const Duration(days: 1));
    }

    final totalDays = end.difference(start).inDays + 1; // inclusive
    final vacancyDays = totalDays - occupiedDays;
    final occupancyRate = totalDays > 0
        ? Decimal.parse(
            (Rational.fromInt(occupiedDays) /
                    Rational.fromInt(totalDays) *
                    Rational.fromInt(100))
                .toDouble()
                .toString(),
          )
        : Decimal.zero;

    return (
      totalDays: totalDays,
      occupiedDays: occupiedDays,
      vacancyDays: vacancyDays,
      occupancyRate: occupancyRate,
    );
  }

  /// Detect vacancy alerts.
  /// Returns true if vacancy days exceed threshold.
  static bool vacancyAlert({
    required List<OccupancyPeriod> periods,
    required DateTime asOf,
    int thresholdDays = 60,
  }) {
    // Find the most recent occupied period
    DateTime? lastOccupiedEnd;
    for (final period in periods) {
      if (period.occupied && period.endDate.isBefore(asOf)) {
        if (lastOccupiedEnd == null ||
            period.endDate.isAfter(lastOccupiedEnd)) {
          lastOccupiedEnd = period.endDate;
        }
      }
    }

    if (lastOccupiedEnd == null) {
      // Never occupied
      return true;
    }

    final vacancyDays = asOf.difference(lastOccupiedEnd).inDays;
    return vacancyDays > thresholdDays;
  }
}
