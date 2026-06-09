import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:dartz/dartz.dart';

/// Base interface for transaction data sources
abstract class TransactionsRepository {
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
  });

  Future<Either<Failure, Map<DateTime, List<TransactionEntity>>>>
      getTransactionsGroupedByDate({
    required String userId,
    required String walletId,
    TransactionTypeModel? type,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, TransactionEntity>> getTransactionById(String id);
  Future<Either<Failure, String>> addTransaction(TransactionEntity transaction);
  Future<Either<Failure, void>> updateTransaction(
      TransactionEntity transaction);
  Future<Either<Failure, void>> deleteTransaction(String id);
}
