import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';

/// Tek bir kategorinin dönemsel harcama sıçraması uyarısı.
class CategorySpike {
  final String categoryName;
  final double currentAmount;
  final double previousAmount;
  final double percentIncrease;

  /// Kıyaslanan iki pencerenin gün sayısı. Uyarı metni "geçen ay" değil
  /// "önceki N gün" demek zorunda: dönem ortasındayken kıyas tam ayla değil,
  /// eşdeğer uzunluktaki önceki pencereyle yapılır.
  final int windowDays;

  const CategorySpike({
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
    required this.percentIncrease,
    required this.windowDays,
  });
}

/// Saf-Dart istatistik servisi: bir işlem listesi + tarih penceresinden
/// "Akıllı İçgörüler" sayfasının özetlerini ve hedeflerini üretir.
///
/// Flutter/Hive bağımlılığı yoktur → kolay birim test edilir. Veriyi yalnızca
/// okur; para zincirine (syncBalance) veya deftere dokunmaz.
///
/// ## İki pencere
///
/// Sayfanın sayıları iki farklı pencereden gelir ve bu ayrım bilinçlidir:
///
///  • **Seçili aralığın tamamı** — TOPLAMLAR (gelir, gider, net, birikim
///    oranı, en büyük gider, en çok harcanan kategori). "Bu ay ne kadar
///    harcadım" sorusunun cevabı dönemin tamamıdır.
///  • **Yaşanmış pencere** (aralığın başından bugüne) — HIZLAR ve
///    KIYASLAR (günlük ortalama, haftanın günü, sıçrama, önceki dönem
///    rozetleri).
///
/// Ayrım olmadan ölçülen hata şuydu: ayın 3'ünde "Bu Ay" seçiliyken 3 günde
/// harcanan 900 TL 30'a bölünüyor ve sayfa **günde 30 TL** harcandığını
/// söylüyordu — gerçek 300 TL. Aynı kök nedenle sıçrama uyarısı da hiç
/// tetiklenmiyordu: 3 günlük harcama 31 günlük geçen ayla kıyaslanıyordu.
/// (Rapor sayfası aynı dersi `_previousPeriodWindow` ile ayrıca öğrendi.)
class TransactionAnalyticsService {
  const TransactionAnalyticsService();

  static const _reportService = TransactionReportService();

  /// Harcama sıçraması uyarısının varsayılan alt eşiği. Gürültüyü (birkaç
  /// liralık kalemin %300 "artışı") elemek içindir.
  ///
  /// Cüzdan bazlı para birimi (TRY/USD/EUR) nedeniyle mutlak bir eşik tam
  /// doğru olamaz — 50 USD ≠ 50 TL. Bu yüzden [analyze]'a parametre olarak
  /// geçilebilir; çağıran aktif cüzdanın birimine uygun bir değer verebilir.
  static const double defaultSpikeMinimumAmount = 50;

  /// Sıçrama sayılmak için gereken en az artış yüzdesi.
  static const double spikeThresholdPercent = 25;

