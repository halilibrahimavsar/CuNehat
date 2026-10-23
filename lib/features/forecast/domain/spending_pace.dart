import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';

/// Serbest harcama hızı: "planlı olmayan" giderin günlük ortalaması.
///
/// **Neden yalnız serbest harcama:** düzenli işlemler ve taksitler tahminde
/// zaten KESİN olay olarak tarihleriyle yer alıyor. Onlar hızın içinde de
/// kalsaydı kira hem 1 Kasım'da hem de "günde 400 ₺"nin içinde iki kez
/// düşerdi. Bu yüzden şunlar hıza GİRMEZ:
///  • kuplaj hareketleri (transfer, borç ödemesi, yatırım alımı, kart
///    ödemesi) — harcama değil;
///  • düzenli şablon onayıyla oluşan kayıtlar (`origin == recurring`);
///  • taksit satırları (`installmentGroupId` dolu);
///  • tek seferlik büyük kalemler (bkz. [oneOffs]) — 9.000 ₺'lik bir telefon
///    90 günlük ortalamayı günde 100 ₺ şişirir ve her gün yeniden "harcanır".
///
/// **Bilinçli eksik:** `origin` alanından önce onaylanmış eski düzenli
/// kayıtlar ayırt edilemez ve hızın içinde kalır. Arayüz bunu "Nasıl
/// hesaplandı?" sayfasında yazar.
///
/// Gelir hızı TAHMİN EDİLMEZ: düzensiz gelir (prim, satış) "her ay gelir"
/// sayılırsa harcanabilir para olduğundan fazla görünür. Gelir yalnız
/// düzenli şablonlardan gelir — temkinli taraf.
class SpendingPace {
  /// Gözlem penceresi (iki uç dahil, gün çözünürlüğü).
  final DateTime windowStart;
  final DateTime windowEnd;
  final int observedDays;

  /// Haftanın günü (1 = Pazartesi … 7) → o günün ortalama harcaması.
  final Map<int, double> weekdayMean;

  /// Kategori (`tag`) → günlük ortalama (haftanın günü ağırlıksız).
  final Map<String, double> dailyByTag;

  /// Bant oranları: yaşanmış 7 günlük toplamların 20. ve 80. yüzdeliği /
  /// ortalaması. Beklenen harcama × oran = kötümser/iyimser harcama.
  final double lowRatio;
  final double highRatio;

  /// Hıza katılmayan tek seferlik büyük kalemler (açıklama sayfası adlarıyla
  /// listeler).
  final List<TransactionEntity> oneOffs;

  /// Hıza katılmayan, planlı tarafta zaten sayılan kayıtların sayısı.
  final int recurringExcluded;
  final int installmentExcluded;

  const SpendingPace({
    required this.windowStart,
    required this.windowEnd,
    required this.observedDays,
    required this.weekdayMean,
    required this.dailyByTag,
    required this.lowRatio,
    required this.highRatio,
    this.oneOffs = const [],
    this.recurringExcluded = 0,
    this.installmentExcluded = 0,
  });

  /// Gözlem penceresinin en uzunu.
  static const int defaultWindowDays = 90;

  /// Güven kapısı: bundan az gün gözlemlenmişse tahmin üretilmez.
  static const int minObservedDays = 14;

  /// Tek seferlik eşiğin parçaları: tek kalem medyanın bu katını VE
  /// pencere toplamının bu payını aşarsa tek seferliktir.
  static const double oneOffMedianFactor = 5;
  static const double oneOffShareOfTotal = 0.10;

  /// Kırpma için gereken en az kalem (azında medyan anlamsız).
  static const int oneOffMinSample = 8;

  double get dailyMean {
    if (weekdayMean.isEmpty) return 0;
    var sum = 0.0;
    for (var d = 1; d <= 7; d++) {
      sum += weekdayMean[d] ?? 0;
    }
    return sum / 7;
  }

  /// [day] için beklenen harcama.
  double expectedOn(DateTime day) => weekdayMean[day.weekday] ?? 0;

  /// [tags] kümesindeki kategorilerin günlük toplam ortalaması.
  double dailyForTags(Set<String> tags) {
    var sum = 0.0;
    for (final t in tags) {
      sum += dailyByTag[t] ?? 0;
    }
    return sum;
  }

  /// Hıza katılan harcama mı (bkz. sınıf belgesi). Tarih ve tek seferlik
  /// kırpma burada değil.
  static bool isPaceSpending(TransactionEntity t) =>
      !t.isIncome &&
      isSpendingMovement(t) &&
      t.origin != TransactionOrigin.recurring &&
      t.installmentGroupId == null;

