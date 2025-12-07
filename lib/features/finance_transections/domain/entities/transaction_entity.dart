// lib/features/finance_transections/domain/entities/transaction_entity.dart
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'transaction_entity.g.dart';

// ⚠️ FIX: Changed typeId from 5 to 6 to avoid conflict

/// ⚠️ Entity should NOT have @HiveField annotations
/// Only the Model (TransactionModel) should have Hive fields
class TransactionEntity extends Equatable {
  final String id;
  final String userId;
  final String walletId;
  final String title;
  final String tag;
  final double amount;
  final DateTime date;
  final String time;
  final TransactionType type;

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

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

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
