// lib/features/recurring_transactions/domain/usecases/skip_recurring_transaction_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import '../entities/recurring_transaction_entity.dart';
import 'approve_recurring_transaction_usecase.dart';
import 'save_recurring_transaction_usecase.dart';

/// Bu vadeyi işlem yaratmadan atlar: yalnızca şablonun bir sonraki vade
/// tarihini ilerletir (örn. "bu ay abonelik donduruldu").
@injectable
class SkipRecurringTransactionUsecase {
  final SaveRecurringTransactionUsecase saveTemplate;

  SkipRecurringTransactionUsecase(this.saveTemplate);

  Future<Either<Failure, void>> call(RecurringTransactionEntity template) {
    final nextDate = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
      template.nextExecutionDate,
      template.frequency,
    );
    // Kaydetme usecase'i üzerinden: yeni vadenin hatırlatması da kurulsun.
    return saveTemplate(template.copyWith(nextExecutionDate: nextDate));
  }
}
