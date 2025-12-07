// ==========================================
// UPDATED REPOSITORY IMPLEMENTATION
// ==========================================

// lib/features/transaction/data/repositories/transaction_repository_impl.dart
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/finance_transections/data/datasources/transection_data_source.dart';
import 'package:dartz/dartz.dart';
import 'package:cunehat/core/utils/error_handler.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDataSource dataSource;

  TransactionRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
  }) async {
    try {
      final transactions = await dataSource.getTransactions(
        userId: userId,
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
      return Right(transactions);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionById(
      String id) async {
    try {
      final transaction = await dataSource.getTransactionById(id);
      return Right(transaction);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> addTransaction(
      TransactionEntity transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      final id = await dataSource.addTransaction(model);
      return Right(id);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(
      TransactionEntity transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      await dataSource.updateTransaction(model);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await dataSource.deleteTransaction(id);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, List<TransactionEntity>>>>
      getTransactionsGroupedByDate({
    required String userId,
    required String walletId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await dataSource.getTransactions(
        userId: userId,
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
        type: type,
      );

      // Group by date
      final Map<DateTime, List<TransactionEntity>> grouped = {};
      for (var transaction in transactions) {
        final dateKey = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );

        if (grouped.containsKey(dateKey)) {
          grouped[dateKey]!.add(transaction);
        } else {
          grouped[dateKey] = [transaction];
        }
      }

      return Right(grouped);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }
}
