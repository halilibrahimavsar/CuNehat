import 'dart:io';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/data/datasources/recurring_transaction_local_datasource.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;
  late RecurringTransactionLocalDataSourceImpl dataSource;
  late Box<RecurringTransactionModel> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('recurring_tx_test_dir');
    Hive.init(tempDir.path);

    // Register required Hive adapters
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TransactionTypeModelAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(RecurringTransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(RecurringFrequencyAdapter());
    }
  });

  setUp(() async {
    box = await Hive.openBox<RecurringTransactionModel>(
        'recurring_transactions_box');
    dataSource = RecurringTransactionLocalDataSourceImpl();
  });

  tearDown(() async {
    await box.clear();
    await box.close();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('RecurringTransactionLocalDataSourceImpl', () {
    final tModel = RecurringTransactionModel(
      id: 'rec_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Rent',
      tag: 'housing',
      amount: 1500.0,
      type: TransactionTypeModel.expense,
      frequency: RecurringFrequency.monthly,
      nextExecutionDate: DateTime(2026, 6, 1),
      isActive: true,
    );

    test('should save and get all templates successfully', () async {
      await dataSource.saveTemplate(tModel);

      final templates = await dataSource.getAllTemplates();

      expect(templates.length, 1);
      expect(templates[0], tModel);
    });

    test('should delete template successfully', () async {
      await dataSource.saveTemplate(tModel);
      var templates = await dataSource.getAllTemplates();
      expect(templates.length, 1);

      await dataSource.deleteTemplate(tModel.id);

      templates = await dataSource.getAllTemplates();
      expect(templates, isEmpty);
    });

    test(
        'should return pending transactions (active and execution date <= now)',
        () async {
      final now = DateTime.now();

      final pendingActive = RecurringTransactionModel(
        id: 'rec_pending_active',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Electricity',
        tag: 'bills',
        amount: 200.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: now.subtract(const Duration(days: 1)),
        isActive: true,
      );

      final pendingToday = RecurringTransactionModel(
        id: 'rec_pending_today',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Water',
        tag: 'bills',
        amount: 50.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: now,
        isActive: true,
      );

      final futureActive = RecurringTransactionModel(
        id: 'rec_future_active',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Netflix',
        tag: 'entertainment',
        amount: 15.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: now.add(const Duration(days: 1)),
        isActive: true,
      );

      final pendingInactive = RecurringTransactionModel(
        id: 'rec_pending_inactive',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Gym',
        tag: 'sports',
        amount: 80.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: now.subtract(const Duration(days: 1)),
        isActive: false,
      );

      await dataSource.saveTemplate(pendingActive);
      await dataSource.saveTemplate(pendingToday);
      await dataSource.saveTemplate(futureActive);
      await dataSource.saveTemplate(pendingInactive);

      final pending = await dataSource.getPendingTransactions();

      expect(pending.length, 2);
      expect(pending.contains(pendingActive), true);
      expect(pending.contains(pendingToday), true);
      expect(pending.contains(futureActive), false);
      expect(pending.contains(pendingInactive), false);
    });
  });
}
