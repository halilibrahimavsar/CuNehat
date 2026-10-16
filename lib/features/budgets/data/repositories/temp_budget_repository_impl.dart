import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_strings.dart';
import 'package:cunehat/features/budgets/data/datasources/local/temp_budget_local_datasource.dart';
import 'package:cunehat/features/budgets/data/models/temp_budget_model.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/temp_budget_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TempBudgetRepository)
class TempBudgetRepositoryImpl implements TempBudgetRepository {
  final TempBudgetLocalDataSource _local;

  TempBudgetRepositoryImpl(this._local);

  @override
  Future<Either<Failure, List<TempBudgetEntity>>> getTempBudgets(
      String walletId) async {
    try {
      final models = await _local.getForWallet(walletId);
      return Right([for (final m in models) m.toEntity()]);
    } catch (e, st) {
      debugPrint('Temp budget get error: $e\n$st');
      return Left(CacheFailure(appStrings.failBudgetLoad));
    }
  }

  @override
  Future<Either<Failure, TempBudgetEntity?>> getTempBudget(String id) async {
    try {
      return Right((await _local.getById(id))?.toEntity());
    } catch (e, st) {
      debugPrint('Temp budget get-by-id error: $e\n$st');
      return Left(CacheFailure(appStrings.failBudgetLoad));
    }
  }

  @override
  Future<Either<Failure, void>> saveTempBudget(TempBudgetEntity budget) async {
    try {
      await _local.put(TempBudgetModel.fromEntity(budget));
      return const Right(null);
    } catch (e, st) {
      debugPrint('Temp budget save error: $e\n$st');
      return Left(CacheFailure(appStrings.failBudgetSave));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTempBudget(String id) async {
    try {
      await _local.delete(id);
      return const Right(null);
    } catch (e, st) {
      debugPrint('Temp budget delete error: $e\n$st');
      return Left(CacheFailure(appStrings.failBudgetDelete));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTempBudgetsForWallet(
      String walletId) async {
    try {
      await _local.deleteForWallet(walletId);
      return const Right(null);
    } catch (e, st) {
      debugPrint('Temp budget delete-for-wallet error: $e\n$st');
      return Left(CacheFailure(appStrings.failBudgetDelete));
    }
  }

  @override
  Future<Either<Failure, void>> removeCategoryFromTempBudgets(
      String categoryId) async {
    try {
      await _local.removeCategory(categoryId);
      return const Right(null);
    } catch (e, st) {
      debugPrint('Temp budget remove-category error: $e\n$st');
      return Left(CacheFailure(appStrings.failBudgetDelete));
    }
  }
}
