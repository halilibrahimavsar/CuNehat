import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Zaman serisinin çözünürlüğü.
enum ReportBucketUnit { day, week, month }

/// Serideki tek bir zaman kovası: `[start, endExclusive)` aralığı ve
/// içindeki gelir/gider toplamı.
///
/// İşlemi OLMAYAN kovalar da üretilir ve sıfır taşır — serinin tamamı budur.
class ReportBucket {
  /// Kovanın ilk günü, gece yarısı.
  final DateTime start;

  /// Kovanın bitişi (dahil değil).
  final DateTime endExclusive;

  final double income;
  final double expense;

  const ReportBucket({
    required this.start,
    required this.endExclusive,
    this.income = 0,
    this.expense = 0,
  });

  double get net => income - expense;

  /// Kovada hiç hareket var mı? (Eksen etiketi/nokta kararları için.)
  bool get isEmpty => income == 0 && expense == 0;
}

/// Bir dönemin zaman serisi: kovalar + dönem başındaki gerçek bakiye.
class ReportSeries {
  final ReportBucketUnit unit;

  /// Dönemin TAMAMINI kaplayan kovalar, zaman sırasında. Boş kovalar dahil.
  final List<ReportBucket> buckets;

  /// Dönem BAŞLAMADAN önceki gerçek cüzdan bakiyesi. Birikimli bakiye
  /// çizgisinin çıpası budur; sıfır verilirse çizgi "dönem içi birikimli
  /// net"e döner (bkz. [ReportSeriesService.build]).
  final double openingBalance;

  const ReportSeries({
    required this.unit,
    required this.buckets,
    this.openingBalance = 0,
  });

  bool get isEmpty => buckets.isEmpty;

  /// Hiçbir kovada hareket yok mu?
  bool get hasNoActivity => buckets.every((b) => b.isEmpty);

  /// Kova sonlarındaki birikimli bakiye: `openingBalance + Σ net`.
  ///
  /// Uzunluğu [buckets] ile birebirdir; i. eleman i. kovanın SONUNDAKİ
  /// bakiyedir.
  List<double> get cumulativeBalance {
    final out = <double>[];
    var running = openingBalance;
    for (final b in buckets) {
      running += b.net;
      out.add(running);
    }
    return out;
  }
}

/// Rapor grafiklerinin zaman serisini üreten saf-Dart servis.
///
/// **Neden var:** grafikler eskiden işlemleri güne göre gruplayıp `Map`'in
/// sıralı anahtarlarını x=0,1,2… diye çiziyordu. Yani eksen takvim değil,
/// "işlem OLAN günler" listesiydi: 1 Haziran ve 25 Haziran'daki iki işlem
/// yan yana iki çubuk oluyor, aradaki 23 gün yok sayılıyordu. Bakiye
/// çizgisinin eğimi de bu yüzden anlamsızdı — "bir ayda yavaş erime" ile
/// "iki günde çöküş" aynı çiziliyordu.
///
/// Burada kovalar dönemin TAMAMINI kaplar; hareketsiz kovalar sıfırla durur.
class ReportSeriesService {
  const ReportSeriesService();

  /// Bir kova için ayrılan en dar yer (iki çubuk + nefes payı). Otomatik
  /// çözünürlük seçimi buna göre yapılır.
  static const double kMinBucketWidth = 9;

  /// Otomatik çözünürlük tavanları — gün sayısına göre.
  ///
  /// Bir ay (28-31 gün) GÜNLÜK kalır: "hangi gün ne harcadım" sorusu bu
  /// grafiğin varlık sebebi. Üç ay haftalığa, yıl aylığa iner; yoksa
  /// "Bu Yıl" 365 çubuk demek olurdu (~0,8px/çubuk).
  static const int kMaxDailyDays = 35;
  static const int kMaxWeeklyDays = 182;

