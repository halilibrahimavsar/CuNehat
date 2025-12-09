// lib/features/finance_transections/data/models/transaction_model.dart
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/transaction_entity.dart';

part 'transaction_model.g.dart';

/// ⚠️ CRITICAL FIX: Remove field overrides
/// The model extends entity, so it inherits all fields
/// We only need to add @HiveField annotations
@HiveType(typeId: 1)
class TransactionModel extends TransactionEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String userId;

  @HiveField(2)
  @override
  final String walletId;

  @HiveField(3)
  @override
  final String title;

  @HiveField(4)
  @override
  final String tag;

  @HiveField(5)
  @override
  final double amount;

  @HiveField(6)
  @override
  final DateTime date;

  @HiveField(7)
  @override
  final String time;

  @HiveField(8)
  @override
  final TransactionTypeModel type;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.time,
    required this.type,
  }) : super(
          id: id,
          userId: userId,
          walletId: walletId,
          title: title,
          tag: tag,
          amount: amount,
          date: date,
          time: time,
          type: type,
        );

  factory TransactionModel.fromJson(String id, Map<String, dynamic> json) {
    return TransactionModel(
      id: id,
      userId: json['userId'] as String,
      walletId: json['walletId'] as String,
      title: json['title'] as String,
      tag: json['tag'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      type: _parseTransactionType(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'tag': tag,
      'amount': amount,
      'date': date.toIso8601String(),
      'time': time,
      'type': type == TransactionTypeModel.income ? 'income' : 'expense',
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      walletId: entity.walletId,
      title: entity.title,
      tag: entity.tag,
      amount: entity.amount,
      date: entity.date,
      time: entity.time,
      type: entity.type,
    );
  }

  static TransactionTypeModel _parseTransactionType(String type) {
    return type == 'income'
        ? TransactionTypeModel.income
        : TransactionTypeModel.expense;
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    String? tag,
    double? amount,
    DateTime? date,
    String? time,
    TransactionTypeModel? type,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
    );
  }
}
