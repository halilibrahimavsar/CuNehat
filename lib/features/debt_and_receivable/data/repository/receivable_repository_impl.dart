import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/repository/receivable_datasource_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/receivable_repository.dart';

class ReceivableRepositoryImpl implements ReceivableRepository {
  final ReceivableDatasourceRepository receivableDatasourceRepository;

  ReceivableRepositoryImpl({required this.receivableDatasourceRepository});

  @override
  Future<void> addReceivable(ReceivableEntity receivable) async {
    final model = ReceivableModel.fromEntity(receivable);
    return await receivableDatasourceRepository.addReceivable(model);
  }

  @override
  Future<void> deleteReceivable(String id) async {
    return await receivableDatasourceRepository.deleteReceivable(id);
  }

  @override
  Future<List<ReceivableEntity>> getReceivablesByWalletId(
      String walletId) async {
    return await receivableDatasourceRepository
        .getReceivablesByWalletId(walletId)
        .then((models) => models.map((e) => e.toEntity()).toList());
  }

  @override
  Future<void> updateReceivable(ReceivableEntity receivable) async {
    await receivableDatasourceRepository
        .updateReceivable(ReceivableModel.fromEntity(receivable));
  }
}
