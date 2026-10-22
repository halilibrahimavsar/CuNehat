import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Bakiye hattındaki bir günün zamandaki yeri.
enum BalanceDayKind { past, today, future }

/// Bakiye hattının tek bir günü: çizginin noktası + o günün fişi.
///
/// Geçmiş ve bugün DEFTERDEN gelir (`balanceAfter` zinciri); gelecek
/// TAHMİNDEN (bkz. `ForecastEngine` bakiye yolu). İkisi aynı tipte durur ki
/// grafik ve fiş günün türünü bilmeden çizebilsin; ayrımı [kind] taşır.
class BalanceDay {
  final DateTime day;
  final BalanceDayKind kind;

  /// Gün sonu bakiyesi; gelecekte tahminin beklenen değeri. Tahmin henüz
  /// yoksa (yükleniyor ya da tahmin edilemiyor) gelecekte `null` — çizgi o
  /// günlere UZANMAZ, uydurma bir düz çizgi çizilmez.
  final double? balance;

  /// Tahmin bandı (yalnız gelecekte ve tahmin açıkken).
  final double? low;
  final double? high;

  /// Gelecekte yalnız kesin kalemlerle bakiye (plan). Plan görünümünde
  /// [balance] ile aynı; tahminde grafiğin ince planlı çizgisi.
  final double? planned;

  /// Gelecekte (tahmin açıkken) o gün hızdan beklenen serbest harcama;
  /// fişin "tahmini serbest harcama" satırı. İlk gelecek gün bugünün
  /// kalanını da taşır: fişin toplamı gün sonuyla TUTSUN.
  final double estimatedSpend;

  /// Günün defter satırları ESKİDEN YENİYE: fiş yukarıdan aşağı, günün
  /// akışıyla okunur. Gelecekte boş.
  final List<TransactionWithBalance> items;

  /// Günün planlı/tahmini hareketleri (yalnız gelecekte).
  final List<ForecastEvent> events;

  /// Harcama evreninde gelir/gider; para taşıma [moved]'da işaretli durur
  /// (bkz. [groupLedgerByDay] — aynı evren).
  final double income;
  final double expense;
  final double moved;

  const BalanceDay({
    required this.day,
    required this.kind,
    required this.balance,
    this.low,
    this.high,
    this.planned,
    this.estimatedSpend = 0,
    this.items = const [],
    this.events = const [],
    this.income = 0,
    this.expense = 0,
    this.moved = 0,
  });

  bool get isFuture => kind == BalanceDayKind.future;
  bool get isToday => kind == BalanceDayKind.today;
  bool get isEmpty => items.isEmpty && events.isEmpty;
  int get entryCount => items.length + events.length;
}

/// Dönemin bütün günleri, takvim sırasıyla (eskiden yeniye).
class BalanceLineSeries {
  final List<BalanceDay> days;

  /// Bugünün indeksi; dönem bugünü kapsamıyorsa -1.
  final int todayIndex;

  /// Tahmin katmanı açık mı: gelecek günler beklenen yolla (hız dahil, mor)
  /// mı, yalnız kesin kalemlerle (plan) mı kuruldu.
  final bool estimates;

  const BalanceLineSeries({
    required this.days,
    required this.todayIndex,
    this.estimates = false,
  });

  bool get isEmpty => days.isEmpty;

  /// [day] gününün indeksi; dönemde yoksa -1.
  int indexOf(DateTime day) {
    final d = dateOnly(day);
    for (var i = 0; i < days.length; i++) {
      if (days[i].day == d) return i;
    }
    return -1;
  }

  /// Açılışta seçilecek gün: bugün, yoksa dönem geçmişteyse son gün,
  /// gelecekteyse ilk gün.
  int get initialIndex {
    if (todayIndex >= 0) return todayIndex;
    if (days.isEmpty) return 0;
    return days.first.isFuture ? 0 : days.length - 1;
  }

