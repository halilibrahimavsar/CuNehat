import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TransactionsRepository)
class TransactionRepositoryImpl implements TransactionsRepository {
  final TransactionHiveDataSource localDatasource;

  TransactionRepositoryImpl({required this.localDatasource});

  @override
  Future<Either<Failure, String>> addTransaction(
      TransactionEntity transaction) async {
    try {
      final id = await localDatasource
          .addTransaction(TransactionModel.fromEntity(transaction));
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('İşlem eklenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(
      TransactionEntity transaction) async {
    try {
      await localDatasource
          .updateTransaction(TransactionModel.fromEntity(transaction));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('İşlem güncellenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await localDatasource.deleteTransaction(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('İşlem silinemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionById(
      String id) async {
    try {
      final model = await localDatasource.getTransactionById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('İşlem getirilemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
  }) async {
    try {
      final models = await localDatasource.getTransactions(
        userId: userId,
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('İşlemler getirilemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, List<TransactionEntity>>>>
      getTransactionsGroupedByDate({
    required String userId,
    required String walletId,
    TransactionTypeModel? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final modelsMap = await localDatasource.getTransactionsGroupedByDate(
        userId: userId,
        walletId: walletId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      final Map<DateTime, List<TransactionEntity>> entitiesMap = {};
      modelsMap.forEach((date, models) {
        entitiesMap[date] = models.map((m) => m.toEntity()).toList();
      });

      return Right(entitiesMap);
    } catch (e) {
      return Left(
          CacheFailure('Gruplanmış işlemler getirilemedi: ${e.toString()}'));
    }
  }
}
