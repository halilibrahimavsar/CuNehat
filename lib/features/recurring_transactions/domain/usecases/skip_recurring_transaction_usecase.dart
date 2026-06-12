// lib/features/recurring_transactions/domain/usecases/skip_recurring_transaction_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import '../entities/recurring_transaction_entity.dart';
import '../repositories/recurring_transaction_repository.dart';
import 'approve_recurring_transaction_usecase.dart';

/// Bu vadeyi işlem yaratmadan atlar: yalnızca şablonun bir sonraki vade
/// tarihini ilerletir (örn. "bu ay abonelik donduruldu").
@injectable
class SkipRecurringTransactionUsecase {
  final RecurringTransactionRepository recurringRepository;

  SkipRecurringTransactionUsecase(this.recurringRepository);

  Future<Either<Failure, void>> call(
      RecurringTransactionEntity template) async {
    final nextDate = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
      template.nextExecutionDate,
      template.frequency,
    );
    return recurringRepository
        .saveTemplate(template.copyWith(nextExecutionDate: nextDate));
  }
}
