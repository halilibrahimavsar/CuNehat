import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_series.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';

/// Fişin altındaki "NOT:" satırının parçaları.
///
/// Cümle AI ile değil sabit kurallarla kurulur (bkz. ai-layer kararı:
/// hesaplamaya AI girmez). Kurallar saf; metne dökmek arayüzün işi, yani
/// burada dil yok, yalnız ne söyleneceği var.
///
/// Notlarda TUTAR YOK: tutarlar gizliyken (göz düğmesi) fiş satırları
/// `MoneyText` ile örtülür, düz metindeki bir rakam ise örtülmezdi.
sealed class DayNote {
  const DayNote();
}

/// Günde gelir var: en büyük gelirin başlığı.
class IncomeDayNote extends DayNote {
  final String title;
  const IncomeDayNote(this.title);
}

/// Harcama, önceki 4 haftanın günlük ortalamasına göre.
class PaceNote extends DayNote {
  /// Yüzde fark; pozitif = ortalamanın üstünde.
  final int percent;
  const PaceNote(this.percent);

  /// Fark bu yüzdenin altındaysa "ortalamaya yakın" denir.
  static const int nearBand = 10;
  bool get isNear => percent.abs() < nearBand;
}

/// Günde para taşıma hareketi var ve toplamlara girmedi.
class MovedNote extends DayNote {
  const MovedNote();
}

/// Birden çok giderin en büyüğü.
class BiggestNote extends DayNote {
  final String title;
  const BiggestNote(this.title);
}

/// Bu güne kadar art arda harcamasız gün sayısı (≥ 2).
class StreakNote extends DayNote {
  final int days;
  const StreakNote(this.days);
}

/// Geçmiş gün, hiç kayıt yok (ve seri sayılacak kadar uzun değil).
class NoRecordsNote extends DayNote {
  const NoRecordsNote();
}

/// Gelecek gün: kaç planlı/tahmini hareket bekleniyor (0 olabilir).
/// [estimates]: tahmin katmanı açık mı (not mor bandı mı, yalnız planlı
/// kalemleri mi anlatır).
class FutureNote extends DayNote {
  final int count;
  final bool estimates;
  const FutureNote(this.count, {this.estimates = false});
}

/// Günlük gider toplamları (harcama evreni) — notların taban çizgisi.
Map<DateTime, double> dailyExpenseOf(List<TransactionWithBalance> ledger) {
  final out = <DateTime, double>{};
  for (final e in ledger) {
    final t = e.transaction;
    if (!t.isExpense || !isSpendingMovement(t)) continue;
    final d = dateOnly(t.date);
    out[d] = (out[d] ?? 0) + t.amount;
  }
  return out;
}

/// [day] için notlar, gösterim sırasıyla.
///
/// [dailyExpense] cüzdanın TÜM geçmişinden ([dailyExpenseOf]); [firstRecord]
/// defterin en eski günü — seri ondan geriye sayılmaz ("kurulumdan önceki
/// 400 gün harcamasız" demek yanlış olur).
List<DayNote> buildDayNotes({
  required BalanceDay day,
  required Map<DateTime, double> dailyExpense,
  required DateTime? firstRecord,
  bool estimates = false,
}) {
  if (day.isFuture) {
    return [FutureNote(day.events.length, estimates: estimates)];
  }

  final notes = <DayNote>[];
  final incomes = [
    for (final e in day.items)
      if (e.transaction.isIncome && isSpendingMovement(e.transaction)) e,
  ]..sort((a, b) => b.transaction.amount.compareTo(a.transaction.amount));
  if (incomes.isNotEmpty) {
    notes.add(IncomeDayNote(incomes.first.transaction.title));
  }

  if (day.expense > 0) {
    final pace = _paceOf(day, dailyExpense, firstRecord);
    if (pace != null) notes.add(pace);
  }

  if (day.moved != 0) notes.add(const MovedNote());

  final expenses = [
    for (final e in day.items)
      if (e.transaction.isExpense && isSpendingMovement(e.transaction)) e,
  ];
  if (incomes.isEmpty && expenses.length >= 2) {
    expenses
        .sort((a, b) => b.transaction.amount.compareTo(a.transaction.amount));
    notes.add(BiggestNote(expenses.first.transaction.title));
  }

  if (day.expense == 0) {
    final streak = _streakOf(day.day, dailyExpense, firstRecord);
    if (streak >= 2) {
      notes.add(StreakNote(streak));
    } else if (day.items.isEmpty) {
      notes.add(const NoRecordsNote());
    }
  }
  return notes;
}

/// Önceki 28 günün (gün dahil DEĞİL) günlük ortalaması. Pencerede en az
/// [_minSpendDays] harcamalı gün yoksa taban güvenilmez, not çıkmaz.
///
/// Pencere [firstRecord]'dan geriye UZANMAZ: kayıttan önceki günler "sıfır
/// harcama" değil, bilinmeyen günlerdir. Beş günlük cüzdanda 28'e bölmek
/// ortalamayı altıda birine indirir, sıradan bir gün "%800 üstünde" çıkardı.
PaceNote? _paceOf(
  BalanceDay day,
  Map<DateTime, double> dailyExpense,
  DateTime? firstRecord,
) {
  const window = 28;
  final floor = firstRecord == null ? null : dateOnly(firstRecord);
  var total = 0.0;
  var spendDays = 0;
  var tracked = 0;
  for (var i = 1; i <= window; i++) {
    final d = DateTime(day.day.year, day.day.month, day.day.day - i);
    if (floor != null && d.isBefore(floor)) break;
    tracked++;
    final v = dailyExpense[d] ?? 0;
    if (v > 0) {
      total += v;
      spendDays++;
    }
  }
  if (spendDays < _minSpendDays) return null;
  final average = total / tracked;
  if (average <= 0) return null;
  return PaceNote(((day.expense / average - 1) * 100).round());
}

const int _minSpendDays = 3;

/// [day] dahil geriye doğru art arda harcamasız gün sayısı.
int _streakOf(
  DateTime day,
  Map<DateTime, double> dailyExpense,
  DateTime? firstRecord,
) {
  if (firstRecord == null) return 0;
  final floor = dateOnly(firstRecord);
  var count = 0;
  for (var i = 0;; i++) {
    final d = DateTime(day.year, day.month, day.day - i);
    if (d.isBefore(floor)) break;
    if ((dailyExpense[d] ?? 0) > 0) break;
    count++;
  }
  return count;
}
