import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';

/// Bütçe verileri için depo arayüzü.
abstract class BudgetRepository {
  /// Tüm bütçeleri getirir.
  Future<Either<Failure, List<BudgetEntity>>> getBudgets();

  /// Yeni bir bütçe kaydeder veya olanı günceller.
  Future<Either<Failure, void>> saveBudget(BudgetEntity budget);

  /// Verilen kategori ID'sine sahip bütçeyi siler.
  Future<Either<Failure, void>> deleteBudget(String categoryId);
}
