// lib/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

abstract class PendingRecurringEvent extends Equatable {
  const PendingRecurringEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingTransactionsEvent extends PendingRecurringEvent {
  /// Kullanıcı doğrudan bildirime dokunarak geldiğinde `true`.
  ///
  /// Diyalog normalde aynı bekleyen küme için ikinci kez açılmaz (kullanıcı
  /// bir kez "Kapat" dediyse her uygulamaya dönüşte yeniden çıkmamalı);
  /// bildirime dokunmak bu susturmayı bilinçli olarak geçersiz kılar.
  final bool forceShow;

  const LoadPendingTransactionsEvent({this.forceShow = false});

  @override
  List<Object?> get props => [forceShow];
}

class ApproveTransactionEvent extends PendingRecurringEvent {
  final RecurringTransactionEntity template;

  /// Yalnızca bu vadenin işlemi için geçerli tutar; şablon tutarı değişmez.
  final double? overrideAmount;

  const ApproveTransactionEvent(this.template, {this.overrideAmount});

  @override
  List<Object?> get props => [template, overrideAmount];
}

/// Şablonun birikmiş TÜM vadelerini sırayla deftere işler.
class ApproveAllOccurrencesEvent extends PendingRecurringEvent {
  final RecurringTransactionEntity template;

  const ApproveAllOccurrencesEvent(this.template);

  @override
  List<Object?> get props => [template];
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
