import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:equatable/equatable.dart';

enum DebtType { bankLoan, installmentDebt, personalDebt, otherDebt }

class Payment extends Equatable {
  /// Kaydın kalıcı kimliği. Ödeme düzenleme/silme bu kimlikle hedeflenir;
  /// liste indeksi güvenilir değildir (liste bloc'tan yeniden çekilebilir).
  final String id;
  final DateTime date;

  /// Cüzdandan gerçekten çıkan tutar. Deftere bu yazılır.
  final double amount;

  /// [amount]'ın gecikme faizine sayılan kısmı.
  ///
  /// Ödemeler önce birikmiş gecikme faizini kapatır, kalanı ana paraya sayar.
  /// Borcun kalanı yalnız faiz-dışı kısımla azalır ([DebtEntity
  /// .principalPaidAmount]) — böylece `remainingAmount`/`isPaid` zamanla
  /// büyüyen bir tahakkuktan etkilenmez, donmuş ve kararlı kalır.
  final double overdueInterestPart;

  final String? notes;

  const Payment({
    required this.id,
    required this.date,
    required this.amount,
    this.overdueInterestPart = 0,
    this.notes,
  });

  /// Bu ödemenin ana paraya sayılan kısmı.
  double get principalPart => roundToCents(amount - overdueInterestPart);

  Payment copyWith({
    String? id,
    DateTime? date,
    double? amount,
    double? overdueInterestPart,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      overdueInterestPart: overdueInterestPart ?? this.overdueInterestPart,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, date, amount, overdueInterestPart, notes];
}

class DebtEntity extends Equatable {
  final String? id;
  final String userId;
  final String walletId;
  final String title;
  final String counterparty; // Banka adı veya Kişi adı (UI'daki Subtitle)
  final DebtType type;

  /// Toplam geri ödemenin hangi yöntemle hesaplandığı. Kayıtla saklanır;
  /// [interestRate]'in değerinden TÜRETİLMEZ (bkz. [DebtCalcMode]).
  final DebtCalcMode calcMode;

  final double principalAmount;
  final double interestRate;
  final int termMonths;

  /// Gecikme faizi (aylık %). Vadesi geçmiş taksitlerin ödenmemiş kısmına
  /// günlük oransal işler; bkz. `computeOverdueInterest`.
  final double overdueInterestRate;

  final DateTime startDate;
  final DateTime? dueDate;
  final List<Payment> payments;
  final bool isPaid;
  final String? notes;

  /// Kayıt anında dondurulan toplam geri ödeme. Her yazım yolu bunu
  /// `DebtRepaymentCalculator` ile hesaplar; borcun büyüklüğü sonradan
  /// yeniden türetilmez, bu yüzden zamanla ya da formül değişikliğiyle
  /// kaymaz.
  final double expectedTotalAmount;

  /// Ana para cüzdana nakit olarak girdi mi?
  /// true  → borç alınırken para ele geçti; anapara bakiyeye gelir yazılır
  ///         (silmede geri alınır).
  /// false → borç karşılığında ürün/hizmet alındı; nakit ele geçmedi, bakiye
  ///         değişmez. Yalnız taksit/ödemeler gider olarak deftere düşer.
  final bool principalToWallet;

  const DebtEntity({
    this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.counterparty,
    required this.type,
    required this.calcMode,
    required this.principalAmount,
    required this.interestRate,
    required this.termMonths,
    this.overdueInterestRate = 0,
    required this.startDate,
    this.dueDate,
    this.payments = const [],
    this.isPaid = false,
    this.notes,
    required this.expectedTotalAmount,
    this.principalToWallet = true,
  });

  DebtEntity copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    String? counterparty,
    DebtType? type,
    DebtCalcMode? calcMode,
    double? principalAmount,
    double? interestRate,
    int? termMonths,
    double? overdueInterestRate,
    DateTime? startDate,
    DateTime? dueDate,
    List<Payment>? payments,
    bool? isPaid,
    String? notes,
    double? expectedTotalAmount,
    bool? principalToWallet,
  }) {
    return DebtEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      counterparty: counterparty ?? this.counterparty,
      type: type ?? this.type,
      calcMode: calcMode ?? this.calcMode,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate: interestRate ?? this.interestRate,
      termMonths: termMonths ?? this.termMonths,
      overdueInterestRate: overdueInterestRate ?? this.overdueInterestRate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      payments: payments ?? this.payments,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
      expectedTotalAmount: expectedTotalAmount ?? this.expectedTotalAmount,
      principalToWallet: principalToWallet ?? this.principalToWallet,
    );
  }

  // --- Hesaplama Metodları ---

  /// Cüzdandan çıkan toplam nakit (gecikme faizi dahil; kuruşa yuvarlı).
  /// "Ne kadar ödedim" sorusunun yanıtı — borcun ne kadarının kapandığı
  /// değil (onun için [principalPaidAmount]).
  double get totalPaidAmount =>
      roundToCents(payments.fold(0, (sum, p) => sum + p.amount));

  /// Ödemelerin **borcu azaltan** kısmı: toplam nakit eksi gecikme faizi payı.
  /// Kalan borç, taksit planı ve "ödendi" kararı bunu kullanır.
  ///
  /// Yuvarlama TOPLAMDA yapılır, ödeme başına değil: kayıt başına yuvarlayıp
  /// toplamak, kuruş-temiz olmayan eski ödemelerde ([Payment.principalPart]
  /// tek kaydı yuvarlar) toplamı [totalPaidAmount]'tan kuruşlarca ayırıp
  /// kapanmış bir borcu açık gösteriyordu.
  double get principalPaidAmount => roundToCents(
      payments.fold(0, (sum, p) => sum + p.amount - p.overdueInterestPart));

  /// Ödemelerin gecikme faizine sayılmış toplam kısmı.
  double get settledOverdueInterest =>
      roundToCents(payments.fold(0, (sum, p) => sum + p.overdueInterestPart));

  /// Toplam Borç Tutarı (kuruşa yuvarlı; faiz formülü çok basamak üretebilir)
  double get totalDebtAmount => roundToCents(expectedTotalAmount);

  /// Kalan Borç (kuruşa yuvarlı; "Tümü" prefill'i bu değerle birebir eşleşir)
  double get remainingAmount =>
      roundToCents(totalDebtAmount - principalPaidAmount);

  /// Ödeme İlerlemesi (0.0 - 1.0 arası)
  double get progress =>
      totalDebtAmount == 0 ? 0 : principalPaidAmount / totalDebtAmount;

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        title,
        counterparty,
        type,
        calcMode,
        principalAmount,
        interestRate,
        termMonths,
        overdueInterestRate,
        startDate,
        dueDate,
        payments,
        isPaid,
        notes,
        expectedTotalAmount,
        principalToWallet,
      ];
}
