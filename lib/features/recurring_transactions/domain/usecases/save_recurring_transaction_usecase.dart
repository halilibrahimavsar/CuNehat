// lib/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/error/failure.dart';
import '../entities/recurring_transaction_entity.dart';
import '../repositories/recurring_transaction_repository.dart';

import 'package:cunehat/core/notifications/notification_service.dart';

@injectable
class SaveRecurringTransactionUsecase {
  final RecurringTransactionRepository repository;
  final NotificationService notificationService;

  SaveRecurringTransactionUsecase(this.repository, this.notificationService);

  Future<Either<Failure, void>> call(
      RecurringTransactionEntity template) async {
    final result = await repository.saveTemplate(template);

    result.fold(
      (failure) => null,
      (_) {
        final id = template.id.hashCode;
        notificationService.cancelNotification(id);

        notificationService.scheduleNotification(
          id: id,
          title: 'Düzenli İşlem Yaklaşıyor',
          body: '${template.title} başlıklı işleminizin zamanı yaklaştı.',
          scheduledDate:
              template.nextExecutionDate.subtract(const Duration(days: 1)),
        );
      },
    );

    return result;
  }
}