  /// Grafiğin dikey ölçeği: bakiyeler + bant.
  (double, double)? get valueRange {
    double? lo, hi;
    void take(double? v) {
      if (v == null) return;
      lo = lo == null || v < lo! ? v : lo;
      hi = hi == null || v > hi! ? v : hi;
    }

    for (final d in days) {
      take(d.balance);
      take(d.low);
      take(d.high);
      take(d.planned);
    }
    if (lo == null) return null;
    return (lo!, hi!);
  }
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Kaydın bakiyeye etkisi (gelir +, gider −).
double signedAmount(TransactionWithBalance e) =>
    e.transaction.isIncome ? e.transaction.amount : -e.transaction.amount;

/// Dönemin bakiye hattını kurar.
///
/// [ledger] cüzdanın TAM defteri, yeniden eskiye (bkz. [buildLedger]):
/// dönemden önceki son kayıt, dönemin ilk gününden önceki bakiyeyi verir;
/// kaydı olmayan günler önceki günün bakiyesini taşır.
///
/// İleri tarihli defter satırları (kart taksitleri) bugünden sonraki günlere
/// defterden DEĞİL tahminden düşer: tahmin motoru onları zaten `scheduled`
/// olayı olarak sayıyor, ikisi birden gösterilse aynı taksit iki kez görünür.
///
/// [estimates] kapalıyken (plan) gelecek günler yalnız KESİN kalemlerle
/// kurulur: bakiye `planned`, bant yok, olaylar kesin kısmıyla (kesin kısmı
/// olmayan tahmin düşer; beklenen alacak bilgi olarak kalır ama toplamlara
/// girmez). Açıkken beklenen yol + bant + günün hız payı.
BalanceLineSeries buildBalanceLineSeries({
  required List<TransactionWithBalance> ledger,
  required double currentBalance,
  required DateTimeRange period,
  required DateTime now,
  required bool estimates,
  List<BalancePoint> forecastPath = const [],
  List<ForecastEvent> forecastEvents = const [],
}) {
  final start = dateOnly(period.start);
  final end = dateOnly(period.end);
  final today = dateOnly(now);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  if (end.isBefore(start)) {
    return BalanceLineSeries(
        days: const [], todayIndex: -1, estimates: estimates);
  }

  final byDay = <DateTime, List<TransactionWithBalance>>{};
  double? before;
  for (final e in ledger) {
    final day = dateOnly(e.transaction.date);
    if (day.isBefore(start)) {
      // Defter yeniden eskiye: dönemden önceki İLK rastlanan en yenisidir.
      before ??= e.balanceAfter;
      continue;
    }
    if (day.isAfter(end)) continue;
    byDay.putIfAbsent(day, () => []).add(e);
  }
  // Dönemden önce kayıt yoksa açılış, en eski kaydın ÖNCESİDİR.
  before ??= ledger.isEmpty
      ? currentBalance
      : ledger.last.balanceAfter - signedAmount(ledger.last);

  final pathByDay = {for (final p in forecastPath) dateOnly(p.day): p};
  final eventsByDay = <DateTime, List<ForecastEvent>>{};
  for (final e in forecastEvents) {
    eventsByDay.putIfAbsent(dateOnly(e.date), () => []).add(e);
  }

  final days = <BalanceDay>[];
  var todayIndex = -1;
  var running = before;
  for (var i = 0;; i++) {
    // DateTime(y, m, d + i): yaz saati geçişinde `add(Duration(days:))`
    // günü kaydırır.
    final day = DateTime(start.year, start.month, start.day + i);
    if (day.isAfter(end)) break;

    if (day.isAfter(today)) {
      final p = pathByDay[day];
      final all = eventsByDay[day] ?? const <ForecastEvent>[];
      final events = estimates
          ? all
          : [
              for (final e in all)
                if (e.hasKnownPart || e.kind == ForecastEventKind.receivable) e,
            ];
      double income = 0, expense = 0, moved = 0;
      for (final e in events) {
        // Bakiyeye giren kısım: planda kesin kısım, tahminde beklenen yol
        // payı (alacakta ikisi de 0).
        final a = estimates ? e.pathExpected : e.knownAmount;
        if (a == 0) continue;
        if (e.countsAsSpending) {
          expense -= a;
        } else if (a > 0 && e.kind == ForecastEventKind.recurringIncome) {
          income += a;
        } else {
          moved += a;
        }
      }
      var spend = 0.0;
      if (estimates && p != null) {
        spend = p.paceSpend;
        if (day == tomorrow) spend += pathByDay[today]?.paceSpend ?? 0;
      }
      days.add(BalanceDay(
        day: day,
        kind: BalanceDayKind.future,
        balance: p == null ? null : (estimates ? p.expected : p.planned),
        low: estimates ? p?.low : null,
        high: estimates ? p?.high : null,
        planned: p?.planned,
        estimatedSpend: spend,
        events: events,
        income: income,
        expense: expense,
        moved: moved,
      ));
      continue;
    }

    final items = (byDay[day] ?? const <TransactionWithBalance>[])
        .reversed
        .toList(growable: false);
    double income = 0, expense = 0, moved = 0;
    for (final e in items) {
      final t = e.transaction;
      if (!isSpendingMovement(t)) {
        moved += signedAmount(e);
      } else if (t.isIncome) {
        income += t.amount;
      } else if (t.isExpense) {
        expense += t.amount;
      }
    }
    if (items.isNotEmpty) running = items.last.balanceAfter;
    final isToday = day == today;
    if (isToday) todayIndex = days.length;
    days.add(BalanceDay(
      day: day,
      kind: isToday ? BalanceDayKind.today : BalanceDayKind.past,
      balance: running,
      items: items,
      income: income,
      expense: expense,
      moved: moved,
    ));
  }
  return BalanceLineSeries(
      days: days, todayIndex: todayIndex, estimates: estimates);
}
