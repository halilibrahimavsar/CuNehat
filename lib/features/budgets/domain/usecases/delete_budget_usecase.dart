import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteBudgetUsecase {
  final BudgetRepository repository;
  final BudgetsChangedNotifier budgetsChangedNotifier;

  DeleteBudgetUsecase(this.repository, this.budgetsChangedNotifier);

  Future<Either<Failure, void>> call(
      String walletId, String categoryId) async {
    final result = await repository.deleteBudget(walletId, categoryId);
    result.fold((_) {}, (_) => budgetsChangedNotifier.notify());
    return result;
  }
}

/// Kategori silinirken kategorinin tüm cüzdanlardaki bütçelerini temizler
/// (hayalet bütçe önlemi; bütçeler cüzdan bazlı olduğundan tek cüzdan yetmez).
@injectable
class DeleteBudgetsForCategoryUsecase {
  final BudgetRepository repository;
  final BudgetsChangedNotifier budgetsChangedNotifier;

  DeleteBudgetsForCategoryUsecase(this.repository, this.budgetsChangedNotifier);

  Future<Either<Failure, void>> call(String categoryId) async {
    final result = await repository.deleteBudgetsForCategory(categoryId);
    result.fold((_) {}, (_) => budgetsChangedNotifier.notify());
    return result;
  }
}

/// Cüzdan silinirken cüzdana ait tüm bütçeleri temizler (yetim bütçe önlemi).
@injectable
class DeleteBudgetsForWalletUsecase {
  final BudgetRepository repository;
  final BudgetsChangedNotifier budgetsChangedNotifier;

  DeleteBudgetsForWalletUsecase(this.repository, this.budgetsChangedNotifier);

  Future<Either<Failure, void>> call(String walletId) async {
    final result = await repository.deleteBudgetsForWallet(walletId);
    result.fold((_) {}, (_) => budgetsChangedNotifier.notify());
    return result;
  }
}
