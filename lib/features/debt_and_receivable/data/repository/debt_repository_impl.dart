import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/repository/debt_datasource_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/debt_repository.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtDatasourceRepository debtDatasourceRepository;

  DebtRepositoryImpl({required this.debtDatasourceRepository});

  @override
  Future<void> addDebt(DebtEntity debt) async {
    final model = DebtModel.fromEntity(debt);
    return await debtDatasourceRepository.addDebt(model);
  }

  @override
  Future<void> updateDebt(DebtEntity debt) async {
    await debtDatasourceRepository.updateDebt(DebtModel.fromEntity(debt));
  }

  @override
  Future<void> deleteDebt(String id) async {
    return await debtDatasourceRepository.deleteDebt(id);
  }

  @override
  Future<List<DebtEntity>> getDebtsByWalletId(String walletId) async {
    return await debtDatasourceRepository
        .getDebtsByWalletId(walletId)
        .then((models) => models.map((e) => e.toEntity()).toList());
  }
}
