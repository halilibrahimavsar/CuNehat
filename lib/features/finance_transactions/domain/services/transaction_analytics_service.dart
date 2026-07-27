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
/// okur; para zincirine (syncBalance) veya deftere dokunmaz.
class TransactionAnalyticsService {
  const TransactionAnalyticsService();

  /// [rangeStart]–[rangeEnd] penceresini (gün bazında, iki uç da dahil) analiz
  /// eder.
  TransactionInsights analyze(
    List<TransactionEntity> transactions, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
    DateTime? currentDateOverride,
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
        expenseByCategory[t.tag] = (expenseByCategory[t.tag] ?? 0) + t.amount;
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
    int remainingDays;
    if (today.isBefore(startDay)) {
      remainingDays = days;
    } else if (today.isAfter(endDay)) {
      remainingDays = 1;
    } else {
      final rem = endDay.difference(today).inDays + 1;
      remainingDays = rem < 1 ? 1 : rem;
    }

    final double? dailySafeToSpend = net > 0 ? (net / remainingDays) : null;

    // Kategori Bazlı Harcama Sıçraması Uyarısı (Category Spike)
    final CategorySpike? categorySpike = _detectCategorySpike(
      transactions: transactions,
      currentExpenseByCategory: expenseByCategory,
      startDay: startDay,
      endDay: endDay,
      spanDays: days,
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
      prevExpenseByCategory[t.tag] =
          (prevExpenseByCategory[t.tag] ?? 0) + t.amount;
    }

    CategorySpike? maxSpike;
    for (final entry in currentExpenseByCategory.entries) {
      final category = entry.key;
      final currentAmt = entry.value;
      final prevAmt = prevExpenseByCategory[category] ?? 0;

      // Anlamlı bir harcama sıçraması için en az 50 TL harcama ve geçen döneme göre %25+ artış
      if (currentAmt >= 50 && prevAmt > 0) {
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

  MapEntry<K, double>? _argMax<K>(Map<K, double> map) {
    MapEntry<K, double>? best;
    for (final e in map.entries) {
      if (best == null || e.value > best.value) best = e;
    }
    return best;
  }
}

/// Tek bir dönemin metinsel ve akıllı içgörü özeti.
class TransactionInsights {
  final int transactionCount;
  final double totalIncome;
  final double totalExpense;
  final double net;
  final double dailyAverageExpense;

  final int? topExpenseWeekday;
  final double topExpenseWeekdayAmount;

  final String? topExpenseCategory;
  final double topExpenseCategoryAmount;

  final TransactionEntity? largestExpense;
  final double savingsRate;

  /// Günde Ne Kadar Harcayabilirim? (Kalan net bakiye / Kalan gün sayısı)
  final double? dailySafeToSpend;
  final int remainingDays;

  /// Kategori Harcama Sıçraması Uyarısı (%25+ artış gösteren kategori)
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
