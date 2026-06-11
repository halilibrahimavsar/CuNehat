// lib/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart

import 'package:equatable/equatable.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'recurring_frequency_enum.dart';

class RecurringTransactionEntity extends Equatable {
  final String id;
  final String userId;
  final String walletId;
  final String title;
  final String tag;
  final double amount;
  final TransactionTypeModel type;
  final RecurringFrequency frequency;
  final DateTime nextExecutionDate;
  final bool isActive;

  const RecurringTransactionEntity({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.nextExecutionDate,
    this.isActive = true,
  });

  RecurringTransactionEntity copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    String? tag,
    double? amount,
    TransactionTypeModel? type,
    RecurringFrequency? frequency,
    DateTime? nextExecutionDate,
    bool? isActive,
  }) {
    return RecurringTransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        title,
        tag,
        amount,
        type,
        frequency,
        nextExecutionDate,
        isActive,
      ];
}
