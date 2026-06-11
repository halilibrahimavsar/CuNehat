// lib/features/recurring_transactions/domain/usecases/delete_recurring_transaction_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import '../repositories/recurring_transaction_repository.dart';

@injectable
class DeleteRecurringTransactionUsecase {
  final RecurringTransactionRepository repository;

  DeleteRecurringTransactionUsecase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteTemplate(id);
  }
}
