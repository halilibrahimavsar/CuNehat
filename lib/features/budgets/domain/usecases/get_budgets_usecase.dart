import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetBudgetsUsecase {
  final BudgetRepository repository;

  GetBudgetsUsecase(this.repository);

  Future<Either<Failure, List<BudgetEntity>>> call() {
    return repository.getBudgets();
  }
}
