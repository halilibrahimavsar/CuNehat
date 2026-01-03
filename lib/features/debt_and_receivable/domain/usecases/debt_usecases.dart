import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/debt_repository.dart';

class GetDebtsUseCase {
  final DebtRepository repository;
  GetDebtsUseCase(this.repository);

  Future<List<DebtEntity>> call(String walletId) =>
      repository.getDebtsByWalletId(walletId);
}

class AddDebtUseCase {
  final DebtRepository repository;
  AddDebtUseCase(this.repository);

  Future<void> call(DebtEntity debt) => repository.addDebt(debt);
}

class UpdateDebtUseCase {
  final DebtRepository repository;
  UpdateDebtUseCase(this.repository);

  Future<void> call(DebtEntity debt) => repository.updateDebt(debt);
}

class DeleteDebtUseCase {
  final DebtRepository repository;
  DeleteDebtUseCase(this.repository);

  Future<void> call(String id) => repository.deleteDebt(id);
}
