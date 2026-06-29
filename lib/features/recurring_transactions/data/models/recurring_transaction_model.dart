// lib/features/recurring_transactions/data/models/recurring_transaction_model.dart

import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/entities/recurring_frequency_enum.dart';

part 'recurring_transaction_model.g.dart';

@HiveType(typeId: 11)
class RecurringTransactionModel extends RecurringTransactionEntity {
  const RecurringTransactionModel({
    required super.id,
    required super.userId,
    required super.walletId,
    required super.title,
    required super.tag,
    required super.amount,
    required super.type,
    required super.frequency,
    required super.nextExecutionDate,
    super.isActive = true,
  });

  factory RecurringTransactionModel.fromEntity(
      RecurringTransactionEntity entity) {
    return RecurringTransactionModel(
      id: entity.id,
      userId: entity.userId,
      walletId: entity.walletId,
      title: entity.title,
      tag: entity.tag,
      amount: entity.amount,
      type: entity.type,
      frequency: entity.frequency,
      nextExecutionDate: entity.nextExecutionDate,
      isActive: entity.isActive,
    );
  }

  RecurringTransactionEntity toEntity() {
    return RecurringTransactionEntity(
      id: id,
      userId: userId,
      walletId: walletId,
      title: title,
      tag: tag,
      amount: amount,
      type: type,
      frequency: frequency,
      nextExecutionDate: nextExecutionDate,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'tag': tag,
      'amount': amount,
      'type': type.name,
      'frequency': frequency.name,
      'nextExecutionDate': nextExecutionDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? 'local_user',
      walletId: json['walletId'] as String,
      title: json['title'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      type: TransactionTypeModel.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => TransactionTypeModel.expense,
      ),
      frequency: RecurringFrequency.values.firstWhere(
        (frequency) => frequency.name == json['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      nextExecutionDate: DateTime.parse(json['nextExecutionDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  @HiveField(0)
  String get id => super.id;

  @override
  @HiveField(1)
  String get userId => super.userId;

  @override
  @HiveField(2)
  String get walletId => super.walletId;

  @override
  @HiveField(3)
  String get title => super.title;

  @override
  @HiveField(4)
  String get tag => super.tag;

  @override
  @HiveField(5)
  double get amount => super.amount;

  @override
  @HiveField(6)
  TransactionTypeModel get type => super.type;

  @override
  @HiveField(7)
  RecurringFrequency get frequency => super.frequency;

  @override
  @HiveField(8)
  DateTime get nextExecutionDate => super.nextExecutionDate;

  @override
  @HiveField(9)
  bool get isActive => super.isActive;
}
