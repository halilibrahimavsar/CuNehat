import 'dart:io';
import 'package:cunehat/features/debt_and_receivable/data/datasource/debt_local_datasource.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_type_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late DebtLocalDatasource dataSource;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_debts');
    Hive.init(tempDir.path);
    Hive.registerAdapter(DebtTypeAdapter());
    Hive.registerAdapter(PaymentModelAdapter());
    Hive.registerAdapter(DebtModelAdapter());
  });

  setUp(() {
    dataSource = DebtLocalDatasource();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('debts')) {
      final box = Hive.box<DebtModel>('debts');
      await box.clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DebtLocalDatasource', () {
    final startDate = DateTime(2026, 1, 1);
    final testDebt1 = DebtModel(
      id: 'debt_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Car Loan',
      counterparty: 'Bank A',
      type: DebtType.bankLoan,
      principalAmount: 10000.0,
      interestRate: 12.0,
      termMonths: 12,
      startDate: startDate,
    );

    final testDebt2 = DebtModel(
      id: 'debt_2',
      userId: 'user_1',
      walletId: 'wallet_2',
      title: 'Personal Loan',
      counterparty: 'Friend B',
      type: DebtType.personalDebt,
      principalAmount: 5000.0,
      interestRate: 0.0,
      termMonths: 6,
      startDate: startDate,
    );

    test('should save and get debts by walletId successfully', () async {
      await dataSource.addDebt(testDebt1);
      await dataSource.addDebt(testDebt2);

      final resultWallet1 = await dataSource.getDebtsByWalletId('wallet_1');
      final resultWallet2 = await dataSource.getDebtsByWalletId('wallet_2');

      expect(resultWallet1.length, 1);
      expect(resultWallet1.first.title, 'Car Loan');

      expect(resultWallet2.length, 1);
      expect(resultWallet2.first.title, 'Personal Loan');
    });

    test('should update debt successfully', () async {
      await dataSource.addDebt(testDebt1);
      final updated =
          testDebt1.copyWith(title: 'Updated Car Loan', isPaid: true);
      await dataSource.updateDebt(updated);

      final result = await dataSource.getDebtsByWalletId('wallet_1');
      expect(result.first.title, 'Updated Car Loan');
      expect(result.first.isPaid, true);
    });

    test('should delete debt successfully', () async {
      await dataSource.addDebt(testDebt1);
      await dataSource.deleteDebt('debt_1');

      final result = await dataSource.getDebtsByWalletId('wallet_1');
      expect(result.isEmpty, true);
    });
  });
}
