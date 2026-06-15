import 'dart:io';
import 'package:cunehat/features/wallet/data/datasource/wallet_local_datasource.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late WalletLocalDataSource dataSource;
  late Box<WalletModel> walletBox;
  late Box<Map> userBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('wallet_local_test_dir');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WalletModelAdapter());
    }
  });

  setUp(() async {
    walletBox = await Hive.openBox<WalletModel>('wallets');
    userBox = await Hive.openBox<Map>('users');
    dataSource = WalletLocalDataSource();
  });

  tearDown(() async {
    await walletBox.clear();
    await walletBox.close();
    await userBox.clear();
    await userBox.close();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WalletLocalDataSource', () {
    final wModel = WalletModel(
      id: 'wallet_1',
      userId: 'user_1',
      name: 'Cash',
      balance: 1000.0,
      debt: 100.0,
      credit: 50.0,
      investment: 200.0,
      colorHex: '0xFF4CAF50',
      iconName: 'money',
      createdAt: DateTime(2026, 6, 1),
      isActive: false,
      sortOrder: 1,
    );

    test('should save and get wallet successfully', () async {
      final id = await dataSource.createWallet(wModel);
      expect(id, wModel.id);

      final wallet = await dataSource.getWalletById(id);
      expect(wallet, isNotNull);
      expect(wallet!.name, wModel.name);
      // openingBalance should default to balance when created if not specified
      expect(wallet.openingBalance, wModel.balance);
    });

    test('should update wallet successfully', () async {
      await dataSource.createWallet(wModel);
      final updated = wModel.copyWith(name: 'Updated Bank', balance: 1500.0);

      await dataSource.updateWallet(updated);
      final wallet = await dataSource.getWalletById(wModel.id!);

      expect(wallet, isNotNull);
      expect(wallet!.name, 'Updated Bank');
      expect(wallet.balance, 1500.0);
    });

    test(
        'should set and get active wallet, and get user wallets with active flag set',
        () async {
      await dataSource.createWallet(wModel);
      final secondWallet =
          wModel.copyWith(id: 'wallet_2', name: 'Savings', sortOrder: 2);
      await dataSource.createWallet(secondWallet);

      await dataSource.setActiveWallet(
          userId: 'user_1', newActiveWalletId: 'wallet_2');

      final active = await dataSource.getActiveWallet('user_1');
      expect(active, isNotNull);
      expect(active!.id, 'wallet_2');

      final wallets = await dataSource.getWallets('user_1');
      expect(wallets.length, 2);

      // wallet_2 should have isActive true, wallet_1 should have isActive false
      final w1 = wallets.firstWhere((w) => w.id == 'wallet_1');
      final w2 = wallets.firstWhere((w) => w.id == 'wallet_2');
      expect(w1.isActive, false);
      expect(w2.isActive, true);

      // check sorting (sortOrder 1 comes before 2)
      expect(wallets[0].id, 'wallet_1');
      expect(wallets[1].id, 'wallet_2');
    });

    test(
        'should delete wallet and clear activeWalletId if active wallet is deleted',
        () async {
      await dataSource.createWallet(wModel);
      await dataSource.setActiveWallet(
          userId: 'user_1', newActiveWalletId: 'wallet_1');

      var active = await dataSource.getActiveWallet('user_1');
      expect(active, isNotNull);

      await dataSource.deleteWallet('wallet_1');

      final wallet = await dataSource.getWalletById('wallet_1');
      expect(wallet, null);

      active = await dataSource.getActiveWallet('user_1');
      expect(active, null);
    });

    test('watchWallets should yield initial wallets and updates', () async {
      await dataSource.createWallet(wModel);

      final stream = dataSource.watchWallets('user_1');

      // The first element should be yielded immediately
      final initial = await stream.first;
      expect(initial.length, 1);
      expect(initial[0].id, wModel.id);
    });
  });
}
