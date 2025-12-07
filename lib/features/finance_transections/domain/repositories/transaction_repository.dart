// ==========================================
// lib/features/transaction/domain/repositories/transaction_repository.dart
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:dartz/dartz.dart';

import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
  });

  Future<Either<Failure, TransactionEntity>> getTransactionById(String id);

  Future<Either<Failure, String>> addTransaction(TransactionEntity transaction);

  Future<Either<Failure, void>> updateTransaction(
      TransactionEntity transaction);

  Future<Either<Failure, void>> deleteTransaction(String id);

  Future<Either<Failure, Map<DateTime, List<TransactionEntity>>>>
      getTransactionsGroupedByDate({
    required String userId,
    required String walletId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  });
}
