import 'dart:math' as math;

import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';

/// Bir taksitin ödeme durumu. Gecikme AYRI bir eksendir ([InstallmentProgress
/// .isOverdue]) — kısmen ödenmiş bir taksit aynı anda gecikmiş de olabilir.
enum InstallmentStatus {
  /// Taksit tutarının tamamı karşılandı.
  paid,

  /// Bir kısmı karşılandı, tamamı değil.
  partial,

  /// Bu taksite hiç ödeme düşmedi.
  unpaid,
}

/// Taksit planındaki tek bir satır.
class InstallmentProgress {
  /// 1'den başlayan taksit sırası.
  final int number;

  /// Planlanan ödeme tarihi.
  final DateTime dueDate;

  /// Taksitin kendi tutarı (toplam / vade).
  final double scheduledAmount;

  /// Ödemelerden BU taksite düşen kısım.
  final double paidAmount;

  final InstallmentStatus status;

  /// Tamamı ödenmemiş ve vadesi geçmiş.
  final bool isOverdue;

  const InstallmentProgress({
    required this.number,
    required this.dueDate,
    required this.scheduledAmount,
    required this.paidAmount,
    required this.status,
    required this.isOverdue,
  });

  /// Kalan tutar (kuruşa yuvarlı).
  double get remainingAmount => roundToCents(scheduledAmount - paidAmount);
}

/// Taksit planını **ödenen TUTARA** göre kurar.
///
/// Eskiden durum ödeme SAYISINA bakıyordu (`i < payments.length`), bu yüzden
/// plan gerçekle ilgisiz hâle gelebiliyordu:
///   * 12×1.000 ₺ borca 3 kez 100 ₺ ödendiğinde ilk üç taksit "ödendi"
///     görünüyordu (toplam 300 ₺, tek taksiti bile karşılamıyor);
///   * "Tümünü öde" ile borç tek kayıtta kapandığında yalnız 1. taksit
///     ödenmiş, kalan 11'i "gecikmiş" görünüyordu.
///
/// Ödemeler taksitlere sırayla dağıtılır: kümülatif ödenen tutar önce 1.
/// taksiti doldurur, artan 2.'ye taşar. Ödemelerin hangi tarihte ya da kaç
/// parçada yapıldığı önemsizdir — aradan geçen kısmi/fazla ödemeler planı
/// kaydırmaz.
List<InstallmentProgress> buildInstallmentPlan({
  required double totalDebtAmount,
  required int termMonths,
  required DateTime startDate,
  required double totalPaidAmount,
  DateTime? now,
}) {
  if (termMonths <= 0) return const [];

  final reference = now ?? DateTime.now();
  final monthly = roundToCents(totalDebtAmount / termMonths);

  return [
    for (var i = 0; i < termMonths; i++)
      _buildRow(
        index: i,
        termMonths: termMonths,
        monthly: monthly,
        totalDebtAmount: totalDebtAmount,
        totalPaidAmount: totalPaidAmount,
        startDate: startDate,
        reference: reference,
      ),
  ];
}

/// [debt] üzerinden kısayol; toplam/vade/ödenen tek kaynaktan okunur.
List<InstallmentProgress> buildInstallmentPlanFor(DebtEntity debt,
        {DateTime? now}) =>
    buildInstallmentPlan(
      totalDebtAmount: debt.totalDebtAmount,
      termMonths: debt.termMonths,
      startDate: debt.startDate,
      totalPaidAmount: debt.totalPaidAmount,
      now: now,
    );

InstallmentProgress _buildRow({
  required int index,
  required int termMonths,
  required double monthly,
  required double totalDebtAmount,
  required double totalPaidAmount,
  required DateTime startDate,
  required DateTime reference,
}) {
  // Son taksit yuvarlama artığını üstlenir: `monthly × vade` toplamı
  // tutmayabilir (1.000/3 → 333,33×3 = 999,99) ve son taksit hiç
  // "ödendi" olamazdı.
  //
  // Artık 0'da tabanlanır: yuvarlama YUKARI da kaçabilir (1 ₺ / 36 ay →
  // 0,03 × 35 = 1,05 > 1,00) ve son satıra eksi tutar düşerdi. Negatif üst
  // sınır aşağıdaki `clamp`i ArgumentError'a çevirip planın çizildiği build'i
  // kırıyordu (kırmızı ekran).
  final scheduled = index == termMonths - 1
      ? math.max(
          0.0, roundToCents(totalDebtAmount - monthly * (termMonths - 1)))
      : monthly;

  final coveredBefore = monthly * index;
  final paidHere =
      roundToCents((totalPaidAmount - coveredBefore).clamp(0.0, scheduled));

  final InstallmentStatus status;
  if (moneyGte(paidHere, scheduled)) {
    status = InstallmentStatus.paid;
  } else if (moneyIsPositive(paidHere)) {
    status = InstallmentStatus.partial;
  } else {
    status = InstallmentStatus.unpaid;
  }

  final dueDate = addMonthsClamped(startDate, index + 1);

  return InstallmentProgress(
    number: index + 1,
    dueDate: dueDate,
    scheduledAmount: scheduled,
    paidAmount: paidHere,
    status: status,
    isOverdue: status != InstallmentStatus.paid && dueDate.isBefore(reference),
  );
}
