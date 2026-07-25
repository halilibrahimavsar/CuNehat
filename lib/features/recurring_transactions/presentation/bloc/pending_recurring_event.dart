// lib/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

abstract class PendingRecurringEvent extends Equatable {
  const PendingRecurringEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingTransactionsEvent extends PendingRecurringEvent {
  /// Açılış hatırlatması (nudge) bu yükleme için gösterilmesin.
  ///
  /// Bildirime dokunulduğunda doğrudan Düzenli İşlemler sayfası açılır;
  /// hatırlatma diyaloğu da çıkarsa sayfanın üstünde bir modal olarak
  /// birikirdi.
  final bool suppressNudge;

  const LoadPendingTransactionsEvent({this.suppressNudge = false});

  @override
  List<Object?> get props => [suppressNudge];
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
