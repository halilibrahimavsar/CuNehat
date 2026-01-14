import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction_entity.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  /// Helper to access transactions from any state
  List<TransactionEntity> get currentTransactions => [];

  @override
  List<Object?> get props => [];
}

class TransactionLoading extends TransactionState {
  final List<TransactionEntity> previousTransactions;

  const TransactionLoading({this.previousTransactions = const []});

  @override
  List<TransactionEntity> get currentTransactions => previousTransactions;

  @override
  List<Object> get props => [previousTransactions];
}

class TransactionLoaded extends TransactionState {
  final Map<DateTime, List<TransactionEntity>> groupedTransactions;
  final List<TransactionEntity> allTransactions;

  const TransactionLoaded({
    required this.groupedTransactions,
    required this.allTransactions,
  });

  @override
  List<TransactionEntity> get currentTransactions => allTransactions;

  @override
  List<Object> get props => [groupedTransactions, allTransactions];
}

class TransactionError extends TransactionState {
  final String message;
  final List<TransactionEntity> transactions;

  const TransactionError(this.message, {this.transactions = const []});

  @override
  List<TransactionEntity> get currentTransactions => transactions;

  @override
  List<Object> get props => [message, transactions];
}

class TransactionActionSuccess extends TransactionState {
  final String message;
  final List<TransactionEntity> transactions;

  const TransactionActionSuccess(this.message, {this.transactions = const []});

  @override
  List<TransactionEntity> get currentTransactions => transactions;

  @override
  List<Object> get props => [message, transactions];
}
