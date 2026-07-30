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

  /// Yalnız silmede dolu: UI bunu "Geri al" eylemine bağlar.
  final DeletionUndo? undo;

  const ReceivableOperationSuccess(this.message, {this.undo});

  @override
  List<Object?> get props => [message, undo];
}

class ReceivableError extends ReceivableState {
  final String message;
  const ReceivableError(this.message);

  @override
  List<Object?> get props => [message];
}
