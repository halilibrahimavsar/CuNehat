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
  double? get expectedTotalAmount;

  DebtModel({
    required super.id,
    required super.userId,
    required super.walletId,
    required super.title,
    required super.counterparty,
    required super.type,
    required super.principalAmount,
    required super.interestRate,
    required super.termMonths,
    super.overdueInterestRate,
    required super.startDate,
    super.dueDate,
    super.payments = const [],
    super.isPaid = false,
    super.notes,
    super.expectedTotalAmount,
  });

  factory DebtModel.fromEntity(DebtEntity entity) {
    return DebtModel(
      id: entity.id,
      userId: entity.userId,
      walletId: entity.walletId,
      title: entity.title,
      counterparty: entity.counterparty,
      type: entity.type,
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
      principalAmount: principalAmount,
      interestRate: interestRate,
      termMonths: termMonths,
      overdueInterestRate: overdueInterestRate,
      startDate: startDate,
      dueDate: dueDate,
      payments: payments
          .map((e) => e is PaymentModel
              ? e.toEntity()
              : Payment(date: e.date, amount: e.amount, notes: e.notes))
          .toList(),
      isPaid: isPaid,
      notes: notes,
      expectedTotalAmount: expectedTotalAmount,
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
  }) {
    return DebtModel(
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
    };
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? 'local_user',
      walletId: json['walletId'] as String,
      title: json['title'] as String,
      counterparty: json['counterparty'] as String? ?? '',
      // byName bilinmeyen adda fırlatır ve tek bozuk kayıt tüm restore'u
      // düşürür; bilinmeyen tür otherDebt'e düşsün.
      type: DebtType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DebtType.otherDebt,
      ),
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      termMonths: json['termMonths'] as int,
      overdueInterestRate:
          (json['overdueInterestRate'] as num? ?? 0.0).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPaid: json['isPaid'] as bool? ?? false,
      notes: json['notes'] as String?,
      expectedTotalAmount: (json['expectedTotalAmount'] as num?)?.toDouble(),
    );
  }
}

// Payment sınıfı artık Entity dosyasında tanımlı ama Hive için burada Adapter'a ihtiyacı var.
// Hive Type Adapter'ı generated dosyada (g.dart) oluşturulurken bu sınıfı kullanacak.
// Eğer Payment sınıfını Entity'de tanımladığımız için burada tekrar tanımlamıyoruz,
// ancak Hive anotasyonlarını eklemek için bir "Mixin" veya "Extension" kullanamayız.
// Bu yüzden en temiz yöntem: PaymentModel oluşturup Entity'deki Payment'tan türetmek veya
// Payment sınıfını direkt Entity'de tutup HiveType anotasyonunu orada kullanmaktır.
// Ancak Clean Architecture gereği Entity'de Hive olmamalı.
// Çözüm: PaymentModel oluşturuyoruz.

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

  PaymentModel({required super.date, required super.amount, super.notes});

  // Entity'den Model'e çevirici
  factory PaymentModel.fromEntity(Payment payment) {
    return PaymentModel(
      date: payment.date,
      amount: payment.amount,
      notes: payment.notes,
    );
  }

  Payment toEntity() {
    return Payment(
      date: date,
      amount: amount,
      notes: notes,
    );
  }

  @override
  PaymentModel copyWith({
    DateTime? date,
    double? amount,
    String? notes,
  }) {
    return PaymentModel(
      date: date ?? this.date,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'notes': notes,
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}
