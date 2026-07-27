import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:flutter/material.dart';

/// Rapor sayfasındaki tek bir kategori dilimi: ad, dönem toplamı, o kategoriye
/// düşen işlemler ve dilim rengi.
class CategoryData {
  final String name;
  final double totalAmount;
  final List<TransactionEntity> transactions;
  final Color color;

  /// Pasta eşiklemesinde toplanan küçük kategorilerin sentetik "Diğer" kovası.
  /// Kullanıcının gerçek bir "Diğer" kategorisi olabildiğinden eşleştirme
  /// isimle değil bu bayrakla yapılır.
  final bool isOther;

  const CategoryData(
    this.name,
    this.totalAmount,
    this.transactions,
    this.color, {
    this.isOther = false,
  });
}

/// Rapor sayfasının kategori kırılımını üreten yardımcı: seçili tarih aralığı,
/// bütçe limitleri ve renk paletini tek yerde tutar.
///
/// Detay bottom sheet'i, sayfanın State'ine kapanan dört ayrı closure yerine
/// bu nesneyi alır; böylece TransactionBloc her değiştiğinde kırılımı kendisi
/// yeniden hesaplayabilir ve State'e bağımlı kalmaz.
class ReportCategoryDataBuilder {
  static const _service = TransactionReportService();

  static const _expensePalette = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.deepOrangeAccent,
    Colors.amberAccent,
  ];
  static const _incomePalette = [
    Colors.greenAccent,
    Colors.tealAccent,
    Colors.blueAccent,
    Colors.indigoAccent,
  ];

  /// Kalıcı paletin dışına taşan kategoriler için ayrılan, kategori
  /// renkleriyle çakışmayacak sabit "Diğer" rengi.
  static const _otherColor = Colors.blueGrey;

  /// Pasta diliminde ayrı gösterilmek için gereken en düşük pay (%).
  static const _pieThresholdPercent = 3.0;

  final DateTimeRange range;

  /// Cüzdanın bütçe limitleri. `spentAmount` kullanılmaz — rapor sayfası
  /// harcamayı seçili [range]'a göre ayrıca hesaplar (BudgetRepository yalnız
  /// limitleri döner ve "bu ay" varsayımı taşımaz).
  final List<BudgetEntity> budgets;

  /// Sentetik "Diğer" kovasının yerelleştirilmiş adı. Yapıcıda alınır ki bu
  /// sınıf BuildContext'e bağımlı olmasın.
  final String otherCategoryLabel;

  const ReportCategoryDataBuilder({
    required this.range,
    required this.budgets,
    required this.otherCategoryLabel,
  });

  List<TransactionEntity> filterByRange(List<TransactionEntity> transactions) =>
      _service.filterByRange(transactions, range.start, range.end);

  List<CategoryData> buildFull(
    List<TransactionEntity> transactions, {
    required bool isExpense,
  }) {
    final breakdowns = _service.buildCategoryBreakdown(
      transactions,
      isExpense: isExpense,
    );

    return [
      for (int i = 0; i < breakdowns.length; i++)
        CategoryData(
          breakdowns[i].name,
          breakdowns[i].totalAmount,
          breakdowns[i].transactions,
          _colorForIndex(i, isExpense),
        ),
    ];
  }

  /// Payı [_pieThresholdPercent]'in altında kalan kategorileri tek "Diğer"
  /// diliminde toplar. Toplam değişmez; yalnız dilimler yeniden gruplanır.
  List<CategoryData> buildPie(List<CategoryData> fullData) {
    if (fullData.isEmpty) return fullData;

    final total =
        fullData.fold<double>(0.0, (sum, item) => sum + item.totalAmount);
    if (total <= 0) return fullData;

    final major = <CategoryData>[];
    double otherTotal = 0;
    final otherTx = <TransactionEntity>[];

    for (final item in fullData) {
      final percent = (item.totalAmount / total) * 100;
      if (percent >= _pieThresholdPercent) {
        major.add(item);
      } else {
        otherTotal += item.totalAmount;
        otherTx.addAll(item.transactions);
      }
    }

    if (otherTx.isEmpty) return major;

    return [
      ...major,
      CategoryData(otherCategoryLabel, otherTotal, otherTx, _otherColor,
          isOther: true),
    ];
  }

  /// [tag] kategorisi için, o an görüntülenen [range]'a göre bütçe
  /// ilerlemesini hesaplar. Bütçe tanımlı değilse null döner.
  ({double progress, bool isExceeded, double limit})? budgetProgressFor(
    String tag,
    double spentInRange,
  ) {
    for (final b in budgets) {
      if (b.categoryId == tag) {
        if (b.limitAmount <= 0) return null;
        return (
          progress: (spentInRange / b.limitAmount).clamp(0.0, 1.0),
          isExceeded: spentInRange > b.limitAmount,
          limit: b.limitAmount,
        );
      }
    }
    return null;
  }

  Color _colorForIndex(int i, bool isExpense) {
    final palette = isExpense ? _expensePalette : _incomePalette;
    if (i < palette.length) return palette[i];

    final overflow = i - palette.length;
    const stepsPerCycle = 8;
    final hueStart = isExpense ? 0.0 : 95.0;
    final hueWidth = isExpense ? 45.0 : 150.0;
    final hue =
        (hueStart + (overflow % stepsPerCycle) * (hueWidth / stepsPerCycle)) %
            360;
    final cycle = overflow ~/ stepsPerCycle;
    final lightness = (0.42 + (cycle % 3) * 0.12).clamp(0.3, 0.72);
    return HSLColor.fromAHSL(1, hue, 0.65, lightness).toColor();
  }
}
