import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/receivable_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetReceivablesUseCase {
  final ReceivableRepository repository;
  GetReceivablesUseCase(this.repository);

  Future<List<ReceivableEntity>> call(String walletId) =>
      repository.getReceivablesByWalletId(walletId);
}

@injectable
class AddReceivableUseCase {
  final ReceivableRepository repository;
  AddReceivableUseCase(this.repository);

  Future<void> call(ReceivableEntity receivable) async {
    if (receivable.id == null) {
      receivable = receivable.copyWith(id: UidGenerator.generateV7());
    }
    await repository.addReceivable(receivable);
  }
}

@injectable
class UpdateReceivableUseCase {
  final ReceivableRepository repository;
  UpdateReceivableUseCase(this.repository);

  Future<void> call(ReceivableEntity receivable) =>
      repository.updateReceivable(receivable);
}

@injectable
class DeleteReceivableUseCase {
  final ReceivableRepository repository;
  DeleteReceivableUseCase(this.repository);

  Future<void> call(String id) => repository.deleteReceivable(id);
}
