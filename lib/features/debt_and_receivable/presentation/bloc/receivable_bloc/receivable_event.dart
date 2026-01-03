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
  const UpdateReceivableEvent(this.receivable);

  @override
  List<Object?> get props => [receivable];
}

class DeleteReceivableEvent extends ReceivableEvent {
  final String id;
  final String walletId;
  const DeleteReceivableEvent({required this.id, required this.walletId});

  @override
  List<Object?> get props => [id, walletId];
}
