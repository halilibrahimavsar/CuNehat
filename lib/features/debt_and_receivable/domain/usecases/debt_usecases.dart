import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

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
  final ReminderSyncService reminderSync;

  AddDebtUseCase(this.repository, this.reminderSync);

  Future<Either<Failure, void>> call(DebtEntity debt) async {
    if (debt.id == null || debt.id!.isEmpty) {
      debt = debt.copyWith(id: UidGenerator.generateV7());
    }

    final result = await repository.addDebt(debt);

    await result.fold(
      (_) async {},
      (_) => reminderSync.syncDebt(debt),
    );

    return result;
  }
}

@injectable
class UpdateDebtUseCase {
  final DebtRepository repository;
  final ReminderSyncService reminderSync;

  UpdateDebtUseCase(this.repository, this.reminderSync);

  Future<Either<Failure, void>> call(DebtEntity debt) async {
    if (debt.id == null || debt.id!.isEmpty) {
      return Left(
          ValidationFailure('Debt ID cannot be null for update operation'));
    }
    final result = await repository.updateDebt(debt);

    // syncDebt önce eskileri iptal eder, sonra borç hâlâ ödenmemiş ve vadeli
    // ise yeniden kurar; ödendi/vade silindi durumunda kurmaz.
    await result.fold(
      (_) async {},
      (_) => reminderSync.syncDebt(debt),
    );

    return result;
  }
}

@injectable
class DeleteDebtUseCase {
  final DebtRepository repository;
  final ReminderSyncService reminderSync;

  DeleteDebtUseCase(this.repository, this.reminderSync);

  Future<Either<Failure, void>> call(String id) async {
    final result = await repository.deleteDebt(id);
    await result.fold(
      (_) async {},
      (_) => reminderSync.cancelDebtReminders(id),
    );
    return result;
  }
}
