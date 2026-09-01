import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class SaveBudgetUsecase {
  final BudgetRepository repository;
  final BudgetsChangedNotifier budgetsChangedNotifier;

  SaveBudgetUsecase(this.repository, this.budgetsChangedNotifier);

  Future<Either<Failure, void>> call(BudgetEntity budget) async {
    final result = await repository.saveBudget(budget);
    // Yalnız BAŞARIDA haber ver: başarısız yazımda açık sayfaları boşuna
    // yeniden okutmanın anlamı yok.
    result.fold((_) {}, (_) => budgetsChangedNotifier.notify());
    return result;
  }
}
