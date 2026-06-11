// lib/features/recurring_transactions/presentation/bloc/pending_recurring_state.dart

import 'package:equatable/equatable.dart';
import 'package:cunehat/core/error/failure.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

abstract class PendingRecurringState extends Equatable {
  const PendingRecurringState();

  @override
  List<Object?> get props => [];
}

class PendingRecurringInitial extends PendingRecurringState {}

class PendingRecurringLoading extends PendingRecurringState {}

class PendingRecurringLoaded extends PendingRecurringState {
  final List<RecurringTransactionEntity> pendingTransactions;

  const PendingRecurringLoaded(this.pendingTransactions);

  @override
  List<Object?> get props => [pendingTransactions];
}

class PendingRecurringFailure extends PendingRecurringState {
  final Failure failure;

  const PendingRecurringFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
