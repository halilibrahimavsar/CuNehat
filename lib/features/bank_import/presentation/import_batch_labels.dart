import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:intl/intl.dart';

// "Son içe aktarımlar" satırındaki iki tarihin ETİKETLİ yazımı.
//
// Eskiden satır "11.10.2026 20:57 · 16.09.2026–15.10.2026" basıyordu: üç
// rakam tarih, hiçbirinin ne olduğu yazmıyor. Hangisi içe aktardığım gün,
// hangisi ekstrenin dönemi? (kullanıcı şikâyeti, 12 Eki 2026). Şimdi her
// biri kendi satırında, ne olduğu yazılı ve ay adıyla.

/// Partideki işlemlerin kapsadığı günler: "16 Eyl – 15 Eki"; içinde
/// bulunulan yıl değilse yıl da yazılır. Tek günse yalnız o gün.
String importBatchRangeLabel(DateTime first, DateTime last, {DateTime? now}) {
  final locale = Intl.defaultLocale;
  final start = dayOf(first);
  final end = dayOf(last);
  final thisYear = (now ?? DateTime.now()).year;
  final withYear = start.year != thisYear || end.year != thisYear;
  if (isSameDayValue(start, end)) {
    return (withYear ? DateFormat.yMMMd(locale) : DateFormat.MMMd(locale))
        .format(start);
  }
  final label = dateRangeLabel(start, end, locale);
  // Yıl değişen aralıkta `dateRangeLabel` iki uca da yılı zaten yazar.
  return withYear && start.year == end.year ? '$label ${end.year}' : label;
}

/// İçe aktarımın yapıldığı an: "Bugün 20:57", "Dün 09:10", "11 Eki 20:57".
String importedAtLabel(DateTime at, AppLocalizations l10n, {DateTime? now}) {
  final locale = Intl.defaultLocale;
  final today = dayOf(now ?? DateTime.now());
  final day = dayOf(at);
  final time = DateFormat.Hm(locale).format(at);
  if (isSameDayValue(day, today)) return '${l10n.txPeriodToday} $time';
  if (isSameDayValue(day, today.subtract(const Duration(days: 1)))) {
    return '${l10n.txPeriodYesterday} $time';
  }
  final date = (day.year == today.year
          ? DateFormat.MMMd(locale)
          : DateFormat.yMMMd(locale))
      .format(day);
  return '$date $time';
}
