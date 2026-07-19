// lib/features/recurring_transactions/domain/usecases/delete_recurring_transaction_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import '../repositories/recurring_transaction_repository.dart';

import 'package:cunehat/core/notifications/notification_service.dart';

@injectable
class DeleteRecurringTransactionUsecase {
  final RecurringTransactionRepository repository;
  final NotificationService notificationService;

  DeleteRecurringTransactionUsecase(this.repository, this.notificationService);

  Future<Either<Failure, void>> call(String id) async {
    final result = await repository.deleteTemplate(id);
    result.fold(
      (failure) => null,
      (_) => notificationService.cancelNotification('recurring_$id'.hashCode),
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
  final NotificationService notificationService;

  DeleteRecurringTemplatesForWalletUsecase(
      this.repository, this.notificationService);

  Future<Either<Failure, void>> call(String walletId) async {
    final res = await repository.getAllTemplates();
    return res.fold(
      (failure) => Left(failure),
      (templates) async {
        for (final t in templates.where((t) => t.walletId == walletId)) {
          final del = await repository.deleteTemplate(t.id);
          del.fold(
            (_) => null,
            (_) => notificationService
                .cancelNotification('recurring_${t.id}'.hashCode),
          );
        }
        return const Right(null);
      },
    );
  }
}
