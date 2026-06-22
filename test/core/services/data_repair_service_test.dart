import 'dart:io';
import 'package:cunehat/core/services/data_repair_service.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_type_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/models/investment_type_adapter.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/color_adapter.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

void main() {
  late Directory tempDir;
  late MockWalletMetricsService mockWalletMetricsService;
  late DataRepairService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cunehat_repair_test_');
    Hive.init(tempDir.path);

    void register<T>(TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }
    }

    register(WalletModelAdapter());
    register(TransactionModelAdapter());
    register(TransactionTypeModelAdapter());
    register(InvestmentModelAdapter());
    register(InvestmentTypeAdapter());
    register(DebtModelAdapter());
    register(ReceivableModelAdapter());
    register(PaymentModelAdapter());
    register(DebtTypeAdapter());
    register(ColorAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    mockWalletMetricsService = MockWalletMetricsService();
    service = DataRepairService(mockWalletMetricsService);

    await Hive.openBox<WalletModel>('wallets');
    await Hive.openBox<TransactionModel>('transactions');
    await Hive.openBox<DebtModel>('debts');
    await Hive.openBox<ReceivableModel>('receivables');
    await Hive.openBox<InvestmentModel>('investments_box');
  });

  tearDown(() async {
    if (Hive.isBoxOpen('wallets')) {
      await Hive.box<WalletModel>('wallets').clear();
    }
    if (Hive.isBoxOpen('transactions')) {
      await Hive.box<TransactionModel>('transactions').clear();
    }
    if (Hive.isBoxOpen('debts')) {
      await Hive.box<DebtModel>('debts').clear();
    }
    if (Hive.isBoxOpen('receivables')) {
      await Hive.box<ReceivableModel>('receivables').clear();
    }
    if (Hive.isBoxOpen('investments_box')) {
      await Hive.box<InvestmentModel>('investments_box').clear();
    }
  });

  group('planUserIdRepairs', () {
    test('should return empty list when no records mismatch', () {
      final walletUserIds = {'w1': 'u1', 'w2': 'u2'};
      final records = [
        (key: 'k1', userId: 'u1', walletId: 'w1'),
        (key: 'k2', userId: 'u2', walletId: 'w2'),
      ];
      final result =
          planUserIdRepairs(walletUserIds: walletUserIds, records: records);
      expect(result, isEmpty);
    });

    test(
        'should identify records that have mismatching userId compared to the wallet owner',
        () {
      final walletUserIds = {'w1': 'u1', 'w2': 'u2'};
      final records = [
        (key: 'k1', userId: 'u_wrong', walletId: 'w1'),
        (key: 'k2', userId: 'u2', walletId: 'w2'),
        (key: 'k3', userId: 'unknown_user', walletId: 'w1'),
      ];
      final result =
          planUserIdRepairs(walletUserIds: walletUserIds, records: records);
      expect(result.length, 2);
      expect(result[0].key, 'k1');
      expect(result[0].correctUserId, 'u1');
      expect(result[1].key, 'k3');
      expect(result[1].correctUserId, 'u1');
    });

    test('should ignore records with unknown wallets (orphans)', () {
      final walletUserIds = {'w1': 'u1'};
      final records = [
        (key: 'k1', userId: 'u_wrong', walletId: 'w_unknown'),
      ];
      final result =
          planUserIdRepairs(walletUserIds: walletUserIds, records: records);
      expect(result, isEmpty);
    });
  });

  group('DataRepairService.run', () {
    test('should return early when wallets are empty', () async {
      await service.run();
      verifyNoMoreInteractions(mockWalletMetricsService);
    });

    test(
        'should repair incorrect userId in transactions, debts, receivables, investments and trigger syncs',
        () async {
      final walletBox = Hive.box<WalletModel>('wallets');
      await walletBox.put(
          'w1',
          WalletModel(
            id: 'w1',
            userId: 'correct_user',
            name: 'W1',
            balance: 100,
            debt: 0,
            credit: 0,
            investment: 0,
            colorHex: '#000000',
            iconName: 'wallet',
            createdAt: DateTime.now(),
          ));

      final txBox = Hive.box<TransactionModel>('transactions');
      await txBox.put(
          't1',
          TransactionModel(
            id: 't1',
            userId: 'wrong_user',
            walletId: 'w1',
            title: 'T1',
            tag: 'tag',
            amount: 50,
            date: DateTime.now(),
            type: TransactionTypeModel.income,
          ));

      final debtBox = Hive.box<DebtModel>('debts');
      await debtBox.put(
          'd1',
          DebtModel(
            id: 'd1',
            userId: 'wrong_user',
            walletId: 'w1',
            title: 'D1',
            counterparty: 'C1',
            principalAmount: 100,
            interestRate: 0,
            termMonths: 1,
            startDate: DateTime.now(),
            isPaid: false,
            payments: const [],
            type: DebtType.personalDebt,
          ));

      final recBox = Hive.box<ReceivableModel>('receivables');
      await recBox.put(
          'r1',
          ReceivableModel(
            id: 'r1',
            userId: 'wrong_user',
            walletId: 'w1',
            debtorName: 'C2',
            amount: 200,
            dueDate: DateTime.now(),
            isPaid: false,
            notes: null,
          ));

      final invBox = Hive.box<InvestmentModel>('investments_box');
      await invBox.put(
          'i1',
          InvestmentModel(
            id: 'i1',
            userId: 'wrong_user',
            walletId: 'w1',
            name: 'I1',
            amount: 1,
            currentValue: 100,
            type: InvestmentType.stock,
            color: const Color(0xFF000000),
            dateAdded: DateTime.now(),
          ));

      when(() => mockWalletMetricsService.syncBalance('w1'))
          .thenAnswer((_) async => true);
      when(() => mockWalletMetricsService.syncDebt('w1'))
          .thenAnswer((_) async {});
      when(() => mockWalletMetricsService.syncCredit('w1'))
          .thenAnswer((_) async {});
      when(() => mockWalletMetricsService.syncInvestment('w1'))
          .thenAnswer((_) async {});

      await service.run();

      expect(txBox.get('t1')!.userId, 'correct_user');
      expect(debtBox.get('d1')!.userId, 'correct_user');
      expect(recBox.get('r1')!.userId, 'correct_user');
      expect(invBox.get('i1')!.userId, 'correct_user');

      verify(() => mockWalletMetricsService.syncBalance('w1')).called(1);
      verify(() => mockWalletMetricsService.syncDebt('w1')).called(1);
      verify(() => mockWalletMetricsService.syncCredit('w1')).called(1);
      verify(() => mockWalletMetricsService.syncInvestment('w1')).called(1);
    });

    test('should not crash if exception is thrown', () async {
      await Hive.close();
      await expectLater(service.run(), completes);
    });
  });
}