  /// [rangeStart]–[rangeEnd] penceresini (gün bazında, iki uç da dahil) analiz
  /// eder.
  ///
  /// **Kuplaj hareketleri (transfer, borç ödemesi, yatırım alımı) tamamen
  /// dışarıda bırakılır.** `WalletMetricsService` bunları gerçek işlem olarak
  /// deftere yazıyor (`isSystem: true`) ve sayfa bunları süzmediği için
  /// ölçülen sonuç şuydu: nakitten bankaya 18.000 TL taşımak sayfaya
  /// "Gider 38.155 TL" (gerçeği 20.155), "En büyük harcama: Transfer",
  /// "En çok harcanan kategori: Transfer" yazdırıyordu. Rapor sayfası bu
  /// hareketleri zaten varsayılan olarak ayırıyor (bkz.
  /// [TransactionReportService.splitSystemMovements]); iki sayfa yan yana
  /// duran iki kaydırma sayfası olduğundan farklı rakam göstermeleri tek
  /// başına bir hata.
  ///
  /// [rangeIsBudgetPeriod], pencerenin içinde bulunulan bütçe dönemi olduğunu
  /// ("Bu Ay", "Bu Yıl") söyler; geriye dönük pencerelerde ("Son 7 Gün",
  /// "Son 3 Ay") false'tur. Yalnız günlük harcama hedefini etkiler —
  /// bkz. [TransactionInsights.dailySafeToSpend].
  ///
  /// [upcomingObligations], dönemin kalanında vadesi gelecek düzenli
  /// giderlerin toplamıdır (bkz. `RecurringOccurrences.plannedExpenseTotal`);
  /// günlük harcama hedefinden düşülür.
  TransactionInsights analyze(
    List<TransactionEntity> transactions, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
    DateTime? currentDateOverride,
    double spikeMinimumAmount = defaultSpikeMinimumAmount,
    bool rangeIsBudgetPeriod = false,
    Map<String, String> rootIndex = const {},
    double upcomingObligations = 0,
  }) {
    final startDay = _dayOnly(rangeStart);
    final endDay = _dayOnly(rangeEnd);
    final today = _dayOnly(currentDateOverride ?? DateTime.now());

    // Yaşanmış pencerenin son günü: aralık geleceğe uzanıyorsa bugün, geçmişte
    // bitiyorsa aralığın kendi sonu.
    final elapsedEnd = endDay.isAfter(today) ? today : endDay;

    final split = _reportService.splitSystemMovements(transactions);
    final spending = split.spending;

    final inRange = <TransactionEntity>[];
    var systemMovementCount = 0;
    for (final t in spending) {
      final d = _dayOnly(t.date);
      if (!d.isBefore(startDay) && !d.isAfter(endDay)) inRange.add(t);
    }
    for (final t in split.system) {
      final d = _dayOnly(t.date);
      if (!d.isBefore(startDay) && !d.isAfter(endDay)) systemMovementCount++;
    }

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> expenseByCategory = {};
    TransactionEntity? largestExpense;

    // Yaşanmış pencerenin kendi birikimleri — hız ve kıyas buradan çıkar.
    double elapsedExpense = 0;
    final Map<int, double> elapsedExpenseByWeekday = {}; // 1..7
    final Map<String, double> elapsedExpenseByCategory = {};

    for (final t in inRange) {
      if (t.isIncome) {
        totalIncome += t.amount;
        continue;
      }
      totalExpense += t.amount;
      // Kök seviyede toplanır: "en çok harcanan kategori" alt kalemlere
      // bölünseydi ("Elektrik", "Doğalgaz") hem anlamı zayıflar hem de
      // sıçrama tespiti bölünmüş tutarlarla eşiği geçemezdi.
      final root = rootIdOf(t.tag, rootIndex);
      expenseByCategory[root] = (expenseByCategory[root] ?? 0) + t.amount;
      if (largestExpense == null || t.amount > largestExpense.amount) {
        largestExpense = t;
      }

      if (!_dayOnly(t.date).isAfter(elapsedEnd)) {
        elapsedExpense += t.amount;
        elapsedExpenseByWeekday[t.date.weekday] =
            (elapsedExpenseByWeekday[t.date.weekday] ?? 0) + t.amount;
        elapsedExpenseByCategory[root] =
            (elapsedExpenseByCategory[root] ?? 0) + t.amount;
      }
    }

    // Pencere gün sayısı (iki uç dahil), en az 1.
    final span = endDay.difference(startDay).inDays + 1;
    final days = span < 1 ? 1 : span;

    // Yaşanmış gün sayısı. Aralık tamamen gelecekteyse henüz yaşanmış gün
    // yoktur; bölen olarak 1 kullanılır (pay da 0 olacağı için sonuç 0).
    final elapsedSpan = elapsedEnd.difference(startDay).inDays + 1;
    final elapsedDays = elapsedSpan < 1 ? 1 : (elapsedSpan > days ? days : elapsedSpan);
    final hasElapsed = !elapsedEnd.isBefore(startDay);

    final net = totalIncome - totalExpense;

    // En çok harcanan gün: TOPLAM değil, o günün ORTALAMASI.
    //
    // Ölçüldü: her gün tam 100 TL harcanan (yani tekdüze) bir Eylül'de sayfa
    // "En çok harcadığınız gün: Salı (500 TL)" diyordu. Fark davranış değil
    // TAKVİM — o ayda 5 Salı, 4 Perşembe var. Toplamı o günün pencere içinde
    // kaç kez geçtiğine bölmek yanlılığı kaldırır.
    final weekdayOccurrences =
        hasElapsed ? _weekdayOccurrences(startDay, elapsedEnd) : const <int, int>{};
    final Map<int, double> weekdayAverage = {
      for (final e in elapsedExpenseByWeekday.entries)
        if ((weekdayOccurrences[e.key] ?? 0) > 0)
          e.key: e.value / weekdayOccurrences[e.key]!,
    };
    final topWeekday = _argMax(weekdayAverage);
    final topCategory = _argMax(expenseByCategory);

    // Günde Ne Kadar Harcayabilirim? (Daily Safe-to-Spend)
    //
    // Yalnız pencerenin ÖNÜNDE gün varken anlamlıdır: "kalan neti kalan güne
    // böl". Bugünde ya da daha erken biten aralıklarda dağıtılacak gün
    // kalmadığından hedef üretilmez (0 döner). Aksi halde geriye dönük bir
    // pencerenin ("Geçen Ay", bugün biten "Son 7 Gün") tüm neti tek günün
    // harcama limitiymiş gibi gösterilirdi.
    //
    // Tek istisna bütçe döneminin son günüdür ([rangeIsBudgetPeriod]): "Bu Ay"
    // ayın 30'unda gerçekten "kalan net bugün harcanabilir" demektir. Ayrım
    // tarihlerden türetilemez — 31'inde biten "Bu Ay" ile bugün biten "Son 7
    // Gün" aynı görünür — bu yüzden niyeti çağıran bildirir.
    final int remainingDays;
    if (today.isBefore(startDay)) {
      remainingDays = days;
    } else if (today.isBefore(endDay)) {
      // Bugün hâlâ harcanabilir → sayıya dahil.
      remainingDays = endDay.difference(today).inDays + 1;
    } else if (rangeIsBudgetPeriod && today.isAtSameMomentAs(endDay)) {
      // Dönemin son günü: geriye yalnız bugün kaldı.
      remainingDays = 1;
    } else {
      remainingDays = 0;
    }

    // Bilinen yükümlülükler NETTEN düşülür: sayfa zaten düzenli ödemeleri
    // tespit ediyor, 5 gün sonra ödenecek kirayı görmezden gelen bir "günlük
    // limit" kullanıcıyı bilerek yanıltır.
    final spendableRemaining = net - upcomingObligations;
    final double? dailySafeToSpend = (remainingDays > 0 && spendableRemaining > 0)
        ? (spendableRemaining / remainingDays)
        : null;

    // Kategori Bazlı Harcama Sıçraması Uyarısı (Category Spike)
    final previousWindow = hasElapsed
        ? (
            start: startDay.subtract(Duration(days: elapsedDays)),
            end: startDay.subtract(const Duration(days: 1)),
          )
        : null;

    final CategorySpike? categorySpike = previousWindow == null
        ? null
        : _detectCategorySpike(
            transactions: spending,
            currentExpenseByCategory: elapsedExpenseByCategory,
            previousStart: previousWindow.start,
            previousEnd: previousWindow.end,
            windowDays: elapsedDays,
            minimumAmount: spikeMinimumAmount,
            rootIndex: rootIndex,
          );

    return TransactionInsights(
      transactionCount: inRange.length,
      systemMovementCount: systemMovementCount,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      net: net,
      previousTotals: previousWindow == null
          ? null
          : _reportService.calculateTotals(
              _reportService.filterByRange(
                spending,
                previousWindow.start,
                previousWindow.end,
              ),
            ),
      dailyAverageExpense: elapsedExpense / elapsedDays,
      elapsedDays: elapsedDays,
      topExpenseWeekday: topWeekday?.key,
      topExpenseWeekdayAverage: topWeekday?.value ?? 0,
      topExpenseWeekdayOccurrences:
          topWeekday == null ? 0 : (weekdayOccurrences[topWeekday.key] ?? 0),
      topExpenseCategory: topCategory?.key,
      topExpenseCategoryAmount: topCategory?.value ?? 0,
      largestExpense: largestExpense,
      // Gelir yokken oran TANIMSIZDIR. Eskiden 0'a düşüyordu ve 5.000 TL
      // gideri olan bir döneme "%0 birikim" yazılıyordu. (Rapor sayfası aynı
      // yalanı `_netSubtitle` ile ayrıca düzeltti.)
      savingsRate: totalIncome > 0 ? net / totalIncome : null,
      dailySafeToSpend: dailySafeToSpend,
      spendableRemaining: spendableRemaining,
      upcomingObligations: upcomingObligations,
      remainingDays: remainingDays,
      categorySpike: categorySpike,
    );
  }

  /// [start]–[end] arasında (iki uç dahil) her haftanın gününün kaç kez
  /// geçtiği.
  Map<int, int> _weekdayOccurrences(DateTime start, DateTime end) {
    final counts = <int, int>{};
    final total = end.difference(start).inDays + 1;
    // Tam haftalar herkese eşit dağılır; yalnız artan günler sayılır.
    final fullWeeks = total ~/ 7;
    for (var wd = 1; wd <= 7; wd++) {
      counts[wd] = fullWeeks;
    }
    for (var i = fullWeeks * 7; i < total; i++) {
      final wd = start.add(Duration(days: i)).weekday;
      counts[wd] = (counts[wd] ?? 0) + 1;
    }
    return counts;
  }

  CategorySpike? _detectCategorySpike({
    required List<TransactionEntity> transactions,
    required Map<String, double> currentExpenseByCategory,
    required DateTime previousStart,
    required DateTime previousEnd,
    required int windowDays,
    required double minimumAmount,
    required Map<String, String> rootIndex,
  }) {
    if (currentExpenseByCategory.isEmpty) return null;

    final Map<String, double> prevExpenseByCategory = {};
    for (final t in transactions) {
      if (!t.isExpense) continue;
      final d = _dayOnly(t.date);
      if (d.isBefore(previousStart) || d.isAfter(previousEnd)) continue;
      // Karşılaştırılan iki dönem AYNI seviyede toplanmalı.
      final root = rootIdOf(t.tag, rootIndex);
      prevExpenseByCategory[root] =
          (prevExpenseByCategory[root] ?? 0) + t.amount;
    }

    CategorySpike? maxSpike;
    for (final entry in currentExpenseByCategory.entries) {
      final category = entry.key;
      final currentAmt = entry.value;
      final prevAmt = prevExpenseByCategory[category] ?? 0;

      // Anlamlı sıçrama = en az [minimumAmount] harcama + önceki eşdeğer
      // pencereye göre [spikeThresholdPercent] artış. Alt eşik olmadan birkaç
      // liralık kalemler listeyi doldurur.
      if (currentAmt < minimumAmount || prevAmt <= 0) continue;
      final increase = ((currentAmt - prevAmt) / prevAmt) * 100;
      if (increase < spikeThresholdPercent) continue;
      if (maxSpike != null && increase <= maxSpike.percentIncrease) continue;
      maxSpike = CategorySpike(
        categoryName: category,
        currentAmount: currentAmt,
        previousAmount: prevAmt,
        percentIncrease: increase,
        windowDays: windowDays,
      );
    }

    return maxSpike;
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// En büyük değere sahip anahtarı döndürür; harita boşsa null.
  MapEntry<K, double>? _argMax<K>(Map<K, double> map) {
    MapEntry<K, double>? best;
    for (final e in map.entries) {
      if (best == null || e.value > best.value) best = e;
    }
    return best;
  }
}

