import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class SaveBudgetUsecase {
  final BudgetRepository repository;

  SaveBudgetUsecase(this.repository);

  Future<Either<Failure, void>> call(BudgetEntity budget) {
    return repository.saveBudget(budget);
  }
}
