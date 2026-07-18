import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteBudgetUsecase {
  final BudgetRepository repository;

  DeleteBudgetUsecase(this.repository);

  Future<Either<Failure, void>> call(String walletId, String categoryId) {
    return repository.deleteBudget(walletId, categoryId);
  }
}

/// Kategori silinirken kategorinin tüm cüzdanlardaki bütçelerini temizler
/// (hayalet bütçe önlemi; bütçeler cüzdan bazlı olduğundan tek cüzdan yetmez).
@injectable
class DeleteBudgetsForCategoryUsecase {
  final BudgetRepository repository;

  DeleteBudgetsForCategoryUsecase(this.repository);

  Future<Either<Failure, void>> call(String categoryId) {
    return repository.deleteBudgetsForCategory(categoryId);
  }
}

/// Cüzdan silinirken cüzdana ait tüm bütçeleri temizler (yetim bütçe önlemi).
@injectable
class DeleteBudgetsForWalletUsecase {
  final BudgetRepository repository;

  DeleteBudgetsForWalletUsecase(this.repository);

  Future<Either<Failure, void>> call(String walletId) {
    return repository.deleteBudgetsForWallet(walletId);
  }
}
