// lib/core/utils/date_helper.dart
import 'package:intl/intl.dart';

class DateHelper {
  /// Format date to string
  static String formatDate(DateTime date, {String format = 'dd.MM.yyyy'}) {
    return DateFormat(format, 'tr_TR').format(date);
  }

  /// Format date to long string
  static String formatDateLong(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
  }

  /// Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(dateTime);
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is in range
  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start) && date.isBefore(end) ||
        date.isAtSameMomentAs(start) ||
        date.isAtSameMomentAs(end);
  }
}