/// Tek bir dönemin metinsel ve akıllı içgörü özeti. Saf veri; biçimlendirme
/// UI'da yapılır.
class TransactionInsights {
  /// Aralıktaki HARCAMA evreninin (kuplaj hareketleri hariç) kayıt sayısı.
  final int transactionCount;

  /// Aralıkta ayıklanan kuplaj/sistem hareketi sayısı. Sayfa "bu dönemde N
  /// transfer sayılmadı" diyebilsin diye taşınır; hiçbir toplama girmez.
  final int systemMovementCount;

  final double totalIncome;
  final double totalExpense;
  final double net;

  /// Önceki EŞDEĞER pencerenin toplamları (aynı gün sayısı, hemen öncesinde).
  /// Aralık tamamen gelecekteyse null.
  final ReportTotals? previousTotals;

  /// YAŞANMIŞ gün başına ortalama gider. Bölen [elapsedDays]'tir; aralığın
  /// tamamı değil.
  final double dailyAverageExpense;

  /// Aralığın başından bugüne (ya da aralık geçmişteyse sonuna) kaç gün
  /// geçtiği; en az 1.
  final int elapsedDays;

  /// Gün başına ortalaması en yüksek haftanın günü (1=Pazartesi .. 7=Pazar)
  /// ya da gider yoksa null.
  final int? topExpenseWeekday;

