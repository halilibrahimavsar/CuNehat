import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
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
  AddReceivableUseCase(this.repository);

  Future<Either<Failure, void>> call(ReceivableEntity receivable) async {
    if (receivable.id == null || receivable.id!.isEmpty) {
      receivable = receivable.copyWith(id: UidGenerator.generateV7());
    }
    return await repository.addReceivable(receivable);
  }
}

@injectable
class UpdateReceivableUseCase {
  final ReceivableRepository repository;
  UpdateReceivableUseCase(this.repository);

  Future<Either<Failure, void>> call(ReceivableEntity receivable) {
    if (receivable.id == null || receivable.id!.isEmpty) {
      return Future.value(Left(ValidationFailure(
          'Receivable ID cannot be null for update operation')));
    }
    return repository.updateReceivable(receivable);
  }
}

@injectable
class DeleteReceivableUseCase {
  final ReceivableRepository repository;
  DeleteReceivableUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.deleteReceivable(id);
}
