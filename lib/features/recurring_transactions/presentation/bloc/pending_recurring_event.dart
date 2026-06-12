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

  /// Yalnızca bu vadenin işlemi için geçerli tutar; şablon tutarı değişmez.
  final double? overrideAmount;

  const ApproveTransactionEvent(this.template, {this.overrideAmount});

  @override
  List<Object?> get props => [template, overrideAmount];
}

class SkipTransactionEvent extends PendingRecurringEvent {
  final RecurringTransactionEntity template;

  const SkipTransactionEvent(this.template);

  @override
  List<Object?> get props => [template];
}

class DeleteTransactionEvent extends PendingRecurringEvent {
  final String id;

  const DeleteTransactionEvent(this.id);

  @override
  List<Object?> get props => [id];
}
