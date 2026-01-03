import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/receivable_repository.dart';

class GetReceivablesUseCase {
  final ReceivableRepository repository;
  GetReceivablesUseCase(this.repository);

  Future<List<ReceivableEntity>> call(String walletId) =>
      repository.getReceivablesByWalletId(walletId);
}

class AddReceivableUseCase {
  final ReceivableRepository repository;
  AddReceivableUseCase(this.repository);

  Future<void> call(ReceivableEntity receivable) =>
      repository.addReceivable(receivable);
}

class UpdateReceivableUseCase {
  final ReceivableRepository repository;
  UpdateReceivableUseCase(this.repository);

  Future<void> call(ReceivableEntity receivable) =>
      repository.updateReceivable(receivable);
}

class DeleteReceivableUseCase {
  final ReceivableRepository repository;
  DeleteReceivableUseCase(this.repository);

  Future<void> call(String id) => repository.deleteReceivable(id);
}
