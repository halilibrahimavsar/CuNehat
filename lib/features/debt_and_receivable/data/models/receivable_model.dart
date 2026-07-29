import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:hive/hive.dart';
part 'receivable_model.g.dart';

@HiveType(typeId: 7)
class ReceivableModel extends ReceivableEntity {
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
  String get debtorName;

  @override
  @HiveField(4)
  double get amount;

  @override
  @HiveField(5)
  DateTime get dueDate;

  @override
  @HiveField(6)
  bool get isPaid;

  @override
  @HiveField(7)
  String? get notes;

  @override
  @HiveField(8)
  DateTime get createdAt;

  @override
  @HiveField(9)
  DateTime? get collectedAt;

  const ReceivableModel({
    required super.id,
    required super.userId,
    required super.walletId,
    required super.debtorName,
    required super.amount,
    required super.dueDate,
    required super.createdAt,
    super.collectedAt,
    super.isPaid,
    super.notes,
  });

  factory ReceivableModel.fromEntity(ReceivableEntity entity) {
    return ReceivableModel(
      id: entity.id,
      userId: entity.userId,
      walletId: entity.walletId,
      debtorName: entity.debtorName,
      amount: entity.amount,
      dueDate: entity.dueDate,
      createdAt: entity.createdAt,
      collectedAt: entity.collectedAt,
      isPaid: entity.isPaid,
      notes: entity.notes,
    );
  }

  ReceivableEntity toEntity() {
    return ReceivableEntity(
      id: id,
      userId: userId,
      walletId: walletId,
      debtorName: debtorName,
      amount: amount,
      dueDate: dueDate,
      createdAt: createdAt,
      collectedAt: collectedAt,
      isPaid: isPaid,
      notes: notes,
    );
  }

  @override
  ReceivableModel copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? debtorName,
    double? amount,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? collectedAt,
    bool? isPaid,
    String? notes,
  }) {
    return ReceivableModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      debtorName: debtorName ?? this.debtorName,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      collectedAt: collectedAt ?? this.collectedAt,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'debtorName': debtorName,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'collectedAt': collectedAt?.toIso8601String(),
      'isPaid': isPaid,
      'notes': notes,
    };
  }

  factory ReceivableModel.fromJson(Map<String, dynamic> json) {
    return ReceivableModel(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      walletId: json['walletId'] as String,
      debtorName: json['debtorName'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      // Gerçekten nullable (henüz tahsil edilmemiş), sürüm fallback'i değil.
      collectedAt: json['collectedAt'] == null
          ? null
          : DateTime.parse(json['collectedAt'] as String),
      isPaid: json['isPaid'] as bool,
      notes: json['notes'] as String?,
    );
  }
}
