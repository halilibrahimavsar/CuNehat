import 'package:cunehat/features/budgets/data/models/temp_budget_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

/// Tek seferlik bütçelerin kalıcı deposu (`temp_budgets_box`, anahtar `id`).
@lazySingleton
class TempBudgetLocalDataSource {
  static const String boxName = 'temp_budgets_box';

  final HiveInterface _hive;

  @visibleForTesting
  TempBudgetLocalDataSource(this._hive);

  @factoryMethod
  static TempBudgetLocalDataSource create() => TempBudgetLocalDataSource(Hive);

  Future<Box<TempBudgetModel>> get _box async {
    if (_hive.isBoxOpen(boxName)) return _hive.box<TempBudgetModel>(boxName);
    return _hive.openBox<TempBudgetModel>(boxName);
  }

  Future<List<TempBudgetModel>> getForWallet(String walletId) async {
    final box = await _box;
    return box.values.where((b) => b.walletId == walletId).toList();
  }

  Future<List<TempBudgetModel>> getAll() async {
    final box = await _box;
    return box.values.toList();
  }

  Future<TempBudgetModel?> getById(String id) async {
    final box = await _box;
    return box.get(id);
  }

  Future<void> put(TempBudgetModel model) async {
    final box = await _box;
    await box.put(model.id, model);
  }

  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  /// Cüzdan silinirken: cüzdanın tüm geçici bütçeleri (yetim kalmasın).
  Future<void> deleteForWallet(String walletId) async {
    final box = await _box;
    final keys = [
      for (final key in box.keys)
        if (box.get(key)?.walletId == walletId) key,
    ];
    await box.deleteAll(keys);
  }

  /// Kategori silinirken: kategori her bütçenin listesinden düşer; listesi
  /// boşalan bütçe silinir (hiçbir şey saymayan bir bütçe "0 / 15.000 ·
  /// sığıyor" diye yalan söylerdi).
  Future<void> removeCategory(String categoryId) async {
    final box = await _box;
    for (final key in box.keys.toList(growable: false)) {
      final model = box.get(key);
      if (model == null || !model.categoryIds.contains(categoryId)) continue;
      final rest = [
        for (final id in model.categoryIds)
          if (id != categoryId) id,
      ];
      if (rest.isEmpty) {
        await box.delete(key);
      } else {
        await box.put(
          key,
          TempBudgetModel(
            id: model.id,
            walletId: model.walletId,
            name: model.name,
            limitAmount: model.limitAmount,
            startDate: model.startDate,
            endDate: model.endDate,
            categoryIds: rest,
          ),
        );
      }
    }
  }
}
