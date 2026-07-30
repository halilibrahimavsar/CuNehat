part of 'debt_bloc.dart';

abstract class DebtState extends Equatable {
  const DebtState();

  @override
  List<Object?> get props => [];
}

class DebtInitial extends DebtState {}

class DebtLoading extends DebtState {}

class DebtLoaded extends DebtState {
  final List<DebtEntity> debts;

  const DebtLoaded(this.debts);

  @override
  List<Object?> get props => [debts];
}

/// Ekleme, Silme veya Güncelleme işlemi başarılı olduğunda tetiklenir.
/// UI tarafında SnackBar göstermek için kullanılabilir.
class DebtOperationSuccess extends DebtState {
  final String message;

  /// Yalnız silmede dolu: UI bunu "Geri al" eylemine bağlar. `null` →
  /// geri alınabilir bir şey yok (ekleme/güncelleme) ya da geri alma için
  /// gereken bilgi toplanamadı.
  final DeletionUndo? undo;

  const DebtOperationSuccess(this.message, {this.undo});

  @override
  List<Object?> get props => [message, undo];
}

class DebtError extends DebtState {
  final String message;
  const DebtError(this.message);

  @override
  List<Object?> get props => [message];
}
