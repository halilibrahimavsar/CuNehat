import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WalletHiveDataSource implements WalletRepository {
  static const String _boxName = 'wallets';
  static const String _usersBoxName = 'users';

  Future<Box<WalletModel>> get _box async =>
      await Hive.openBox<WalletModel>(_boxName);

  Future<Box<Map>> get _usersBox async =>
      await Hive.openBox<Map>(_usersBoxName);

  @override
  Future<void> createWallet(WalletModel wallet) async {
    final box = await _box;
    final id = UidGenerator.generateWithUserId(wallet.userId);

    await box.put(id, wallet);
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    final box = await _box;
    await box.delete(walletId);
  }

  @override
  Stream<List<WalletModel>> getWallets(String userId) async* {
    final box = await _box;

    // İlk veriyi gönder
    yield _filterWalletsByUser(box, userId);

    // Değişiklikleri dinle
    yield* box.watch().map((_) => _filterWalletsByUser(box, userId));
  }

  List<WalletModel> _filterWalletsByUser(Box<WalletModel> box, String userId) {
    return box.values.where((wallet) => wallet.userId == userId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<void> setActiveWallet({
    required String userId,
    required String newActiveWalletId,
  }) async {
    final usersBox = await _usersBox;
    final userData = usersBox.get(userId, defaultValue: {}) as Map;
    userData['activeWalletId'] = newActiveWalletId;
    await usersBox.put(userId, userData);

    // Tüm cüzdanların isActive durumunu güncelle
    final walletsBox = await _box;
    for (var wallet in walletsBox.values.where((w) => w.userId == userId)) {
      final updatedWallet = wallet.copyWith(
        isActive: wallet.id == newActiveWalletId,
      );
      await walletsBox.put(wallet.id, updatedWallet);
    }
  }

  @override
  Future<void> updateWallet(WalletModel wallet) async {
    final box = await _box;
    await box.put(wallet.id, wallet);
  }
}
