// lib/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

abstract class PendingRecurringEvent extends Equatable {
  const PendingRecurringEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingTransactionsEvent extends PendingRecurringEvent {}

class ApproveTransactionEvent extends PendingRecurringEvent {
  final RecurringTransactionEntity template;

  const ApproveTransactionEvent(this.template);

  @override
  List<Object?> get props => [template];
}

class SkipTransactionEvent extends PendingRecurringEvent {
  final RecurringTransactionEntity template;

  const SkipTransactionEvent(this.template);

  @override
  List<Object?> get props => [template];
}
