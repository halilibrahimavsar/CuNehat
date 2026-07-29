import 'dart:io';
import 'package:cunehat/features/debt_and_receivable/data/datasource/receivable_local_datasource.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late ReceivableLocalDatasource dataSource;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_receivables');
    Hive.init(tempDir.path);
    Hive.registerAdapter(ReceivableModelAdapter());
  });

  setUp(() {
    dataSource = ReceivableLocalDatasource();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('receivables')) {
      final box = Hive.box<ReceivableModel>('receivables');
      await box.clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ReceivableLocalDatasource', () {
    final dueDate = DateTime(2026, 12, 31);
    final testReceivable1 = ReceivableModel(
      id: 'rec_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      debtorName: 'John Doe',
      amount: 1500.0,
      dueDate: dueDate,
      createdAt: DateTime(2026, 1, 1),
    );

    final testReceivable2 = ReceivableModel(
      id: 'rec_2',
      userId: 'user_1',
      walletId: 'wallet_2',
      debtorName: 'Jane Smith',
      amount: 2500.0,
      dueDate: dueDate,
      createdAt: DateTime(2026, 1, 1),
    );

    test('should save and get receivables by walletId successfully', () async {
      await dataSource.addReceivable(testReceivable1);
      await dataSource.addReceivable(testReceivable2);

      final resultWallet1 =
          await dataSource.getReceivablesByWalletId('wallet_1');
      final resultWallet2 =
          await dataSource.getReceivablesByWalletId('wallet_2');

      expect(resultWallet1.length, 1);
      expect(resultWallet1.first.debtorName, 'John Doe');

      expect(resultWallet2.length, 1);
      expect(resultWallet2.first.debtorName, 'Jane Smith');
    });

    test('should update receivable successfully', () async {
      await dataSource.addReceivable(testReceivable1);
      final updated =
          testReceivable1.copyWith(debtorName: 'Updated John', isPaid: true);
      await dataSource.updateReceivable(updated);

      final result = await dataSource.getReceivablesByWalletId('wallet_1');
      expect(result.first.debtorName, 'Updated John');
      expect(result.first.isPaid, true);
    });

    test('should delete receivable successfully', () async {
      await dataSource.addReceivable(testReceivable1);
      await dataSource.deleteReceivable('rec_1');

      final result = await dataSource.getReceivablesByWalletId('wallet_1');
      expect(result.isEmpty, true);
    });
  });
}
