// lib/features/transaction/presentation/bloc/transaction_event.dart
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class GetTransactionsEvent extends TransactionEvent {
  final String userId;
  final String walletId;
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionTypeModel? type;

  const GetTransactionsEvent({
    required this.userId,
    required this.walletId,
    this.startDate,
    this.endDate,
    this.type,
  });

  @override
  List<Object?> get props => [userId, walletId, startDate, endDate, type];
}

class AddTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;

  const AddTransactionEvent(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class UpdateTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;

  const UpdateTransactionEvent(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String transactionId;

  const DeleteTransactionEvent(this.transactionId);

  @override
  List<Object> get props => [transactionId];
}
