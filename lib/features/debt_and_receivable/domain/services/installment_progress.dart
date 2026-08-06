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

/// Eşit taksit tutarı (son satır hariç).
double _monthlyOf(double totalDebtAmount, int termMonths) =>
    roundToCents(totalDebtAmount / termMonths);

/// [index]. taksitin (0 tabanlı) planlanan tutarı.
///
/// Son taksit yuvarlama artığını üstlenir: `monthly × vade` toplamı
/// tutmayabilir (1.000/3 → 333,33×3 = 999,99) ve son taksit hiç "ödendi"
/// olamazdı.
///
/// 0'da tabanlanır: yuvarlama YUKARI da kaçabilir (1 ₺ / 36 ay → 0,03 × 35 =
/// 1,05 > 1,00) ve son satıra eksi tutar düşerdi. Negatif üst sınır aşağıdaki
/// `clamp`i ArgumentError'a çevirip planın çizildiği build'i kırıyordu.
double installmentScheduledAmount({
  required double totalDebtAmount,
  required int termMonths,
  required int index,
}) {
  final monthly = _monthlyOf(totalDebtAmount, termMonths);
  if (index != termMonths - 1) return monthly;
  return math.max(
      0.0, roundToCents(totalDebtAmount - monthly * (termMonths - 1)));
}

/// [index]. taksitin (0 tabanlı) vade tarihi.
DateTime installmentDueDate(DateTime startDate, int index) =>
    addMonthsClamped(startDate, index + 1);

/// Taksit planını **ana paraya sayılan TUTARA** göre kurar.
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
///
/// [principalPaidAmount] gecikme faizine sayılan kısmı İÇERMEZ: faiz borcun
/// kendisini azaltmaz (bkz. `Payment.overdueInterestPart`).
List<InstallmentProgress> buildInstallmentPlan({
  required double totalDebtAmount,
  required int termMonths,
  required DateTime startDate,
  required double principalPaidAmount,
  DateTime? now,
}) {
  if (termMonths <= 0) return const [];

  final reference = now ?? DateTime.now();
  final monthly = _monthlyOf(totalDebtAmount, termMonths);

  return [
    for (var i = 0; i < termMonths; i++)
      _buildRow(
        index: i,
        termMonths: termMonths,
        monthly: monthly,
        totalDebtAmount: totalDebtAmount,
        principalPaidAmount: principalPaidAmount,
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
      principalPaidAmount: debt.principalPaidAmount,
      now: now,
    );

InstallmentProgress _buildRow({
  required int index,
  required int termMonths,
  required double monthly,
  required double totalDebtAmount,
  required double principalPaidAmount,
  required DateTime startDate,
  required DateTime reference,
}) {
  final scheduled = installmentScheduledAmount(
    totalDebtAmount: totalDebtAmount,
    termMonths: termMonths,
    index: index,
  );

  final coveredBefore = monthly * index;
  final paidHere =
      roundToCents((principalPaidAmount - coveredBefore).clamp(0.0, scheduled));

  final InstallmentStatus status;
  if (moneyGte(paidHere, scheduled)) {
    status = InstallmentStatus.paid;
  } else if (moneyIsPositive(paidHere)) {
    status = InstallmentStatus.partial;
  } else {
    status = InstallmentStatus.unpaid;
  }

  final dueDate = installmentDueDate(startDate, index);

  return InstallmentProgress(
    number: index + 1,
    dueDate: dueDate,
    scheduledAmount: scheduled,
    paidAmount: paidHere,
    status: status,
    isOverdue: status != InstallmentStatus.paid && dueDate.isBefore(reference),
  );
}

// ---------------------------------------------------------------------------
// Liste ALLOKE ETMEYEN sorgular
//
// Kart listesi ve hatırlatma senkronu her borç için bu soruları soruyor; 600
// satırlık bir planı kurup atmak gereksiz. Aşağıdakiler aynı aritmetiği
// (`installmentScheduledAmount` + kümülatif kapsama) tek döngüde kullanır.
// ---------------------------------------------------------------------------

/// Tamamı kapanmış taksit sayısı.
int paidInstallmentCount(DebtEntity debt) {
  final term = debt.termMonths;
  if (term <= 0) return 0;
  final total = debt.totalDebtAmount;
  final paid = debt.principalPaidAmount;
  final monthly = _monthlyOf(total, term);

  var count = 0;
  for (var i = 0; i < term; i++) {
    final scheduled = installmentScheduledAmount(
        totalDebtAmount: total, termMonths: term, index: i);
    if (!moneyGte(paid - monthly * i, scheduled)) break;
    count++;
  }
  return count;
}

/// Sıradaki ödenmemiş taksitin vadesi; kapanmış borçta ve tüm taksitleri
/// dolmuş planda `null`.
///
/// Tek taksitli kayıtlarda (kişisel borç, "diğer") plan yerine kaydın kendi
/// [DebtEntity.dueDate]'i geçerlidir; o da boş olabilir (vade opsiyonel).
DateTime? nextUnpaidInstallmentDate(DebtEntity debt) {
  if (debt.isPaid) return null;
  if (debt.termMonths <= 1) return debt.dueDate;
  final paidCount = paidInstallmentCount(debt);
  if (paidCount >= debt.termMonths) return null;
  return installmentDueDate(debt.startDate, paidCount);
}

/// Vadesi geçmiş ve tamamı ödenmemiş EN AZ BİR taksit var mı?
///
/// Kart rozeti bunu kullanır: eskiden yalnız kaydın SON vadesine bakılıyordu,
/// bu yüzden 12 taksitin 6'sı gecikmiş bir borç tertemiz görünüyordu.
bool hasOverdueInstallment(DebtEntity debt, {DateTime? now}) {
  final next = nextUnpaidInstallmentDate(debt);
  return next != null && next.isBefore(now ?? DateTime.now());
}
