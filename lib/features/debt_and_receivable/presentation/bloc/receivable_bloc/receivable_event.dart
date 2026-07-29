// lib/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_event.dart

part of 'receivable_bloc.dart';

abstract class ReceivableEvent extends Equatable {
  const ReceivableEvent();

  @override
  List<Object?> get props => [];
}

class GetReceivablesEvent extends ReceivableEvent {
  final String walletId;
  const GetReceivablesEvent(this.walletId);

  @override
  List<Object?> get props => [walletId];
}

class AddReceivableEvent extends ReceivableEvent {
  final ReceivableEntity receivable;
  const AddReceivableEvent(this.receivable);

  @override
  List<Object?> get props => [receivable];
}

class UpdateReceivableEvent extends ReceivableEvent {
  final ReceivableEntity receivable;
  final double prevAmount; // Wallet senkronizasyonu için eski tutar

  const UpdateReceivableEvent({
    required this.receivable,
    required this.prevAmount,
  });

  @override
  List<Object?> get props => [receivable, prevAmount];
}

class DeleteReceivableEvent extends ReceivableEvent {
  final String id;
  final String userId;
  final String walletId;
  final double amount; // Wallet senkronizasyonu için
  final bool isPaid; // Mutabakat: tahsil edilmemişse silmede para geri döner

  /// Alacağın deftere yazıldığı tarih; ters kayıt buraya yazılır ki para
  /// verilen ay kendi içinde sıfırlansın.
  final DateTime createdAt;

  const DeleteReceivableEvent({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.amount,
    required this.isPaid,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, walletId, amount, isPaid];
}

/// Alacağı "ödendi" olarak işaretle
class MarkReceivableAsPaidEvent extends ReceivableEvent {
  final ReceivableEntity receivable;

  const MarkReceivableAsPaidEvent(this.receivable);

  @override
  List<Object?> get props => [receivable];
}
