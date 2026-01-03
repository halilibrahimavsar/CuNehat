part of 'debt_bloc.dart';

abstract class DebtEvent extends Equatable {
  const DebtEvent();

  @override
  List<Object?> get props => [];
}

class GetDebtsEvent extends DebtEvent {
  final String walletId;
  const GetDebtsEvent(this.walletId);

  @override
  List<Object?> get props => [walletId];
}

class AddDebtEvent extends DebtEvent {
  final DebtEntity debt;
  const AddDebtEvent(this.debt);

  @override
  List<Object?> get props => [debt];
}

class UpdateDebtEvent extends DebtEvent {
  final DebtEntity debt;
  const UpdateDebtEvent(this.debt);

  @override
  List<Object?> get props => [debt];
}

class DeleteDebtEvent extends DebtEvent {
  final String id;
  final String userId;
  final String
      walletId; // Silme işleminden sonra listeyi yenilemek için gerekli
  final double amount;
  const DeleteDebtEvent(this.userId, this.amount,
      {required this.id, required this.walletId});

  @override
  List<Object?> get props => [id, walletId];
}
