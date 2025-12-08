// lib/features/finance_transections/domain/entities/transaction_entity.dart
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String userId;
  final String walletId;
  final String title;
  final String tag;
  final double amount;
  final DateTime date;
  final String time;
  final TransactionTypeModel type;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.time,
    required this.type,
  });

  bool get isIncome => type == TransactionTypeModel.income;
  bool get isExpense => type == TransactionTypeModel.expense;

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
