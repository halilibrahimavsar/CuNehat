import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class DateRangeHelper {
  DateRangeHelper._();

  /// İçinde bulunulan ay. Başlangıç aralığı olarak kullanan sayfalar için;
  /// eskiden `buildDateRangeQuickOptions()[1].range` diye indeksle
  /// alınıyordu ve seçenek sırası değişince sessizce kayardı.
  static DateTimeRange thisMonth({DateTime? now}) {
    final today = now ?? DateTime.now();
    final start = DateTime(today.year, today.month, 1);
    final end = DateTime(today.year, today.month + 1, 0);
    return DateTimeRange(start: start, end: end);
  }

  /// Hızlı aralık seçenekleri. Etiketler l10n'den gelir; sabit Türkçe
  /// metinlerdi ve İngilizce arayüzde de "Son 7 Gün" görünüyordu.
  static List<IboDateRangeQuickOption> buildDateRangeQuickOptions(
      AppLocalizations l10n) {
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
        label: l10n.dateRangeLast7Days,
        range: DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        ),
      ),
      IboDateRangeQuickOption(
        label: l10n.dateRangeThisMonth,
        range: DateTimeRange(start: startOfMonth, end: endOfMonth),
      ),
      IboDateRangeQuickOption(
        label: l10n.dateRangeLastMonth,
        range: DateTimeRange(start: startOfLastMonth, end: endOfLastMonth),
      ),
      IboDateRangeQuickOption(
        label: l10n.dateRangeLast3Months,
        range: DateTimeRange(start: startOfLast3Months, end: endOfMonth),
      ),
      IboDateRangeQuickOption(
        label: l10n.dateRangeThisYear,
        range: DateTimeRange(start: startOfYear, end: endOfYear),
      ),
    ];
  }

  /// [range] içinde bulunulan bütçe dönemi mi — yani başı dönemin başı, sonu
  /// dönemin sonu mu? ("Bu Ay", "Bu Yıl"; aynı sınırları seçen özel aralık da
  /// dahil.)
  ///
  /// "Son 7 Gün", "Son 3 Ay", "Geçen Ay" geriye dönük penceredir: aralığın
  /// bugünle bitmesi "biriken netin tamamı bugün harcanabilir" demek değildir.
  /// Bu ayrım tarihlerden türetilemediğinden günlük harcama hedefini üreten
  /// analiz servisine niyet olarak geçilir.
  static bool isBudgetPeriod(DateTimeRange range, {DateTime? now}) {
    final today = now ?? DateTime.now();

    final startOfMonth = DateTime(today.year, today.month, 1);
    final startOfNextMonth = (today.month == 12)
        ? DateTime(today.year + 1, 1, 1)
        : DateTime(today.year, today.month + 1, 1);
    final endOfMonth = startOfNextMonth.subtract(const Duration(days: 1));

    final startOfYear = DateTime(today.year, 1, 1);
    final endOfYear = DateTime(today.year, 12, 31);

    return (_isSameDay(range.start, startOfMonth) &&
            _isSameDay(range.end, endOfMonth)) ||
        (_isSameDay(range.start, startOfYear) &&
            _isSameDay(range.end, endOfYear));
  }

  /// Aralık uçları seçiciden saat bilgisiyle gelebilir; karşılaştırma gün
  /// bazındadır.
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