  /// O günün TEK BİR günü için ortalama harcaması.
  final double topExpenseWeekdayAverage;

  /// O günün yaşanmış pencerede kaç kez geçtiği (ortalamanın böleni).
  final int topExpenseWeekdayOccurrences;

  /// En çok harcanan kök kategori (tag); boş string olabilir, gider yoksa null.
  final String? topExpenseCategory;
  final double topExpenseCategoryAmount;

  /// Dönemin en büyük tek gideri ya da gider yoksa null.
  final TransactionEntity? largestExpense;

  /// (gelir − gider) / gelir. **Gelir 0 ise null** — oran tanımsızdır.
  /// Negatif olabilir.
  final double? savingsRate;

  /// Günde Ne Kadar Harcayabilirim? = [spendableRemaining] / [remainingDays].
  /// Harcanabilir tutar ≤ 0 ise ya da pencerenin önünde gün kalmadıysa null.
  final double? dailySafeToSpend;

  /// Net eksi bilinen yükümlülükler. Negatif olabilir — sayfa bu durumda
  /// hedef yerine açık uyarısı gösterir.
  final double spendableRemaining;

  /// Dönemin kalanında vadesi gelecek düzenli giderlerin toplamı.
  final double upcomingObligations;

  /// Pencerede bugün dahil kaç gün kaldığı. Aralık bugünde ya da daha önce
  /// bittiyse 0 — bu durumda [dailySafeToSpend] de null'dır.
  final int remainingDays;

  /// Önceki eşdeğer pencereye göre eşiği aşan kategori (varsa en yükseği).
  final CategorySpike? categorySpike;

  const TransactionInsights({
    required this.transactionCount,
    required this.systemMovementCount,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.previousTotals,
    required this.dailyAverageExpense,
    required this.elapsedDays,
    required this.topExpenseWeekday,
    required this.topExpenseWeekdayAverage,
    required this.topExpenseWeekdayOccurrences,
    required this.topExpenseCategory,
    required this.topExpenseCategoryAmount,
    required this.largestExpense,
    required this.savingsRate,
    required this.dailySafeToSpend,
    required this.spendableRemaining,
    required this.upcomingObligations,
    required this.remainingDays,
    required this.categorySpike,
  });

  bool get isEmpty => transactionCount == 0;
  bool get hasExpense => totalExpense > 0;

  /// Dönemin önünde gün var ama harcanacak bir şey kalmadı — hedef yerine
  /// açık uyarısı gösterilir.
  bool get isOverspent => remainingDays > 0 && spendableRemaining <= 0;
}
