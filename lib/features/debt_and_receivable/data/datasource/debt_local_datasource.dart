import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/repository/debt_datasource_repository.dart';
import 'package:hive/hive.dart';

class DebtLocalDatasource implements DebtDatasourceRepository {
  final String _boxName = 'debts';

  Future<Box<DebtModel>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<DebtModel>(_boxName);
    }
    return await Hive.openBox<DebtModel>(_boxName);
  }

  @override
  Future<void> addDebt(DebtModel debt) async {
    final box = await _getBox();
    await box.put(debt.id, debt);
  }

  @override
  Future<void> deleteDebt(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  Future<List<DebtModel>> getDebtsByWalletId(String walletId) async {
    final box = await _getBox();
    return box.values.where((debt) => debt.walletId == walletId).toList();
  }

  @override
  Future<void> updateDebt(DebtModel debt) async {
    final box = await _getBox();
    await box.put(debt.id, debt);
  }
}
