// lib/features/finance_transactions/domain/entities/transaction_entity.dart
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:equatable/equatable.dart';

/// ✅ FIXED: ID is optional in constructor (will be set by repository)
class TransactionEntity extends Equatable {
  final String? id;
  final String userId;
  final String walletId;
  final String title;
  final String tag;
  final double amount;
  final DateTime date;
  final String time;
  final TransactionTypeModel type;

  const TransactionEntity({
    this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.time,
    required this.type,
  });

  factory TransactionEntity.create({
    required String userId,
    required String walletId,
    required String title,
    required String tag,
    required double amount,
    required DateTime date,
    required String time,
    required TransactionTypeModel type,
  }) {
    return TransactionEntity(
      id: UidGenerator.generateWithUserId(),
      userId: userId,
      walletId: walletId,
      title: title,
      tag: tag,
      amount: amount,
      date: date,
      time: time,
      type: type,
    );
  }

  TransactionEntity copyWith({
    String? title,
    String? tag,
    double? amount,
    DateTime? date,
    String? time,
    TransactionTypeModel? type,
  }) {
    return TransactionEntity(
      id: id, // preserve id
      userId: userId, // preserve id
      walletId: walletId, // preserve id
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
    );
  }

  bool get isIncome => type == TransactionTypeModel.income;
  bool get isExpense => type == TransactionTypeModel.expense;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'tag': tag,
      'amount': amount,
      'date': date.toIso8601String(),
      'time': time,
      'type': type.name,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        title,
        tag,
        amount,
        date,
        time,
        type,
      ];
}
