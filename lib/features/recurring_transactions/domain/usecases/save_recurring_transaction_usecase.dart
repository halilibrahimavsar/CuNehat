// lib/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import '../entities/recurring_transaction_entity.dart';
import '../repositories/recurring_transaction_repository.dart';

@injectable
class SaveRecurringTransactionUsecase {
  final RecurringTransactionRepository repository;

  SaveRecurringTransactionUsecase(this.repository);

  Future<Either<Failure, void>> call(
      RecurringTransactionEntity template) async {
    return await repository.saveTemplate(template);
  }
}
