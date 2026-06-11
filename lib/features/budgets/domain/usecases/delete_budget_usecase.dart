import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteBudgetUsecase {
  final BudgetRepository repository;

  DeleteBudgetUsecase(this.repository);

  Future<Either<Failure, void>> call(String categoryId) {
    return repository.deleteBudget(categoryId);
  }
}
