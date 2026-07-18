import 'package:hive/hive.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:injectable/injectable.dart';

abstract class BudgetLocalDataSource {
  Future<List<BudgetModel>> getBudgets(String walletId);
  Future<void> saveBudget(BudgetModel budget);
  Future<void> deleteBudget(String walletId, String categoryId);

  /// Kategori silinirken çağrılır: kategorinin TÜM cüzdanlardaki bütçelerini
  /// (henüz migrasyonlanmamış eski kayıt dahil) temizler.
  Future<void> deleteBudgetsForCategory(String categoryId);

  /// Cüzdan silinirken çağrılır: cüzdana ait tüm bütçeleri temizler
  /// (yetim bütçe kalmasın). Legacy (cüzdansız) kayıtlara dokunmaz.
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
    await _migrateLegacyBudgets(box, walletId);
    return box.values.where((b) => b.walletId == walletId).toList();
  }

  /// walletId öncesi kayıtları (walletId == null, anahtar = çıplak categoryId)
  /// ilk isteyen cüzdana devreder. Eski davranışta bütçeler fiilen "aktif
  /// cüzdanın bütçesi" gibi görünüyordu; ilk yükleme aktif cüzdandan geldiği
  /// için sahiplik oraya geçer. İdempotenttir: ikinci koşuda legacy kayıt kalmaz.
  Future<void> _migrateLegacyBudgets(
      Box<BudgetModel> box, String walletId) async {
    if (walletId.isEmpty) return;
    final legacyKeys = box.keys
        .where((key) => box.get(key)?.walletId == null)
        .toList(growable: false);
    for (final key in legacyKeys) {
      final legacy = box.get(key);
      if (legacy == null) continue;
      final migrated = BudgetModel(
        categoryId: legacy.categoryId,
        limitAmount: legacy.limitAmount,
        walletId: walletId,
      );
      await box.delete(key);
      await box.put(migrated.storageKey, migrated);
    }
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
    if (walletId.isEmpty) return;
    final box = await _box;
    final keys = box.keys
        .where((key) => box.get(key)?.walletId == walletId)
        .toList(growable: false);
    for (final key in keys) {
      await box.delete(key);
    }
  }
}
