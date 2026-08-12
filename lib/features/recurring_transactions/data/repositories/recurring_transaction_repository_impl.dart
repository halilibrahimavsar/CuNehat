// lib/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/repositories/recurring_transaction_repository.dart';
import '../datasources/recurring_transaction_local_datasource.dart';
import '../models/recurring_transaction_model.dart';

@LazySingleton(as: RecurringTransactionRepository)
class RecurringTransactionRepositoryImpl
    implements RecurringTransactionRepository {
  final RecurringTransactionLocalDataSource localDataSource;

  RecurringTransactionRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, void>> saveTemplate(
      RecurringTransactionEntity template) async {
    try {
      final model = RecurringTransactionModel.fromEntity(template);
      await localDataSource.saveTemplate(model);
      return const Right(null);
    } catch (e, st) {
      debugPrint('Save recurring template error: $e\n$st');
      return const Left(CacheFailure('Düzenli işlem şablonu kaydedilemedi.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTemplate(String id) async {
    try {
      await localDataSource.deleteTemplate(id);
      return const Right(null);
    } catch (e, st) {
      debugPrint('Delete recurring template error: $e\n$st');
      return const Left(CacheFailure('Düzenli işlem şablonu silinemedi.'));
    }
  }

  @override
  Future<Either<Failure, List<RecurringTransactionEntity>>>
      getAllTemplates() async {
    try {
      final models = await localDataSource.getAllTemplates();
      final entities = models.map((e) => e.toEntity()).toList();
      return Right(entities);
    } catch (e, st) {
      debugPrint('Get all recurring templates error: $e\n$st');
      return const Left(CacheFailure('Düzenli işlem şablonları getirilemedi.'));
    }
  }

  @override
  Future<Either<Failure, int>> retagTemplates(
      Set<String> from, String to) async {
    try {
      return Right(await localDataSource.retagTemplates(from, to));
    } catch (e, st) {
      debugPrint('Retag recurring templates error: $e\n$st');
      return const Left(CacheFailure('Düzenli işlem şablonları taşınamadı.'));
    }
  }

  @override
  Future<Either<Failure, List<RecurringTransactionEntity>>>
      getPendingTransactions() async {
    try {
      final models = await localDataSource.getPendingTransactions();
      final entities = models.map((e) => e.toEntity()).toList();
      return Right(entities);
    } catch (e, st) {
      debugPrint('Get pending recurring transactions error: $e\n$st');
      return const Left(
          CacheFailure('Bekleyen düzenli işlemler getirilemedi.'));
    }
  }
}
