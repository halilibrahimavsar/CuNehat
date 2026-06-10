/// Takvim ayı ekleme: gün, hedef ayın son gününe kenetlenir.
/// Örn. 31 Oca + 1 ay → 28/29 Şub (30×gün yaklaşımının aksine doğru vade).
DateTime addMonthsClamped(DateTime d, int months) {
  final totalMonths = d.year * 12 + (d.month - 1) + months;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = d.day > lastDay ? lastDay : d.day;
  return DateTime(year, month, day, d.hour, d.minute, d.second);
}
