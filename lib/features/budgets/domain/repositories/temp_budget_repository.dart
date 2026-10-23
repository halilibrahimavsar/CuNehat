import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:dartz/dartz.dart';

/// Tek seferlik bütçelerin deposu. Yalnız kaydı döner; harcama
/// `GetTempBudgetsUsecase`'te hesaplanır.
abstract class TempBudgetRepository {
  Future<Either<Failure, List<TempBudgetEntity>>> getTempBudgets(
      String walletId);

  Future<Either<Failure, TempBudgetEntity?>> getTempBudget(String id);

  /// Ekler ya da günceller (anahtar `id`; `walletId` dolu olmalı).
  Future<Either<Failure, void>> saveTempBudget(TempBudgetEntity budget);

  Future<Either<Failure, void>> deleteTempBudget(String id);

  /// Cüzdan silinirken (yetim bütçe önlemi).
  Future<Either<Failure, void>> deleteTempBudgetsForWallet(String walletId);

  /// Kategori silinirken: kategori listelerden düşer, boşalan bütçe silinir.
  /// [replacementId] verilirse (işlemler oraya taşındı) yerini o alır.
  Future<Either<Failure, void>> removeCategoryFromTempBudgets(String categoryId,
      {String? replacementId});
}
