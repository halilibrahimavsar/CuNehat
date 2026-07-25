// lib/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import '../entities/recurring_transaction_entity.dart';
import '../repositories/recurring_transaction_repository.dart';

/// Şablonu kaydeder ve hatırlatmasını güncel hale getirir.
///
/// Şablonun `nextExecutionDate` alanını değiştiren HER yol buradan geçmeli
/// (onay ve atlama dahil); doğrudan repository'ye yazmak bir sonraki vadenin
/// bildirimini kurmadan bırakır.
@injectable
class SaveRecurringTransactionUsecase {
  final RecurringTransactionRepository repository;
  final ReminderSyncService reminderSync;

  SaveRecurringTransactionUsecase(this.repository, this.reminderSync);

  Future<Either<Failure, void>> call(
      RecurringTransactionEntity template) async {
    final result = await repository.saveTemplate(template);

    await result.fold(
      (_) async {},
      (_) => reminderSync.syncRecurringTemplate(template),
    );

    return result;
  }
}
