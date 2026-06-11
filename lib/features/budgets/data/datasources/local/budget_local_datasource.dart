import 'package:hive/hive.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:injectable/injectable.dart';

abstract class BudgetLocalDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<void> saveBudget(BudgetModel budget);
  Future<void> deleteBudget(String categoryId);
}

@LazySingleton(as: BudgetLocalDataSource)
class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  static const String _boxName = 'budgets_box';

  Future<Box<BudgetModel>> get _box async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<BudgetModel>(_boxName);
    }
    return await Hive.openBox<BudgetModel>(_boxName);
  }

  @override
  Future<List<BudgetModel>> getBudgets() async {
    final box = await _box;
    return box.values.toList();
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    final box = await _box;
    // Kategori ID'yi key olarak kullanıyoruz.
    await box.put(budget.categoryId, budget);
  }

  @override
  Future<void> deleteBudget(String categoryId) async {
    final box = await _box;
    await box.delete(categoryId);
  }
}
