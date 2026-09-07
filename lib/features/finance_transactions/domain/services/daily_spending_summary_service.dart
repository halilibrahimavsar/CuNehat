import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';

/// Bir günün para hareketi özeti. Saf veri; biçimlendirme UI'da yapılır.
///
/// **İki farklı evren taşır ve bu bilinçlidir.** Tutarlar (`income`/`expense`)
/// HARCAMA evrenindendir (bkz. [isSpendingMovement]): gün şeridinin çubuğu
/// "o gün ne harcandı"yı ölçer, transfer günü en koyu gün olamaz. Sayı
/// (`count`) ise defterin TAMAMINI sayar, çünkü şeridin altındaki liste o
/// satırları gösteriyor — sayıyı da süzmek, transferden ibaret bir günü
/// ekran okuyucuya "işlem yok" diye duyurup listede duran satırla çelişirdi.
class DaySummary {
  /// Harcama evrenindeki gelir (kuplaj hariç).
  final double income;

  /// Harcama evrenindeki gider (kuplaj hariç).
  final double expense;

  /// Gündeki TÜM defter satırları (kuplaj dahil) — liste ile birebir.
  final int count;

  /// [count]'un kuplaj hareketi olan kısmı; "sayılmadı" dipnotu buradan.
  final int systemCount;

  const DaySummary({
    this.income = 0,
    this.expense = 0,
    this.count = 0,
    this.systemCount = 0,
  });

  /// Gelir − gider. Gider günü için negatiftir. Kuplaj hareketleri girmez.
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
      // Satır her hâlükârda SAYILIR (liste onu gösteriyor); yalnız TUTARI
      // harcama evrenine giriyorsa toplanır. Bkz. [DaySummary] sınıf notu.
      entry.count++;
      if (!isSpendingMovement(t)) {
        entry.systemCount++;
        continue;
      }
      if (t.isIncome) {
        entry.income += t.amount;
      } else {
        entry.expense += t.amount;
      }
    }

    return acc.map(
      (day, m) => MapEntry(
        day,
        DaySummary(
          income: m.income,
          expense: m.expense,
          count: m.count,
          systemCount: m.systemCount,
        ),
      ),
    );
  }
}

class _MutableSummary {
  double income = 0;
  double expense = 0;
  int count = 0;
  int systemCount = 0;
}
