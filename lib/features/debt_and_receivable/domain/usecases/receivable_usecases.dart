import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/plans_changed_notifier.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/receivable_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetReceivablesUseCase {
  final ReceivableRepository repository;
  GetReceivablesUseCase(this.repository);

  Future<Either<Failure, List<ReceivableEntity>>> call(String walletId) =>
      repository.getReceivablesByWalletId(walletId);
}

@injectable
class AddReceivableUseCase {
  final ReceivableRepository repository;

  /// Plan değişti: tahmin yüzeyleri tazelensin (bkz. [PlansChangedNotifier]).
  final PlansChangedNotifier? plans;
  AddReceivableUseCase(this.repository, [this.plans]);

  Future<Either<Failure, void>> call(ReceivableEntity receivable) async {
    if (receivable.id == null || receivable.id!.isEmpty) {
      receivable = receivable.copyWith(id: UidGenerator.generateV7());
    }
    final result = await repository.addReceivable(receivable);
    if (result.isRight()) plans?.notify();
    return result;
  }
}

@injectable
class UpdateReceivableUseCase {
  final ReceivableRepository repository;

  /// Plan değişti: tahmin yüzeyleri tazelensin (bkz. [PlansChangedNotifier]).
  final PlansChangedNotifier? plans;
  UpdateReceivableUseCase(this.repository, [this.plans]);

  Future<Either<Failure, void>> call(ReceivableEntity receivable) async {
    if (receivable.id == null || receivable.id!.isEmpty) {
      return Left(ValidationFailure(
          'Receivable ID cannot be null for update operation'));
    }
    final result = await repository.updateReceivable(receivable);
    if (result.isRight()) plans?.notify();
    return result;
  }
}

@injectable
class DeleteReceivableUseCase {
  final ReceivableRepository repository;

  /// Plan değişti: tahmin yüzeyleri tazelensin (bkz. [PlansChangedNotifier]).
  final PlansChangedNotifier? plans;
  DeleteReceivableUseCase(this.repository, [this.plans]);

  Future<Either<Failure, void>> call(String id) async {
    final result = await repository.deleteReceivable(id);
    if (result.isRight()) plans?.notify();
    return result;
  }
}
