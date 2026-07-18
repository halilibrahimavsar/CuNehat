import 'package:hive/hive.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:injectable/injectable.dart';

abstract class BudgetLocalDataSource {
  Future<List<BudgetModel>> getBudgets(String walletId);
  Future<void> saveBudget(BudgetModel budget);
  Future<void> deleteBudget(String walletId, String categoryId);

  /// Kategori silinirken çağrılır: kategorinin TÜM cüzdanlardaki bütçelerini
  /// temizler.
  Future<void> deleteBudgetsForCategory(String categoryId);

  /// Cüzdan silinirken çağrılır: cüzdana ait tüm bütçeleri temizler
  /// (yetim bütçe kalmasın).
  Future<void> deleteBudgetsForWallet(String walletId);
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
  Future<List<BudgetModel>> getBudgets(String walletId) async {
    final box = await _box;
    return box.values.where((b) => b.walletId == walletId).toList();
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    final box = await _box;
    // Cüzdan+kategori bileşik anahtar: aynı kategori cüzdan başına ayrı bütçe.
    await box.put(budget.storageKey, budget);
  }

  @override
  Future<void> deleteBudget(String walletId, String categoryId) async {
    final box = await _box;
    await box.delete(BudgetModel.buildStorageKey(walletId, categoryId));
  }

  @override
  Future<void> deleteBudgetsForCategory(String categoryId) async {
    final box = await _box;
    final keys = box.keys
        .where((key) => box.get(key)?.categoryId == categoryId)
        .toList(growable: false);
    for (final key in keys) {
      await box.delete(key);
    }
  }

  @override
  Future<void> deleteBudgetsForWallet(String walletId) async {
    final box = await _box;
    final keys = box.keys
        .where((key) => box.get(key)?.walletId == walletId)
        .toList(growable: false);
    for (final key in keys) {
      await box.delete(key);
    }
  }
}
