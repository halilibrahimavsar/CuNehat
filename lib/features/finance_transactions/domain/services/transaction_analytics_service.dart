import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Tek bir kategorinin dönemsel harcama sıçraması uyarısı.
class CategorySpike {
  final String categoryName;
  final double currentAmount;
  final double previousAmount;
  final double percentIncrease;

  const CategorySpike({
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
    required this.percentIncrease,
  });
}

/// Saf-Dart istatistik servisi: bir işlem listesi + tarih penceresinden
/// "Akıllı İçgörüler" sayfasının metinsel özetlerini ve akıllı hedeflerini üretir.
///
/// Flutter/Hive bağımlılığı yoktur → kolay birim test edilir. Veriyi yalnızca
/// okur; para zincirine (syncBalance) veya deftere dokunmaz. Sistem (otomatik)
/// işlemler de gerçek para hareketi olduğundan dahil edilir — Rapor sayfasıyla
/// tutarlı.
class TransactionAnalyticsService {
  const TransactionAnalyticsService();

  /// Harcama sıçraması uyarısının varsayılan alt eşiği. Gürültüyü (birkaç
  /// liralık kalemin %300 "artışı") elemek içindir.
  ///
  /// Cüzdan bazlı para birimi (TRY/USD/EUR) nedeniyle mutlak bir eşik tam
  /// doğru olamaz — 50 USD ≠ 50 TL. Bu yüzden [analyze]'a parametre olarak
  /// geçilebilir; çağıran aktif cüzdanın birimine uygun bir değer verebilir.
  static const double defaultSpikeMinimumAmount = 50;

