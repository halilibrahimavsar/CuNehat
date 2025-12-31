import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/repository/investment_datasource_repository.dart';
import 'package:hive/hive.dart';

class InvestmentLocalDatasource implements InvestmentDatasourceRepository {
  static const String _boxName = 'investments_box';

  Future<Box<InvestmentModel>> get _box async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<InvestmentModel>(_boxName);
    }
    return await Hive.openBox<InvestmentModel>(_boxName);
  }

  @override
  Future<void> addInvestment(InvestmentModel investment) async {
    final box = await _box;
    await box.put(investment.id, investment);
  }

  @override
  Future<void> deleteInvestment({required String id}) async {
    final box = await _box;
    await box.delete(id);
  }

  @override
  Future<List<InvestmentModel>> getInvestments() async {
    final box = await _box;
    return box.values.toList();
  }

  @override
  Future<void> updateInvestment(InvestmentModel investment) async {
    final box = await _box;
    await box.put(investment.id, investment);
  }
}
