import 'package:flutter/material.dart';

// utilities/date_range_helper.dart
class DateRangeHelper {
  static DateTimeRange getTodayRange() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DateTimeRange(start: startOfDay, end: endOfDay);
  }

  static DateTimeRange getYesterdayRange() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final startOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final endOfDay =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    return DateTimeRange(start: startOfDay, end: endOfDay);
  }

  static DateTimeRange getMonthRange(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    return DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth);
  }

  static DateTimeRange getWeekRange(DateTime date) {
    final firstDayOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final lastDayOfWeek = firstDayOfWeek
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return DateTimeRange(start: firstDayOfWeek, end: lastDayOfWeek);
  }

  static DateTimeRange getLastWeekRange(DateTime date) {
    final lastWeek = date.subtract(const Duration(days: 7));
    return getWeekRange(lastWeek);
  }

  static DateTimeRange getYearRange(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final lastDayOfYear = DateTime(date.year, 12, 31, 23, 59, 59);
    return DateTimeRange(start: firstDayOfYear, end: lastDayOfYear);
  }

  static DateTimeRange getDayRange(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return DateTimeRange(start: startOfDay, end: endOfDay);
  }
}
