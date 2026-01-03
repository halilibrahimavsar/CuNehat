part of 'receivable_bloc.dart';

abstract class ReceivableState extends Equatable {
  const ReceivableState();

  @override
  List<Object?> get props => [];
}

class ReceivableInitial extends ReceivableState {}

class ReceivableLoading extends ReceivableState {}

class ReceivableLoaded extends ReceivableState {
  final List<ReceivableEntity> receivables;

  const ReceivableLoaded(this.receivables);

  @override
  List<Object?> get props => [receivables];
}

/// İşlem başarılı olduğunda (Ekleme/Silme/Güncelleme)
class ReceivableOperationSuccess extends ReceivableState {
  final String message;
  const ReceivableOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ReceivableError extends ReceivableState {
  final String message;
  const ReceivableError(this.message);

  @override
  List<Object?> get props => [message];
}
