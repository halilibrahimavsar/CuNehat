import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class DateRangeHelper {
  DateRangeHelper._();

  static List<IboDateRangeQuickOption> buildDateRangeQuickOptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = (now.month == 12)
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    final endOfMonth = startOfNextMonth.subtract(const Duration(days: 1));
    final startOfLastMonth = (now.month == 1)
        ? DateTime(now.year - 1, 12, 1)
        : DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = startOfMonth.subtract(const Duration(days: 1));
    
    final startOfLast3Months = DateTime(now.year, now.month - 2, 1);
    
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);

    return [
      IboDateRangeQuickOption(
        label: 'Son 7 Gün',
        range: DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        ),
      ),
      IboDateRangeQuickOption(
        label: 'Bu Ay',
        range: DateTimeRange(start: startOfMonth, end: endOfMonth),
      ),
      IboDateRangeQuickOption(
        label: 'Geçen Ay',
        range: DateTimeRange(start: startOfLastMonth, end: endOfLastMonth),
      ),
      IboDateRangeQuickOption(
        label: 'Son 3 Ay',
        range: DateTimeRange(start: startOfLast3Months, end: endOfMonth),
      ),
      IboDateRangeQuickOption(
        label: 'Bu Yıl',
        range: DateTimeRange(start: startOfYear, end: endOfYear),
      ),
    ];
  }
}
