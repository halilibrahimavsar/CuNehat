// lib/features/recurring_transactions/domain/usecases/get_pending_recurring_transactions_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import '../entities/recurring_transaction_entity.dart';
import '../repositories/recurring_transaction_repository.dart';

@injectable
class GetPendingRecurringTransactionsUsecase {
  final RecurringTransactionRepository repository;

  GetPendingRecurringTransactionsUsecase(this.repository);

  Future<Either<Failure, List<RecurringTransactionEntity>>> call() async {
    return await repository.getPendingTransactions();
  }
}
