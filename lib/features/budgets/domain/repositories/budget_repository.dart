import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';

/// Bütçe verileri için depo arayüzü. Bütçeler cüzdan bazlıdır.
abstract class BudgetRepository {
  /// Verilen cüzdana ait bütçeleri getirir.
  Future<Either<Failure, List<BudgetEntity>>> getBudgets(String walletId);

  /// Yeni bir bütçe kaydeder veya olanı günceller (walletId dolu olmalı).
  Future<Either<Failure, void>> saveBudget(BudgetEntity budget);

  /// Verilen cüzdan+kategori bütçesini siler.
  Future<Either<Failure, void>> deleteBudget(
      String walletId, String categoryId);

  /// Kategori silinirken: kategorinin tüm cüzdanlardaki bütçelerini siler.
  Future<Either<Failure, void>> deleteBudgetsForCategory(String categoryId);

  /// Cüzdan silinirken: cüzdana ait tüm bütçeleri siler (yetim bütçe önlemi).
  Future<Either<Failure, void>> deleteBudgetsForWallet(String walletId);
}
