import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/data/datasources/local/budget_local_datasource.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

@LazySingleton(as: BudgetRepository)
class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource localDataSource;

  BudgetRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<BudgetEntity>>> getBudgets(
      String walletId) async {
    try {
      final models = await localDataSource.getBudgets(walletId);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e, st) {
      debugPrint('Budget get error: $e\n$st');
      return const Left(CacheFailure('Bütçeler yüklenemedi.'));
    }
  }

  @override
  Future<Either<Failure, void>> saveBudget(BudgetEntity budget) async {
    try {
      final model = BudgetModel.fromEntity(budget);
      await localDataSource.saveBudget(model);
      return const Right(null);
    } catch (e, st) {
      debugPrint('Budget save error: $e\n$st');
      return const Left(CacheFailure('Bütçe kaydedilemedi.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBudget(
      String walletId, String categoryId) async {
    try {
      await localDataSource.deleteBudget(walletId, categoryId);
      return const Right(null);
    } catch (e, st) {
      debugPrint('Budget delete error: $e\n$st');
      return const Left(CacheFailure('Bütçe silinemedi.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBudgetsForCategory(
      String categoryId) async {
    try {
      await localDataSource.deleteBudgetsForCategory(categoryId);
      return const Right(null);
    } catch (e, st) {
      debugPrint('Budget delete-for-category error: $e\n$st');
      return const Left(CacheFailure('Bütçe silinemedi.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBudgetsForWallet(String walletId) async {
    try {
      await localDataSource.deleteBudgetsForWallet(walletId);
      return const Right(null);
    } catch (e, st) {
      debugPrint('Budget delete-for-wallet error: $e\n$st');
      return const Left(CacheFailure('Bütçe silinemedi.'));
    }
  }
}