  /// [rangeStart]–[rangeEnd] penceresini (gün bazında, iki uç da dahil) analiz
  /// eder.
  ///
  /// [rangeIsBudgetPeriod], pencerenin içinde bulunulan bütçe dönemi olduğunu
  /// ("Bu Ay", "Bu Yıl") söyler; geriye dönük pencerelerde ("Son 7 Gün",
  /// "Son 3 Ay") false'tur. Yalnız günlük harcama hedefini etkiler —
  /// bkz. [TransactionInsights.dailySafeToSpend].
  TransactionInsights analyze(
    List<TransactionEntity> transactions, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
    DateTime? currentDateOverride,
    double spikeMinimumAmount = defaultSpikeMinimumAmount,
    bool rangeIsBudgetPeriod = false,
    Map<String, String> rootIndex = const {},
  }) {
    final startDay = _dayOnly(rangeStart);
    final endDay = _dayOnly(rangeEnd);
    final today = _dayOnly(currentDateOverride ?? DateTime.now());

    final inRange = transactions.where((t) {
      final d = _dayOnly(t.date);
      return !d.isBefore(startDay) && !d.isAfter(endDay);
    }).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<int, double> expenseByWeekday = {}; // 1..7 (DateTime.weekday)
    final Map<String, double> expenseByCategory = {};
    TransactionEntity? largestExpense;

    for (final t in inRange) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
        expenseByWeekday[t.date.weekday] =
            (expenseByWeekday[t.date.weekday] ?? 0) + t.amount;
        // Kök seviyede toplanır: "en çok harcanan kategori" alt kalemlere
        // bölünseydi ("Elektrik", "Doğalgaz") hem anlamı zayıflar hem de
        // sıçrama tespiti bölünmüş tutarlarla %25 eşiğini geçemezdi.
        final root = rootIdOf(t.tag, rootIndex);
        expenseByCategory[root] = (expenseByCategory[root] ?? 0) + t.amount;
        if (largestExpense == null || t.amount > largestExpense.amount) {
          largestExpense = t;
        }
      }
    }

    // Pencere gün sayısı (iki uç dahil), en az 1.
    final span = endDay.difference(startDay).inDays + 1;
    final days = span < 1 ? 1 : span;

    final topWeekday = _argMax(expenseByWeekday);
    final topCategory = _argMax(expenseByCategory);
    final net = totalIncome - totalExpense;

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

    final double? dailySafeToSpend =
        (remainingDays > 0 && net > 0) ? (net / remainingDays) : null;

    // Kategori Bazlı Harcama Sıçraması Uyarısı (Category Spike)
    final CategorySpike? categorySpike = _detectCategorySpike(
      transactions: transactions,
      currentExpenseByCategory: expenseByCategory,
      startDay: startDay,
      endDay: endDay,
      spanDays: days,
      minimumAmount: spikeMinimumAmount,
      rootIndex: rootIndex,
    );

    return TransactionInsights(
      transactionCount: inRange.length,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      net: net,
      dailyAverageExpense: totalExpense / days,
      topExpenseWeekday: topWeekday?.key,
      topExpenseWeekdayAmount: topWeekday?.value ?? 0,
      topExpenseCategory: topCategory?.key,
      topExpenseCategoryAmount: topCategory?.value ?? 0,
      largestExpense: largestExpense,
      savingsRate: totalIncome > 0 ? net / totalIncome : 0,
      dailySafeToSpend: dailySafeToSpend,
      remainingDays: remainingDays,
      categorySpike: categorySpike,
    );
  }

  CategorySpike? _detectCategorySpike({
    required List<TransactionEntity> transactions,
    required Map<String, double> currentExpenseByCategory,
    required DateTime startDay,
    required DateTime endDay,
    required int spanDays,
    required double minimumAmount,
    required Map<String, String> rootIndex,
  }) {
    if (currentExpenseByCategory.isEmpty) return null;

    final prevEnd = startDay.subtract(const Duration(days: 1));
    final prevStart = prevEnd.subtract(Duration(days: spanDays - 1));

    final prevRange = transactions.where((t) {
      if (!t.isExpense) return false;
      final d = _dayOnly(t.date);
      return !d.isBefore(prevStart) && !d.isAfter(prevEnd);
    });

    final Map<String, double> prevExpenseByCategory = {};
    for (final t in prevRange) {
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

      // Anlamlı sıçrama = en az [minimumAmount] harcama + geçen döneme göre
      // %25 artış. Alt eşik olmadan birkaç liralık kalemler listeyi doldurur.
      if (currentAmt >= minimumAmount && prevAmt > 0) {
        final increase = ((currentAmt - prevAmt) / prevAmt) * 100;
        if (increase >= 25.0) {
          if (maxSpike == null || increase > maxSpike.percentIncrease) {
            maxSpike = CategorySpike(
              categoryName: category,
              currentAmount: currentAmt,
              previousAmount: prevAmt,
              percentIncrease: increase,
            );
          }
        }
      }
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
  final int transactionCount;
  final double totalIncome;
  final double totalExpense;
  final double net;
  final double dailyAverageExpense;

  /// En çok harcanan haftanın günü (1=Pazartesi .. 7=Pazar) ya da gider yoksa null.
  final int? topExpenseWeekday;
  final double topExpenseWeekdayAmount;

  /// En çok harcanan kategori (tag); boş string olabilir, gider yoksa null.
  final String? topExpenseCategory;
  final double topExpenseCategoryAmount;

  /// Dönemin en büyük tek gideri ya da gider yoksa null.
  final TransactionEntity? largestExpense;

  /// (gelir − gider) / gelir. Gelir 0 ise 0; negatif olabilir.
  final double savingsRate;

  /// Günde Ne Kadar Harcayabilirim? = net / [remainingDays].
  /// Net ≤ 0 ise ya da pencerenin önünde gün kalmadıysa null.
  final double? dailySafeToSpend;

  /// Pencerede bugün dahil kaç gün kaldığı. Aralık bugünde ya da daha önce
  /// bittiyse 0 — bu durumda [dailySafeToSpend] de null'dır.
  final int remainingDays;

  /// Geçen eşdeğer döneme göre %25+ artan kategori (varsa en yükseği).
  final CategorySpike? categorySpike;

  const TransactionInsights({
    required this.transactionCount,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.dailyAverageExpense,
    required this.topExpenseWeekday,
    required this.topExpenseWeekdayAmount,
    required this.topExpenseCategory,
    required this.topExpenseCategoryAmount,
    required this.largestExpense,
    required this.savingsRate,
    required this.dailySafeToSpend,
    required this.remainingDays,
    required this.categorySpike,
  });

  bool get isEmpty => transactionCount == 0;
  bool get hasExpense => totalExpense > 0;
}
