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

  /// [range] TAM olarak bir takvim ayını mı kaplıyor (ayın 1'i → ayın son
  /// günü)? [isBudgetPeriod]'dan farkı: o "içinde bulunulan dönem mi" diye
  /// sorar ve "Bu Yıl"ı da kabul eder; bu ise "bir AY mı" diye sorar ve
  /// "Geçen Ay"ı da kabul eder.
  ///
  /// Bütçe limitleri AYLIKTIR (bkz. `BudgetEntity.limitAmount`). Bir aralığın
  /// harcamasını aylık limite bölmek yalnız aralık bir ay olduğunda anlamlı:
  /// "Bu Yıl" seçiliyken rapor 12 aylık harcamayı 1 aylık limite bölüp
  /// "%340 aşıldı" diyordu — aynı anda Bütçeler sayfası "%28" diyordu.
  static bool isSingleCalendarMonth(DateTimeRange range) {
    final start = range.start;
    if (start.day != 1) return false;
    final lastDay = DateTime(start.year, start.month + 1, 0);
    return _isSameDay(range.end, lastDay);
  }

  /// [range] TAM BİR AY uzunluğunda mı — ayın kaçında başlarsa başlasın
  /// (15 Eyl → 14 Eki dahil)? Maaş gününe göre ay kullanan kişinin dönemi de
  /// bir aydır; bütçe limiti orantılanmadan kullanılır.
  static bool isMonthLength(DateTimeRange range) => wholeMonthCount(range) == 1;

  /// [range] kaç TAM aydan oluşuyor — ayın kaçında başlarsa başlasın
  /// (1 Oca – 31 Ara → 12, 16 Tem – 15 Eki → 3, 15 Eyl – 14 Eki → 1). Tam
  /// ay değilse ya da başlangıç 28'inden sonraysa (ay sonu kenetlemesi
  /// belirsiz) `null`.
  static int? wholeMonthCount(DateTimeRange range) {
    final start = range.start;
    if (start.day > 28) return null;
    for (var n = 1;; n++) {
      final end = DateTime(start.year, start.month + n, start.day - 1);
      if (_isSameDay(range.end, end)) return n;
      if (end.isAfter(range.end)) return null;
    }
  }

  /// Aylık bir bütçe limitini [range]'e uyarlayan katsayı: tam aylardan
  /// oluşan aralıkta ay sayısı ("Bu yıl" → 12), diğer aralıklarda gün sayısı
  /// / ortalama ay uzunluğu (30,4375). Eskiden yalnız tek ay tam sayılıyordu;
  /// yıl 365 / 30,4375 = 11,99 ay çıkıyor, 2.000'lik bütçe 23.983,57 oluyordu
  /// (smoke test R-43).
  static double monthlyLimitFactor(DateTimeRange range) {
    final months = wholeMonthCount(range);
    if (months != null) return months.toDouble();
    final days = DateTime.utc(range.end.year, range.end.month, range.end.day)
            .difference(DateTime.utc(
                range.start.year, range.start.month, range.start.day))
            .inDays +
        1;
    return days / 30.4375;
  }

  /// Aralık uçları seçiciden saat bilgisiyle gelebilir; karşılaştırma gün
  /// bazındadır.
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
