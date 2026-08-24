import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/features/investments/data/models/goal_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

/// Birikim hedeflerinin kalıcı deposu. Hedefler cüzdan bazlıdır (yatırımlar
/// gibi): okuma her zaman userId + walletId ile süzülür.
@singleton
class GoalLocalDataSource {
  static const String boxName = 'goals';

  final HiveInterface _hive;

  @visibleForTesting
  GoalLocalDataSource(this._hive);

  @factoryMethod
  static GoalLocalDataSource create() => GoalLocalDataSource(Hive);

  Future<Box<GoalModel>> _getBox() async {
    if (!_hive.isBoxOpen(boxName)) {
      return await _hive.openBox<GoalModel>(boxName);
    }
    return _hive.box<GoalModel>(boxName);
  }

  Future<List<GoalModel>> getGoals({
    required String userId,
    required String walletId,
  }) async {
    try {
      final box = await _getBox();
      return box.values
          .where((g) => g.userId == userId && g.walletId == walletId)
          .toList();
    } catch (e) {
      throw CacheException('Hedefler okunamadı: $e');
    }
  }

  Future<void> put(GoalModel goal) async {
    try {
      final box = await _getBox();
      await box.put(goal.id, goal);
    } catch (e) {
      throw CacheException('Hedef kaydedilemedi: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final box = await _getBox();
      await box.delete(id);
    } catch (e) {
      throw CacheException('Hedef silinemedi: $e');
    }
  }

  /// Cüzdan silinince hedefleri de gider (bkz. `WalletMetricsService
  /// .purgeWalletData`); öksüz hedef ilerleme hesabında bölen olarak kalırdı.
  Future<void> deleteForWallet(String walletId) async {
    try {
      final box = await _getBox();
      final ids = box.values
          .where((g) => g.walletId == walletId)
          .map((g) => g.id)
          .toList();
      await box.deleteAll(ids);
    } catch (e) {
      throw CacheException('Cüzdanın hedefleri silinemedi: $e');
    }
  }
}
