import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Saf-Dart istatistik servisi: bir işlem listesi + tarih penceresinden
/// "Akıllı İçgörüler" sayfasının metinsel özetlerini üretir.
///
/// Flutter/Hive bağımlılığı yoktur → kolay birim test edilir. Veriyi yalnızca
/// okur; para zincirine (syncBalance) veya deftere dokunmaz. Sistem (otomatik)
/// işlemler de gerçek para hareketi olduğundan dahil edilir — Rapor sayfasıyla
/// tutarlı.
class TransactionAnalyticsService {
  const TransactionAnalyticsService();

  /// [rangeStart]–[rangeEnd] penceresini (gün bazında, iki uç da dahil) analiz
  /// eder.
  TransactionInsights analyze(
    List<TransactionEntity> transactions, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final startDay = _dayOnly(rangeStart);
    final endDay = _dayOnly(rangeEnd);

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
    );
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

/// Tek bir dönemin metinsel içgörü özeti. Saf veri; biçimlendirme UI'da yapılır.
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
  });

  bool get isEmpty => transactionCount == 0;
  bool get hasExpense => totalExpense > 0;
}