  /// [range] uzunluğuna göre varsayılan çözünürlük.
  ReportBucketUnit autoUnitFor(DateTime start, DateTime end) {
    final days = dayCount(start, end);
    if (days <= kMaxDailyDays) return ReportBucketUnit.day;
    if (days <= kMaxWeeklyDays) return ReportBucketUnit.week;
    return ReportBucketUnit.month;
  }

  /// `[start, end]` kapalı aralığındaki gün sayısı (ikisi de dahil).
  int dayCount(DateTime start, DateTime end) {
    final s = _midnight(start);
    final e = _midnight(end);
    return e.difference(s).inDays + 1;
  }

  /// [unit] çözünürlüğünde aralığın kaç kova ürettiği. Seçicinin bir
  /// çözünürlüğü kapatıp kapatmayacağına buna bakarak karar verilir.
  int bucketCountFor(DateTime start, DateTime end, ReportBucketUnit unit) {
    var cursor = _bucketStart(start, unit);
    final last = _midnight(end);
    var count = 0;
    while (!cursor.isAfter(last)) {
      cursor = _nextBucketStart(cursor, unit);
      count++;
    }
    return count;
  }

  /// Seriyi kurar.
  ///
  /// [inRange] zaten aralığa süzülmüş işlemlerdir (bkz.
  /// `TransactionReportService.filterByRange`); aralık dışı bir kayıt
  /// gelirse kendi kovasına düşmez, sessizce atlanır.
  ///
  /// [openingBalance] dönem başındaki gerçek bakiyedir. Defter değişmezi
  /// `balance = openingBalance + Σ signed(işlemler)` olduğu için çağıran
  /// taraf bunu "cüzdanın açılış bakiyesi + dönemden ÖNCEKİ işlemlerin
  /// toplamı" olarak hesaplar.
  ReportSeries build({
    required List<TransactionEntity> inRange,
    required DateTime start,
    required DateTime end,
    ReportBucketUnit? unit,
    double openingBalance = 0,
  }) {
    final resolved = unit ?? autoUnitFor(start, end);
    final last = _midnight(end);

    // Kova iskeleti: dönemin tamamı, boşlar dahil.
    final starts = <DateTime>[];
    var cursor = _bucketStart(start, resolved);
    while (!cursor.isAfter(last)) {
      starts.add(cursor);
      cursor = _nextBucketStart(cursor, resolved);
    }
    if (starts.isEmpty) {
      return ReportSeries(
        unit: resolved,
        buckets: const [],
        openingBalance: openingBalance,
      );
    }

    final income = List<double>.filled(starts.length, 0);
    final expense = List<double>.filled(starts.length, 0);

    // Kova sınırları epoch mikrosaniyesine çevrilir ve işlemler bu SAYILARLA
    // karşılaştırılır.
    //
    // Neden: eskiden her işlem için `_bucketStart` iki `DateTime` kuruyordu
    // ve `DateTime(y, m, d)` yerel saat dönüşümü yaptığı için ucuz değil.
    // Ölçüldü (2.345 işlem, 12 kova): işlem başına ~4,7 µs, yani tek seri
    // ~11 ms — iki seri kuran bir türetme için 22 ms. Sınırlar kova başına
    // BİR kez kurulunca aynı iş ~1 ms'ye iniyor.
    final bounds = [
      for (final start in starts) start.microsecondsSinceEpoch,
      _nextBucketStart(starts.last, resolved).microsecondsSinceEpoch,
    ];

    for (final t in inRange) {
      final index = _bucketIndexOf(bounds, t.date.microsecondsSinceEpoch);
      if (index == null) continue;
      if (t.isIncome) {
        income[index] += t.amount;
      } else if (t.isExpense) {
        expense[index] += t.amount;
      }
    }

    return ReportSeries(
      unit: resolved,
      openingBalance: openingBalance,
      buckets: [
        for (var i = 0; i < starts.length; i++)
          ReportBucket(
            start: starts[i],
            endExclusive: _nextBucketStart(starts[i], resolved),
            income: income[i],
            expense: expense[i],
          ),
      ],
    );
  }

