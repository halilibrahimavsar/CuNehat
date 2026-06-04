import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/debt_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetDebtsUseCase {
  final DebtRepository repository;
  GetDebtsUseCase(this.repository);

  Future<Either<Failure, List<DebtEntity>>> call(String walletId) =>
      repository.getDebtsByWalletId(walletId);
}

@injectable
class AddDebtUseCase {
  final DebtRepository repository;
  AddDebtUseCase(this.repository);

  Future<Either<Failure, void>> call(DebtEntity debt) async {
    if (debt.id == null || debt.id!.isEmpty) {
      debt = debt.copyWith(id: UidGenerator.generateV7());
    }
    return await repository.addDebt(debt);
  }
}

@injectable
class UpdateDebtUseCase {
  final DebtRepository repository;
  UpdateDebtUseCase(this.repository);

  Future<Either<Failure, void>> call(DebtEntity debt) {
    if (debt.id == null || debt.id!.isEmpty) {
      return Future.value(Left(
          ValidationFailure('Debt ID cannot be null for update operation')));
    }
    return repository.updateDebt(debt);
  }
}

@injectable
class DeleteDebtUseCase {
  final DebtRepository repository;
  DeleteDebtUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.deleteDebt(id);
}
