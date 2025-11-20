class DateRangeHelper {
  static Map<String, DateTime> getMonthRange(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    return {
      'firstDate': firstDayOfMonth,
      'lastDate': lastDayOfMonth,
    };
  }

  static Map<String, DateTime> getWeekRange(DateTime date) {
    final firstDayOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
    return {
      'firstDate': firstDayOfWeek,
      'lastDate': lastDayOfWeek,
    };
  }

  static Map<String, DateTime> getDayRange(DateTime date) {
    return {
      'firstDate': date,
      'lastDate': date,
    };
  }

  // static Map<String, DateTime> getYearRange(DateTime date) {}
}