  /// [ledger]'dan hız çıkarır; yeterli gözlem yoksa `null`.
  ///
  /// Pencere DÜNDE biter: bugün yarım bir gündür ve onu tam gün saymak
  /// sabah açan kullanıcının hızını düşürürdü. Pencere kullanıcının İLK
  /// kaydından önceye uzanmaz ([trackingSince]) — İçgörü'deki dersin aynısı:
  /// kayıt tutulmayan günler "harcanmayan gün" sayılırsa hız düşük çıkar.
  static SpendingPace? fit(
    Iterable<TransactionEntity> ledger, {
    required DateTime today,
    DateTime? trackingSince,
    int windowDays = defaultWindowDays,
    int minDays = minObservedDays,
  }) {
    // Hiç kayıt yoksa gözlem de yoktur. Eskiden `null` "pencerenin tamamı
    // gözlendi" sayılıyor ve yeni kullanıcıya 90 günlük SIFIR harcama hızı
    // çıkıyordu: Gelecek sayfası güven kapısını göstermiyor, haftalık özet
    // "dönem sonu gider ~0 ₺" yazıyordu.
    if (trackingSince == null) return null;
    final day = CardCycle.dateOnly(today);
    final windowEnd = DateTime(day.year, day.month, day.day - 1);
    var windowStart = DateTime(day.year, day.month, day.day - windowDays);
    final since = CardCycle.dateOnly(trackingSince);
    if (since.isAfter(windowStart)) windowStart = since;
    final observed = CardCycle.daysBetween(windowStart, windowEnd) + 1;
    if (observed < minDays) return null;

    final windowEndExclusive = day;
    final candidates = <TransactionEntity>[];
    var recurringExcluded = 0;
    var installmentExcluded = 0;
    for (final t in ledger) {
      if (t.isIncome || !isSpendingMovement(t)) continue;
      if (t.date.isBefore(windowStart) ||
          !t.date.isBefore(windowEndExclusive)) {
        continue;
      }
      if (t.origin == TransactionOrigin.recurring) {
        recurringExcluded++;
        continue;
      }
      if (t.installmentGroupId != null) {
        installmentExcluded++;
        continue;
      }
      candidates.add(t);
    }

    // Tek seferlik kırpma.
    final oneOffs = <TransactionEntity>[];
    final kept = <TransactionEntity>[];
    if (candidates.length >= oneOffMinSample) {
      final amounts = [for (final t in candidates) t.amount]..sort();
      final median = amounts.length.isOdd
          ? amounts[amounts.length ~/ 2]
          : (amounts[amounts.length ~/ 2 - 1] + amounts[amounts.length ~/ 2]) /
              2;
      final total = amounts.fold(0.0, (s, a) => s + a);
      final threshold =
          _max(median * oneOffMedianFactor, total * oneOffShareOfTotal);
      for (final t in candidates) {
        (t.amount > threshold ? oneOffs : kept).add(t);
      }
    } else {
      kept.addAll(candidates);
    }

    // Haftanın günü ortalaması: toplam / o günün pencerede kaç kez geçtiği
    // (Eylül'de 5 Salı, 4 Perşembe varken toplam yanıltır).
    final byWeekday = <int, double>{};
    final byTag = <String, double>{};
    final byDay = <int, double>{}; // pencere başından gün indeksi → toplam
    for (final t in kept) {
      byWeekday[t.date.weekday] = (byWeekday[t.date.weekday] ?? 0) + t.amount;
      byTag[t.tag] = (byTag[t.tag] ?? 0) + t.amount;
      final idx = CardCycle.daysBetween(windowStart, t.date);
      byDay[idx] = (byDay[idx] ?? 0) + t.amount;
    }
    final occurrences = <int, int>{};
    for (var i = 0; i < observed; i++) {
      final d =
          DateTime(windowStart.year, windowStart.month, windowStart.day + i);
      occurrences[d.weekday] = (occurrences[d.weekday] ?? 0) + 1;
    }
    final weekdayMean = <int, double>{
      for (var w = 1; w <= 7; w++)
        w: (occurrences[w] ?? 0) == 0
            ? 0
            : (byWeekday[w] ?? 0) / occurrences[w]!,
    };
    final dailyByTag = {
      for (final e in byTag.entries) e.key: e.value / observed,
    };

    // Bant: kayan 7 günlük toplamlar.
    final weekSums = <double>[];
    for (var start = 0; start + 6 < observed; start++) {
      var sum = 0.0;
      for (var i = start; i < start + 7; i++) {
        sum += byDay[i] ?? 0;
      }
      weekSums.add(sum);
    }
    var lowRatio = 1.0;
    var highRatio = 1.0;
    if (weekSums.length >= 2) {
      final mean = weekSums.fold(0.0, (s, a) => s + a) / weekSums.length;
      if (mean > 0) {
        weekSums.sort();
        lowRatio = (_percentile(weekSums, 0.2) / mean).clamp(0.0, 1.0);
        highRatio = _max(1.0, _percentile(weekSums, 0.8) / mean);
      }
    }

    return SpendingPace(
      windowStart: windowStart,
      windowEnd: windowEnd,
      observedDays: observed,
      weekdayMean: weekdayMean,
      dailyByTag: dailyByTag,
      lowRatio: lowRatio,
      highRatio: highRatio,
      oneOffs: oneOffs,
      recurringExcluded: recurringExcluded,
      installmentExcluded: installmentExcluded,
    );
  }

  /// Güven kapısına kaç TAKVİM günü kaldı (0 = açık), en çok [minDays].
  /// İleri tarihli bir ilk kayıt sayacı şişirmesin ("39 gün daha" — QA D2):
  /// gözlem bugünden önce başlayamaz.
  static int daysUntilReady(DateTime? trackingSince, DateTime today,
      {int minDays = minObservedDays}) {
    if (trackingSince == null) return minDays;
    final observed = CardCycle.daysBetween(
        CardCycle.dateOnly(trackingSince), CardCycle.dateOnly(today));
    return (minDays - observed).clamp(0, minDays);
  }

  /// Sıralı listede en yakın sıra yüzdeliği.
  static double _percentile(List<double> sorted, double p) {
    final rank = (p * (sorted.length - 1)).round();
    return sorted[rank.clamp(0, sorted.length - 1)];
  }

  static double _max(double a, double b) => a > b ? a : b;
}
