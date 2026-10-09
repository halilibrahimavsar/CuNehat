import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';

/// Raporun üstündeki zaman çizgisinin ölçüsü.
enum TrendMetric { expense, income, net, balance }

/// Zaman çizgisinin saf hesapları: birikimli toplam ve önceki dönemin
/// hizalanması.
///
/// **Neden birikimli:** günlük gider çizgisi testere dişidir — maaş ve kira
/// günleri her şeyi ezer, "bu ay nasıl gidiyorum" sorusu okunmaz. Birikimli
/// çizgi o soruyu doğrudan yanıtlar ve önceki dönemin çizgisiyle üst üste
/// konunca "geçen ayın bu noktasında ne kadar harcamıştım" tek bakışta
/// görülür. Kova kova tutar dokununca tooltip'te ve çubuk görünümündedir.
abstract final class ReportTrend {
  /// Bir kovanın ölçüye göre tutarı. Bakiye için kovanın NET hareketi.
  static double amountOf(ReportBucket bucket, TrendMetric metric) =>
      switch (metric) {
        TrendMetric.expense => bucket.expense,
        TrendMetric.income => bucket.income,
        TrendMetric.net || TrendMetric.balance => bucket.net,
      };

  /// İlk [count] kovanın (verilmezse hepsinin) birikimli değerleri.
  ///
  /// Bakiye [ReportSeries.openingBalance]'tan başlar (defter değişmezi);
  /// diğer ölçüler dönem içinde 0'dan.
  static List<double> cumulative(
    ReportSeries series,
    TrendMetric metric, {
    int? count,
  }) {
    final n = count == null || count > series.buckets.length
        ? series.buckets.length
        : count;
    var running = metric == TrendMetric.balance ? series.openingBalance : 0.0;
    return [
      for (var i = 0; i < n; i++)
        running += amountOf(series.buckets[i], metric),
    ];
  }

  /// Önceki dönemin birikimli çizgisi, güncel eksenin [length] kovasına
  /// İNDEKSLE hizalanmış (1 Ekim ↔ 1 Eylül). Önceki dönem daha uzunsa
  /// kırpılır, kısaysa çizgi erken biter.
  ///
  /// Önceki dönemde hiç hareket yoksa null: sıfırda yatan kesikli çizgi
  /// "geçen ay hiç harcamadın" demez, "kıyas yok" demektir — çizilmez.
  /// Bakiye için de null: iki dönemin bakiyesi zaten birbirinin devamıdır.
  static List<double>? alignedPrevious(
    ReportSeries? previous,
    TrendMetric metric,
    int length,
  ) {
    if (previous == null || metric == TrendMetric.balance) return null;
    final relevant =
        previous.buckets.take(length).any((b) => amountOf(b, metric) != 0);
    if (!relevant) return null;
    return cumulative(previous, metric, count: length);
  }
}
