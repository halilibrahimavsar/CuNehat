import 'package:cunehat/features/wallet/data/repository/wallet_data_repository.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WalletHiveDataSource implements WalletDataRepository {
  static const String _boxName = 'wallets';
  static const String _usersBoxName = 'users';

  Future<Box<WalletModel>> _getWalletBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<WalletModel>(_boxName);
    }
    return Hive.box<WalletModel>(_boxName);
  }

  Future<Box<Map>> _getUserBox() async {
    if (!Hive.isBoxOpen(_usersBoxName)) {
      return await Hive.openBox<Map>(_usersBoxName);
    }
    return Hive.box<Map>(_usersBoxName);
  }

  @override
  Future<String> createWallet(WalletModel wallet) async {
    final box = await _getWalletBox();

    await box.put(
        wallet.id, wallet); // Firestore'daki kaydedilen document ID gibi
    return wallet.id!;
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    final box = await _getWalletBox();
    await box.delete(walletId);
  }

  @override
  Future<List<WalletModel>> getWallets(String userId) async {
    final box = await _getWalletBox();
    return _filterWalletsByUser(box, userId);
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
    final usersBox = await _getUserBox();
    final userData = usersBox.get(userId, defaultValue: {}) as Map;
    userData['activeWalletId'] = newActiveWalletId;
    await usersBox.put(userId, userData);

    // Tüm cüzdanların isActive durumunu güncelle
    final walletsBox = await _getWalletBox();
    for (var wallet in walletsBox.values.where((w) => w.userId == userId)) {
      final updatedWallet = wallet.copyWith(
        isActive: wallet.id == newActiveWalletId,
      );
      await walletsBox.put(wallet.id, updatedWallet);
    }
  }

  @override
  Future<void> updateWallet(WalletModel wallet) async {
    final box = await _getWalletBox();
    await box.put(wallet.id, wallet);
  }

  @override
  Future<WalletModel?> getActiveWallet(String userId) async {
    final usersBox = await _getUserBox();
    final userData = usersBox.get(userId, defaultValue: {}) as Map;
    final activeWalletId = userData['activeWalletId'] as String?;
    if (activeWalletId != null) {
      final box = await _getWalletBox();
      return box.get(activeWalletId);
    }
    return null;
  }

  @override
  Future<void> updateBalance(String userId, double balance) async {
    final activeWallet = await getActiveWallet(userId);
    if (activeWallet != null) {
      final updatedWallet = activeWallet.copyWith(balance: balance);
      await updateWallet(updatedWallet);
    }
  }

  @override
  Future<void> updateDebt(String userId, double debt) async {
    final activeWallet = await getActiveWallet(userId);
    if (activeWallet != null) {
      final updatedWallet = activeWallet.copyWith(debt: debt);
      await updateWallet(updatedWallet);
    }
  }

  @override
  Future<void> updateCredit(String userId, double credit) async {
    final activeWallet = await getActiveWallet(userId);
    if (activeWallet != null) {
      final updatedWallet = activeWallet.copyWith(credit: credit);
      await updateWallet(updatedWallet);
    }
  }

  @override
  Future<void> updateInvestment(String userId, double save) async {
    final activeWallet = await getActiveWallet(userId);
    if (activeWallet != null) {
      final updatedWallet = activeWallet.copyWith(investment: save);
      await updateWallet(updatedWallet);
    }
  }
}
