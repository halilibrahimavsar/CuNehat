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

  /// İşlemi süren şablon kimlikleri; ilgili satırın butonları kilitlenir.
  final Set<String> busyTemplateIds;

  /// Bu yükleme bildirime dokunularak tetiklendi; diyalog susturulmuş olsa
  /// bile açılmalı.
  final bool forceShow;

  const PendingRecurringLoaded(
    this.pendingTransactions, {
    this.busyTemplateIds = const {},
    this.forceShow = false,
  });

  PendingRecurringLoaded copyWith({
    List<RecurringTransactionEntity>? pendingTransactions,
    Set<String>? busyTemplateIds,
    bool? forceShow,
  }) {
    return PendingRecurringLoaded(
      pendingTransactions ?? this.pendingTransactions,
      busyTemplateIds: busyTemplateIds ?? this.busyTemplateIds,
      forceShow: forceShow ?? this.forceShow,
    );
  }

  @override
  List<Object?> get props => [pendingTransactions, busyTemplateIds, forceShow];
}

class PendingRecurringFailure extends PendingRecurringState {
  final Failure failure;

  const PendingRecurringFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
