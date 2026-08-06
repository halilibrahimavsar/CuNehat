import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:hive/hive.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 6)
class DebtModel extends DebtEntity {
  @override
  @HiveField(0)
  String? get id;

  @override
  @HiveField(1)
  String get userId;

  @override
  @HiveField(2)
  String get walletId;

  @override
  @HiveField(3)
  String get title;

  @override
  @HiveField(17) // Yeni alanlar için yeni index
  String get counterparty;

  @override
  @HiveField(4)
  DebtType get type;

  @override
  @HiveField(5)
  double get principalAmount;

  @override
  @HiveField(6)
  double get interestRate;

  @override
  @HiveField(7)
  int get termMonths;

  @override
  @HiveField(8)
  DateTime get startDate;

  @override
  @HiveField(9)
  DateTime? get dueDate;

  @override
  @HiveField(13)
  double get overdueInterestRate;

  @override
  @HiveField(14)
  List<Payment> get payments;

  @override
  @HiveField(15)
  bool get isPaid;

  @override
  @HiveField(16)
  String? get notes;

  @override
  @HiveField(18) // Yeni alan
  double get expectedTotalAmount;

  @override
  @HiveField(19)
  bool get principalToWallet;

  @override
  @HiveField(20)
  DebtCalcMode get calcMode;

  const DebtModel({
    required super.id,
    required super.userId,
    required super.walletId,
    required super.title,
    required super.counterparty,
    required super.type,
    required super.calcMode,
    required super.principalAmount,
    required super.interestRate,
    required super.termMonths,
    super.overdueInterestRate,
    required super.startDate,
    super.dueDate,
    super.payments = const [],
    super.isPaid = false,
    super.notes,
    required super.expectedTotalAmount,
    super.principalToWallet = true,
  });

  factory DebtModel.fromEntity(DebtEntity entity) {
    return DebtModel(
      id: entity.id,
      userId: entity.userId,
      walletId: entity.walletId,
      title: entity.title,
      counterparty: entity.counterparty,
      type: entity.type,
      calcMode: entity.calcMode,
      principalAmount: entity.principalAmount,
      interestRate: entity.interestRate,
      termMonths: entity.termMonths,
      overdueInterestRate: entity.overdueInterestRate,
      startDate: entity.startDate,
      dueDate: entity.dueDate,
      payments: entity.payments.map((e) => PaymentModel.fromEntity(e)).toList(),
      isPaid: entity.isPaid,
      notes: entity.notes,
      expectedTotalAmount: entity.expectedTotalAmount,
      principalToWallet: entity.principalToWallet,
    );
  }

  DebtEntity toEntity() {
    return DebtEntity(
      id: id,
      userId: userId,
      walletId: walletId,
      title: title,
      counterparty: counterparty,
      type: type,
      calcMode: calcMode,
      principalAmount: principalAmount,
      interestRate: interestRate,
      termMonths: termMonths,
      overdueInterestRate: overdueInterestRate,
      startDate: startDate,
      dueDate: dueDate,
      payments: payments
          .map((e) => e is PaymentModel
              ? e.toEntity()
              : Payment(
                  id: e.id,
                  date: e.date,
                  amount: e.amount,
                  overdueInterestPart: e.overdueInterestPart,
                  notes: e.notes,
                ))
          .toList(),
      isPaid: isPaid,
      notes: notes,
      expectedTotalAmount: expectedTotalAmount,
      principalToWallet: principalToWallet,
    );
  }

  @override
  DebtModel copyWith({
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
    return DebtModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'counterparty': counterparty,
      'type': type.name,
      'calcMode': calcMode.name,
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'termMonths': termMonths,
      'overdueInterestRate': overdueInterestRate,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'payments':
          payments.map((e) => PaymentModel.fromEntity(e).toJson()).toList(),
      'isPaid': isPaid,
      'notes': notes,
      'expectedTotalAmount': expectedTotalAmount,
      'principalToWallet': principalToWallet,
    };
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      walletId: json['walletId'] as String,
      title: json['title'] as String,
      counterparty: json['counterparty'] as String,
      type: DebtType.values.byName(json['type'] as String),
      calcMode: DebtCalcMode.values.byName(json['calcMode'] as String),
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      termMonths: json['termMonths'] as int,
      overdueInterestRate: (json['overdueInterestRate'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      payments: (json['payments'] as List<dynamic>)
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPaid: json['isPaid'] as bool,
      notes: json['notes'] as String?,
      expectedTotalAmount: (json['expectedTotalAmount'] as num).toDouble(),
      principalToWallet: json['principalToWallet'] as bool,
    );
  }
}

// Payment sınıfı Entity dosyasında tanımlı (Clean Architecture gereği orada
// Hive anotasyonu olamaz); Hive'ın ihtiyaç duyduğu alan haritası burada,
// PaymentModel üzerinden verilir.

@HiveType(typeId: 9)
class PaymentModel extends Payment {
  @override
  @HiveField(0)
  DateTime get date => super.date;

  @override
  @HiveField(1)
  double get amount => super.amount;

  @override
  @HiveField(2)
  String? get notes => super.notes;

  @override
  @HiveField(3)
  String get id => super.id;

  @override
  @HiveField(4)
  double get overdueInterestPart => super.overdueInterestPart;

  const PaymentModel({
    required super.id,
    required super.date,
    required super.amount,
    super.overdueInterestPart,
    super.notes,
  });

  // Entity'den Model'e çevirici
  factory PaymentModel.fromEntity(Payment payment) {
    return PaymentModel(
      id: payment.id,
      date: payment.date,
      amount: payment.amount,
      overdueInterestPart: payment.overdueInterestPart,
      notes: payment.notes,
    );
  }

  Payment toEntity() {
    return Payment(
      id: id,
      date: date,
      amount: amount,
      overdueInterestPart: overdueInterestPart,
      notes: notes,
    );
  }

  @override
  PaymentModel copyWith({
    String? id,
    DateTime? date,
    double? amount,
    double? overdueInterestPart,
    String? notes,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      overdueInterestPart: overdueInterestPart ?? this.overdueInterestPart,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'overdueInterestPart': overdueInterestPart,
      'notes': notes,
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      overdueInterestPart: (json['overdueInterestPart'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}
