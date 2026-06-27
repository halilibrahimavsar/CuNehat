import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/notifications/notification_service.dart';

@injectable
class GetDebtsUseCase {
  final DebtRepository repository;
  GetDebtsUseCase(this.repository);

  Future<Either<Failure, List<DebtEntity>>> call(String walletId) =>
      repository.getDebtsByWalletId(walletId);
}

@injectable
class AddDebtUseCase {
  final DebtRepository repository;
  final NotificationService notificationService;

  AddDebtUseCase(this.repository, this.notificationService);

  Future<Either<Failure, void>> call(DebtEntity debt) async {
    if (debt.id == null || debt.id!.isEmpty) {
      debt = debt.copyWith(id: UidGenerator.generateV7());
    }

    final result = await repository.addDebt(debt);

    result.fold(
      (failure) => null,
      (_) {
        if (debt.dueDate != null && !debt.isPaid) {
          final id = debt.id.hashCode;
          notificationService.scheduleNotification(
            id: id,
            title: 'Borç Hatırlatması',
            body:
                '${debt.title} başlıklı borcunuzun son ödeme tarihi yaklaştı.',
            scheduledDate: debt.dueDate!.subtract(const Duration(days: 1)),
          );

          notificationService.scheduleNotification(
            id: id + 1, // Farklı bir ID ile tam gününde
            title: 'Borç Son Ödeme Tarihi!',
            body: '${debt.title} başlıklı borcunuzun son ödeme tarihi bugün.',
            scheduledDate: debt.dueDate!,
          );
        }
      },
    );

    return result;
  }
}

@injectable
class UpdateDebtUseCase {
  final DebtRepository repository;
  final NotificationService notificationService;

  UpdateDebtUseCase(this.repository, this.notificationService);

  Future<Either<Failure, void>> call(DebtEntity debt) async {
    if (debt.id == null || debt.id!.isEmpty) {
      return Left(
          ValidationFailure('Debt ID cannot be null for update operation'));
    }
    final result = await repository.updateDebt(debt);

    result.fold(
      (failure) => null,
      (_) {
        final id = debt.id.hashCode;
        // Önce eskileri iptal et
        notificationService.cancelNotification(id);
        notificationService.cancelNotification(id + 1);

        // Eğer ödenmediyse ve tarihi varsa tekrar kur
        if (debt.dueDate != null && !debt.isPaid) {
          notificationService.scheduleNotification(
            id: id,
            title: 'Borç Hatırlatması',
            body:
                '${debt.title} başlıklı borcunuzun son ödeme tarihi yaklaştı.',
            scheduledDate: debt.dueDate!.subtract(const Duration(days: 1)),
          );

          notificationService.scheduleNotification(
            id: id + 1,
            title: 'Borç Son Ödeme Tarihi!',
            body: '${debt.title} başlıklı borcunuzun son ödeme tarihi bugün.',
            scheduledDate: debt.dueDate!,
          );
        }
      },
    );
    return result;
  }
}

@injectable
class DeleteDebtUseCase {
  final DebtRepository repository;
  final NotificationService notificationService;

  DeleteDebtUseCase(this.repository, this.notificationService);

  Future<Either<Failure, void>> call(String id) async {
    final result = await repository.deleteDebt(id);
    result.fold(
      (failure) => null,
      (_) {
        final notifId = id.hashCode;
        notificationService.cancelNotification(notifId);
        notificationService.cancelNotification(notifId + 1);
      },
    );
    return result;
  }
}
