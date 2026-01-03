import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/repository/receivable_datasource_repository.dart';
import 'package:hive/hive.dart';

class ReceivableLocalDatasource implements ReceivableDatasourceRepository {
  final String _boxName = 'receivables';

  Future<Box<ReceivableModel>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<ReceivableModel>(_boxName);
    }
    return await Hive.openBox<ReceivableModel>(_boxName);
  }

  @override
  Future<void> addReceivable(ReceivableModel receivable) async {
    final box = await _getBox();
    await box.put(receivable.id, receivable);
  }

  @override
  Future<void> deleteReceivable(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  Future<List<ReceivableModel>> getReceivablesByWalletId(
      String walletId) async {
    final box = await _getBox();
    return box.values
        .where((receivable) => receivable.walletId == walletId)
        .toList();
  }

  @override
  Future<void> updateReceivable(ReceivableModel receivable) async {
    final box = await _getBox();
    await box.put(receivable.id, receivable);
  }
}
