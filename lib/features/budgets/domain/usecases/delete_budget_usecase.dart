import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/budgets/domain/repositories/temp_budget_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteBudgetUsecase {
  final BudgetRepository repository;
  final BudgetsChangedNotifier budgetsChangedNotifier;

  DeleteBudgetUsecase(this.repository, this.budgetsChangedNotifier);

  Future<Either<Failure, void>> call(String walletId, String categoryId) async {
    final result = await repository.deleteBudget(walletId, categoryId);
    result.fold((_) {}, (_) => budgetsChangedNotifier.notify());
    return result;
  }
}

/// Kategori silinirken kategorinin tüm cüzdanlardaki bütçelerini temizler
/// (hayalet bütçe önlemi; bütçeler cüzdan bazlı olduğundan tek cüzdan yetmez).
///
/// Tek seferlik bütçelerde kategori yalnız LİSTEDEN düşer; listesi boşalan
/// bütçe silinir (bkz. `TempBudgetLocalDataSource.removeCategory`).
@injectable
class DeleteBudgetsForCategoryUsecase {
  final BudgetRepository repository;
  final TempBudgetRepository tempRepository;
  final BudgetsChangedNotifier budgetsChangedNotifier;

  DeleteBudgetsForCategoryUsecase(
      this.repository, this.tempRepository, this.budgetsChangedNotifier);

  Future<Either<Failure, void>> call(String categoryId) async {
    final result = await repository.deleteBudgetsForCategory(categoryId);
    final temp = await tempRepository.removeCategoryFromTempBudgets(categoryId);
    budgetsChangedNotifier.notify();
    return result.isLeft() ? result : temp;
  }
}

/// Cüzdan silinirken cüzdana ait tüm bütçeleri — aylık ve tek seferlik —
/// temizler (yetim bütçe önlemi).
@injectable
class DeleteBudgetsForWalletUsecase {
  final BudgetRepository repository;
  final TempBudgetRepository tempRepository;
  final BudgetsChangedNotifier budgetsChangedNotifier;

  DeleteBudgetsForWalletUsecase(
      this.repository, this.tempRepository, this.budgetsChangedNotifier);

  Future<Either<Failure, void>> call(String walletId) async {
    final result = await repository.deleteBudgetsForWallet(walletId);
    final temp = await tempRepository.deleteTempBudgetsForWallet(walletId);
    budgetsChangedNotifier.notify();
    return result.isLeft() ? result : temp;
  }
}
