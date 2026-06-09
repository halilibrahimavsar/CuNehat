enum DebtType { bankLoan, installmentDebt, personalDebt, otherDebt }

class Payment {
  final DateTime date;
  final double amount;
  final String? notes;

  Payment({required this.date, required this.amount, this.notes});

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
}

class DebtEntity {
  String? id;
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

  DebtEntity({
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
    );
  }

  // --- Hesaplama Metodları ---

  /// Toplam Ödenen Tutar
  double get totalPaidAmount => payments.fold(0, (sum, p) => sum + p.amount);

  /// Basit faiz formülü — kaydedilmiş borç (totalDebtAmount) ve form
  /// önizlemesi AYNI hesabı kullansın diye tek yerde.
  static double calculateTotalDebt({
    required double principal,
    required double interestRate,
    required int termMonths,
  }) =>
      principal + (principal * interestRate * termMonths / 1200);

  /// Toplam Borç Tutarı (Basit Faiz Hesabı: Ana Para + (Ana Para * Yıllık Faiz * Ay / 1200))
  double get totalDebtAmount => calculateTotalDebt(
        principal: principalAmount,
        interestRate: interestRate,
        termMonths: termMonths,
      );

  /// Kalan Borç
  double get remainingAmount => totalDebtAmount - totalPaidAmount;

  /// Ödeme İlerlemesi (0.0 - 1.0 arası)
  double get progress =>
      totalDebtAmount == 0 ? 0 : totalPaidAmount / totalDebtAmount;
}
