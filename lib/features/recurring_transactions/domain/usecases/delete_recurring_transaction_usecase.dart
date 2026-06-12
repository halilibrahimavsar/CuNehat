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
      (_) => notificationService.cancelNotification(id.hashCode),
    );
    return result;
  }
}
