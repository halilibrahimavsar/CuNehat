// lib/features/finance_transections/domain/entities/transaction_entity.dart
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'transaction_entity.g.dart';

@HiveType(typeId: 5) // ⚠️ NEW typeId (5 was taken)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

/// ⚠️ CRITICAL FIX: Entity should NOT have @HiveField annotations
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