  /// Son [months] takvim ayını kapsayan pencere — [anchor]'ın ayıyla biter.
  ///
  /// Aylık trend kartı SEÇİLİ ARALIKTAN bağımsızdır: "bu ay ne harcadım"
  /// sorusunun cevabı raporun geri kalanında zaten var; buradaki soru "daha
  /// çok mu harcıyorum" ve o soru daha uzun bir ufuk ister.
  ///
  /// `DateTimeRange` DEĞİL kayıt döner: bu servis saf Dart'tır (Flutter
  /// bağımlılığı yok → kolay birim test edilir), dönüşümü sunum katmanı yapar.
  ({DateTime start, DateTime end}) monthsWindow(DateTime anchor, int months) {
    assert(months > 0);
    return (
      start: DateTime(anchor.year, anchor.month - (months - 1), 1),
      end: DateTime(anchor.year, anchor.month + 1, 0),
    );
  }

  /// Dönem BAŞLAMADAN önceki bakiye: `walletOpeningBalance + Σ signed(önceki)`.
  ///
  /// [all] cüzdanın TÜM işlemleridir (aralığa süzülmemiş). Cüzdanın açılış
  /// bakiyesi bilinmiyorsa 0 verilir; seri o zaman sabit bir fark kadar
  /// kayar ama eğimi ve şekli doğru kalır.
  double openingBalanceFor({
    required List<TransactionEntity> all,
    required DateTime start,
    double walletOpeningBalance = 0,
  }) {
    final startDay = _midnight(start);
    var sum = walletOpeningBalance;
    for (final t in all) {
      if (!t.date.isBefore(startDay)) continue;
      sum += t.isIncome ? t.amount : -t.amount;
    }
    return sum;
  }

  // ── kova aritmetiği ───────────────────────────────────────────────────────

  /// [date]'in düştüğü kovanın ilk günü.
  DateTime _bucketStart(DateTime date, ReportBucketUnit unit) {
    final d = _midnight(date);
    return switch (unit) {
      ReportBucketUnit.day => d,
      // Hafta Pazartesi başlar (ISO); `weekday` Pazartesi=1.
      ReportBucketUnit.week =>
        DateTime(d.year, d.month, d.day - (d.weekday - 1)),
      ReportBucketUnit.month => DateTime(d.year, d.month, 1),
    };
  }

  /// Takvim aritmetiği — `Duration` DEĞİL: ay uzunlukları eşit değil ve
  /// gün toplamı yaz saati uygulanan bölgelerde kayabilir.
  DateTime _nextBucketStart(DateTime bucketStart, ReportBucketUnit unit) =>
      switch (unit) {
        ReportBucketUnit.day =>
          DateTime(bucketStart.year, bucketStart.month, bucketStart.day + 1),
        ReportBucketUnit.week =>
          DateTime(bucketStart.year, bucketStart.month, bucketStart.day + 7),
        ReportBucketUnit.month =>
          DateTime(bucketStart.year, bucketStart.month + 1, 1),
      };

  /// [bounds] (uzunluk = kova sayısı + 1) içinde [stamp]'in düştüğü kova;
  /// aralık dışındaysa null.
  ///
  /// İkili arama: bir yılın işlemleri × 366 kova doğrusal aramada kare
  /// karmaşıklığa çıkıyordu.
  int? _bucketIndexOf(List<int> bounds, int stamp) {
    if (stamp < bounds.first || stamp >= bounds.last) return null;
    var lo = 0;
    var hi = bounds.length - 2;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      if (stamp < bounds[mid]) {
        hi = mid - 1;
      } else if (stamp >= bounds[mid + 1]) {
        lo = mid + 1;
      } else {
        return mid;
      }
    }
    return null;
  }

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
}
