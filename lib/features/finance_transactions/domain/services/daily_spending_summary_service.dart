import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Bir günün para hareketi özeti. Saf veri; biçimlendirme UI'da yapılır.
class DaySummary {
  final double income;
  final double expense;
  final int count;

  const DaySummary({
    this.income = 0,
    this.expense = 0,
    this.count = 0,
  });

  /// Gelir − gider. Gider günü için negatiftir.
  double get net => income - expense;

  bool get isEmpty => count == 0;
  bool get hasExpense => expense > 0;
}

/// Saf-Dart günlük özet servisi: işlem listesini güne (yıl-ay-gün) göre
/// toplar. Takvim görünümünün ısı-haritası, net-tutar rozeti ve işlem
/// sayısı için tek kaynaktır.
///
/// Flutter/Hive bağımlılığı yoktur → kolay birim test edilir. Veriyi yalnızca
/// okur; para zincirine (syncBalance) dokunmaz. [TransactionAnalyticsService]
/// ile kardeştir ama farklı sorumluluk taşır (dönem özeti değil, gün-bazlı
/// dağılım).
class DailySpendingSummaryService {
  const DailySpendingSummaryService();

  /// İşlemleri `DateTime(yıl, ay, gün)` anahtarıyla toplar; saat bileşeni
  /// atılır, yani aynı günün tüm işlemleri tek özetde birleşir.
  Map<DateTime, DaySummary> buildDailySummaries(
    List<TransactionEntity> transactions,
  ) {
    final acc = <DateTime, _MutableSummary>{};
    for (final t in transactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      final entry = acc.putIfAbsent(day, _MutableSummary.new);
      if (t.isIncome) {
        entry.income += t.amount;
      } else {
        entry.expense += t.amount;
      }
      entry.count++;
    }

    return acc.map(
      (day, m) => MapEntry(
        day,
        DaySummary(income: m.income, expense: m.expense, count: m.count),
      ),
    );
  }
}

class _MutableSummary {
  double income = 0;
  double expense = 0;
  int count = 0;
}
