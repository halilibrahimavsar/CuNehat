import 'dart:async';

import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@singleton
class WalletLocalDataSource {
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

  Future<String> createWallet(WalletModel wallet) async {
    final box = await _getWalletBox();

    // Açılış bakiyesini sakla (sapma onarımı / syncBalance için referans).
    final toSave = wallet.openingBalance == null
        ? wallet.copyWith(openingBalance: wallet.balance)
        : wallet;
    await box.put(
        toSave.id, toSave); // Firestore'daki kaydedilen document ID gibi
    return toSave.id!;
  }

  Future<void> deleteWallet(String walletId) async {
    final box = await _getWalletBox();
    final wallet = box.get(walletId);
    if (wallet != null) {
      final userId = wallet.userId;
      final usersBox = await _getUserBox();
      final userData = usersBox.get(userId, defaultValue: {}) as Map;
      final activeWalletId = userData['activeWalletId'] as String?;

      if (activeWalletId == walletId) {
        userData.remove('activeWalletId');
        await usersBox.put(userId, userData);
      }

      await box.delete(walletId);
    }
  }

  Future<List<WalletModel>> getWallets(String userId) async {
    final box = await _getWalletBox();
    final usersBox = await _getUserBox();
    final userData = usersBox.get(userId, defaultValue: {}) as Map;
    final activeWalletId = userData['activeWalletId'] as String?;

    return box.values
        .where((wallet) => wallet.userId == userId)
        .map((wallet) => wallet.copyWith(
              isActive: wallet.id == activeWalletId,
            ))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> setActiveWallet({
    required String userId,
    required String newActiveWalletId,
  }) async {
    final usersBox = await _getUserBox();
    final userData = usersBox.get(userId, defaultValue: {}) as Map;
    userData['activeWalletId'] = newActiveWalletId;
    await usersBox.put(userId, userData);

    // isActive field in WalletModel is now primarily for UI/convenience
    // but we can still update it in the box if we want persistent field.
    // However, getWallets now populates it dynamically.
  }

  Future<void> updateWallet(WalletModel wallet) async {
    final box = await _getWalletBox();
    await box.put(wallet.id, wallet);
  }

  Future<WalletModel?> getWalletById(String walletId) async {
    final box = await _getWalletBox();
    return box.get(walletId);
  }

  Stream<List<WalletModel>> watchWallets(String userId) async* {
    final walletBox = await _getWalletBox();
    final userBox = await _getUserBox();

    yield await getWallets(userId);

    final controller = StreamController<List<WalletModel>>();

    Future<void> emitWallets() async {
      if (controller.isClosed) return;
      try {
        controller.add(await getWallets(userId));
      } catch (e, st) {
        controller.addError(e, st);
      }
    }

    final walletSub = walletBox.watch().listen((_) => emitWallets());
    final userSub = userBox.watch(key: userId).listen((_) => emitWallets());

    controller.onCancel = () async {
      await walletSub.cancel();
      await userSub.cancel();
      await controller.close();
    };

    yield* controller.stream;
  }

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
}
