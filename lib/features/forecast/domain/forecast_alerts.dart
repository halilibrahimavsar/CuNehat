import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';

/// Erken uyarının türü — öncelik sırasıyla (nakit en acil).
enum ForecastWarningKind { cash, tempBudget, budget }

/// Tek bir erken uyarı. Metin bildirimi kuran yerde üretilir (saf veri).
class ForecastWarning {
  final ForecastWarningKind kind;

  /// Tekilleştirme anahtarı: aynı olay için İKİNCİ bildirim gitmez.
  final String key;
  final WalletForecast wallet;

  /// Bütçe uyarısında bütçe; nakitte `null`.
  final BudgetOutlook? budget;

  /// Nakitte eksiye düşüş günü, bütçede dolma günü.
  final DateTime date;

  const ForecastWarning({
    required this.kind,
    required this.key,
    required this.wallet,
    required this.date,
    this.budget,
  });
}

/// Erken uyarı kuralları — SAF.
///
/// Gürültü kapıları bilinçli: uyarı ancak "şimdi bir şey yapılabilir"
/// diyebiliyorsa anlamlı.
///  • Nakit: kart olmayan bir hesabın beklenen yolu [cashWindowDays] içinde
///    sıfırın altına iniyor VE bugün eksi değil (zaten ekside olan kullanıcı
///    bunu biliyor) VE maaş o günden önce gelmiyor. Hız yoksa yol yalnız
///    kesin olaylarla çizilir — uyarı yine çalışır, ama tahmine değil plana
///    dayanır.
///  • Aylık bütçe: hız VAR, dönemin en az [minElapsedDays] günü yaşanmış (ay
///    başında üç günlük veriyle "aşacaksın" demek kehanettir) ve bu hızla
///    dönem bitmeden en az [minLeadDays] gün önce doluyor.
///  • Tek seferlik bütçe: süren bütçe bu hızla bitişinden önce doluyor.
List<ForecastWarning> detectForecastWarnings(
  Iterable<WalletForecast> wallets, {
  required DateTime today,
  int cashWindowDays = 14,
  int minElapsedDays = 7,
  int minLeadDays = 3,
}) {
  final day = CardCycle.dateOnly(today);
  final out = <ForecastWarning>[];
  for (final w in wallets) {
    if (!w.isCard && w.path.isNotEmpty && w.path.first.expected >= 0) {
      final neg = w.firstNegative;
      final income = w.nextIncome;
      if (neg != null &&
          CardCycle.daysBetween(day, neg.day) <= cashWindowDays &&
          (income == null || neg.day.isBefore(income.date))) {
        // Anahtar ay bazında: eksiye düşüş günü her gün bir kaydığında yeni
        // bildirim gitmesin.
        out.add(ForecastWarning(
          kind: ForecastWarningKind.cash,
          key: 'cash:${w.walletId}:${neg.day.year}-${neg.day.month}',
          wallet: w,
          date: neg.day,
        ));
      }
    }
    if (w.pace == null) continue;
    for (final b in w.budgets) {
      if (b.status != BudgetOutlookStatus.atRisk) continue;
      final fill = b.fillDate;
      if (fill == null) continue;
      final start = b.periodStart.toIso8601String().substring(0, 10);
      if (b.isTemp) {
        if (!fill.isBefore(b.periodEnd)) continue;
        out.add(ForecastWarning(
          kind: ForecastWarningKind.tempBudget,
          key: 'temp:${w.walletId}:${b.id}',
          wallet: w,
          budget: b,
          date: fill,
        ));
      } else {
        final elapsed = CardCycle.daysBetween(b.periodStart, day);
        final lead = CardCycle.daysBetween(fill, b.periodEnd);
        if (elapsed < minElapsedDays || lead < minLeadDays) continue;
        out.add(ForecastWarning(
          kind: ForecastWarningKind.budget,
          key: 'budget:${w.walletId}:${b.id}:$start',
          wallet: w,
          budget: b,
          date: fill,
        ));
      }
    }
  }
  out.sort((a, b) {
    final k = a.kind.index.compareTo(b.kind.index);
    return k != 0 ? k : a.date.compareTo(b.date);
  });
  return out;
}

/// Haftalık özetin içeriği (saf veri).
class WeeklyDigest {
  /// Dönem sonu beklenen gider (hız yoksa `null`).
  final double? expectedExpense;

  /// Maaşa (yoksa ufka) kadar en dar gün.
  final BalancePoint? lowest;

  /// Önümüzdeki 7 günün planlı ÇIKIŞLARI.
  final int paymentCount;
  final double paymentTotal;

  const WeeklyDigest({
    required this.expectedExpense,
    required this.lowest,
    required this.paymentCount,
    required this.paymentTotal,
  });

  bool get isEmpty =>
      expectedExpense == null && lowest == null && paymentCount == 0;
}

/// [w]'nin [from] gününden itibaren 7 günlük özeti.
WeeklyDigest buildWeeklyDigest(WalletForecast w, {required DateTime from}) {
  final start = CardCycle.dateOnly(from);
  final end = DateTime(start.year, start.month, start.day + 7);
  var count = 0;
  var total = 0.0;
  for (final e in w.events) {
    if (e.isIncome || e.date.isBefore(start) || !e.date.isBefore(end)) {
      continue;
    }
    count++;
    total += -e.amount;
  }
  final period = w.period;
  return WeeklyDigest(
    expectedExpense: w.pace == null || period == null || w.isCard
        ? null
        : period.expectedExpense,
    lowest: w.isCard ? null : w.lowestPoint(until: w.nextIncome?.date),
    paymentCount: count,
    paymentTotal: total,
  );
}

/// Haftalık özetin zamanı: [now]'dan sonraki ilk Pazartesi 09:00 (bugün
/// Pazartesi ve saat 9'dan önceyse bugün).
DateTime nextDigestTime(DateTime now, {int hour = 9}) {
  final todayAt = DateTime(now.year, now.month, now.day, hour);
  if (now.weekday == DateTime.monday && now.isBefore(todayAt)) return todayAt;
  final daysAhead = (DateTime.monday - now.weekday + 7) % 7;
  final ahead = daysAhead == 0 ? 7 : daysAhead;
  return DateTime(now.year, now.month, now.day + ahead, hour);
}
