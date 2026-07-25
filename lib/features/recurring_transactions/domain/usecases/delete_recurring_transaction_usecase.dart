// lib/features/recurring_transactions/domain/usecases/delete_recurring_transaction_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import '../repositories/recurring_transaction_repository.dart';

@injectable
class DeleteRecurringTransactionUsecase {
  final RecurringTransactionRepository repository;
  final ReminderSyncService reminderSync;

  DeleteRecurringTransactionUsecase(this.repository, this.reminderSync);

  Future<Either<Failure, void>> call(String id) async {
    final result = await repository.deleteTemplate(id);
    await result.fold(
      (_) async {},
      (_) => reminderSync.cancelRecurringReminder(id),
    );
    return result;
  }
}

/// Cüzdan silinirken cüzdana ait tüm düzenli işlem şablonlarını temizler
/// (yetim şablon önlemi; şablonlar cüzdan bazlıdır ve bekleyen onay diyaloğu
/// tüm cüzdanları kapsadığından yetimler sonsuza dek vadesi gelmiş görünür).
@injectable
class DeleteRecurringTemplatesForWalletUsecase {
  final RecurringTransactionRepository repository;
  final ReminderSyncService reminderSync;

  DeleteRecurringTemplatesForWalletUsecase(this.repository, this.reminderSync);

  Future<Either<Failure, void>> call(String walletId) async {
    final res = await repository.getAllTemplates();
    return res.fold(
      (failure) => Left(failure),
      (templates) async {
        for (final t in templates.where((t) => t.walletId == walletId)) {
          final del = await repository.deleteTemplate(t.id);
          await del.fold(
            (_) async {},
            (_) => reminderSync.cancelRecurringReminder(t.id),
          );
        }
        return const Right(null);
      },
    );
  }
}
