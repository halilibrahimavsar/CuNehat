import 'dart:math' as math;
import 'package:cunehat/core/utils/money_math.dart';
import 'package:equatable/equatable.dart';

enum DebtType { bankLoan, installmentDebt, personalDebt, otherDebt }

class Payment extends Equatable {
  final DateTime date;
  final double amount;
  final String? notes;

  const Payment({required this.date, required this.amount, this.notes});

  Payment copyWith({
    DateTime? date,
    double? amount,
    String? notes,
  }) {
    return Payment(
      date: date ?? this.date,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [date, amount, notes];
}

class DebtEntity extends Equatable {
  final String? id;
  final String userId;
  final String walletId;
  final String title;
  final String counterparty; // Banka adı veya Kişi adı (UI'daki Subtitle)
  final DebtType type;
  final double principalAmount;
  final double interestRate;
  final int termMonths;
  final double overdueInterestRate; // Gecikme Faizi (%)
  final DateTime startDate;
  final DateTime? dueDate;
  final List<Payment> payments;
  final bool isPaid;
  final String? notes;
  final double? expectedTotalAmount;

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
    required this.principalAmount,
    required this.interestRate,
    required this.termMonths,
    this.overdueInterestRate = 0,
    required this.startDate,
    this.dueDate,
    this.payments = const [],
    this.isPaid = false,
    this.notes,
    this.expectedTotalAmount,
    this.principalToWallet = true,
  });

  DebtEntity copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    String? counterparty,
    DebtType? type,
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

  /// Toplam Ödenen Tutar (kuruşa yuvarlı; FP birikimi kullanıcıya sızmaz)
  double get totalPaidAmount =>
      roundToCents(payments.fold(0, (sum, p) => sum + p.amount));

  /// Basit faiz formülü
  static double calculateTotalDebt({
    required double principal,
    required double interestRate,
    required int termMonths,
  }) =>
      principal + (principal * interestRate * termMonths / 1200);

  /// Eşit Taksitli Kredi (Amortisman) Formülü - Aylık Faiz üzerinden
  static double calculateAmortizedTotal({
    required double principal,
    required double monthlyInterestRate,
    required int termMonths,
    bool includeTaxes = false,
  }) {
    if (principal <= 0 || termMonths <= 0) return principal;
    if (monthlyInterestRate <= 0) return principal;

    // Banka tüketici kredilerinde faiz üzerinden %15 KKDF ve %15 BSMV alınır (Toplam %30).
    double effectiveRate = monthlyInterestRate;
    if (includeTaxes) {
      effectiveRate = monthlyInterestRate * 1.30;
    }

    final r = effectiveRate / 100;
    final denominator = math.pow(1 + r, termMonths) - 1;
    if (denominator == 0) return principal;

    final monthlyPayment =
        principal * (r * math.pow(1 + r, termMonths)) / denominator;
    return monthlyPayment * termMonths;
  }

  /// Toplam Borç Tutarı (kuruşa yuvarlı; faiz formülü çok basamak üretebilir)
  double get totalDebtAmount => roundToCents(
        expectedTotalAmount ??
            calculateTotalDebt(
              principal: principalAmount,
              interestRate: interestRate,
              termMonths: termMonths,
            ),
      );

  /// Kalan Borç (kuruşa yuvarlı; "Tümü" prefill'i bu değerle birebir eşleşir)
  double get remainingAmount => roundToCents(totalDebtAmount - totalPaidAmount);

  /// Ödeme İlerlemesi (0.0 - 1.0 arası)
  double get progress =>
      totalDebtAmount == 0 ? 0 : totalPaidAmount / totalDebtAmount;

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        title,
        counterparty,
        type,
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
