// ==========================================
// lib/features/transaction/presentation/bloc/transaction_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final Map<DateTime, List<TransactionEntity>> groupedTransactions;
  final List<TransactionEntity> allTransactions;

  const TransactionLoaded({
    required this.groupedTransactions,
    required this.allTransactions,
  });

  @override
  List<Object> get props => [groupedTransactions, allTransactions];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object> get props => [message];
}

class TransactionActionSuccess extends TransactionState {
  final String message;

  const TransactionActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}
