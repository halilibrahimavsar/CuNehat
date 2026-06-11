// lib/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart

import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import '../entities/recurring_transaction_entity.dart';

abstract class RecurringTransactionRepository {
  Future<Either<Failure, void>> saveTemplate(
      RecurringTransactionEntity template);
  Future<Either<Failure, void>> deleteTemplate(String id);
  Future<Either<Failure, List<RecurringTransactionEntity>>>
      getPendingTransactions();
  Future<Either<Failure, List<RecurringTransactionEntity>>> getAllTemplates();
}
