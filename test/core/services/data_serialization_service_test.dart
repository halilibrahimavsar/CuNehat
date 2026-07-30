import 'dart:convert';
import 'dart:io';

import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_type_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/models/investment_type_adapter.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/color_adapter.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHiveInterface extends Mock implements HiveInterface {}

class MockNotificationService extends Mock implements NotificationService {}

class MockReminderSyncService extends Mock implements ReminderSyncService {}

class MockBox<T> extends Mock implements Box<T> {}

class FakeWalletModel extends Fake implements WalletModel {}

class FakeTransactionModel extends Fake implements TransactionModel {}

class FakeInvestmentModel extends Fake implements InvestmentModel {}

class FakeDebtModel extends Fake implements DebtModel {}

class FakeReceivableModel extends Fake implements ReceivableModel {}

class FakeBudgetModel extends Fake implements BudgetModel {}

class FakeRecurringTransactionModel extends Fake
    implements RecurringTransactionModel {}

void main() {
  late Directory tempDir;
  late DataSerializationService service;
  late MockNotificationService notifications;
  late MockReminderSyncService reminderSync;

  setUpAll(() async {
    registerFallbackValue(FakeWalletModel());
    registerFallbackValue(FakeTransactionModel());
    registerFallbackValue(FakeInvestmentModel());
    registerFallbackValue(FakeDebtModel());
    registerFallbackValue(FakeReceivableModel());
    registerFallbackValue(FakeBudgetModel());
    registerFallbackValue(FakeRecurringTransactionModel());

    tempDir = await Directory.systemTemp.createTemp('cunehat_backup_test_');
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
    register(BudgetModelAdapter());
    register(RecurringTransactionModelAdapter());
    register(RecurringFrequencyAdapter());
    register(ColorAdapter());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    notifications = MockNotificationService();
    reminderSync = MockReminderSyncService();
    when(() => notifications.cancelAllNotifications()).thenAnswer((_) async {});
    when(() => reminderSync.syncAll()).thenAnswer((_) async {});
    service = DataSerializationService(
      ReceiptStorageService.withBaseDir(tempDir),
      notifications,
      reminderSync,
    );
    await _openAllBoxes();
    await _clearAllBoxes();
  });

  tearDown(() async {
    await _clearAllBoxes();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('exports all v3 sections including budgets and recurring templates',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CategoryService.backupKeys.first, 'custom-cats');

    await Hive.box<WalletModel>('wallets').put('w1', _wallet());
    await Hive.box<TransactionModel>('transactions').put('t1', _transaction());
    await Hive.box<InvestmentModel>('investments_box').put('i1', _investment());
    await Hive.box<DebtModel>('debts').put('d1', _debt());
    await Hive.box<ReceivableModel>('receivables').put('r1', _receivable());
    await Hive.box<BudgetModel>('budgets_box').put(
      'food',
      BudgetModel(categoryId: 'food', limitAmount: 1200, walletId: 'w1'),
    );
    await Hive.box<RecurringTransactionModel>('recurring_transactions_box').put(
      'rec1',
      _recurring(),
    );
    await Hive.box<Map>('users').put('u1', {'activeWalletId': 'w1'});

    final jsonString = await service.exportDataToJson();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    expect(data['version'], DataSerializationService.schemaVersion);
    expect(data['wallets'], hasLength(1));
    expect(data['transactions'], hasLength(1));
    expect(data['investments'], hasLength(1));
    expect(data['debts'], hasLength(1));
    expect(data['receivables'], hasLength(1));
    expect(data['budgets'], hasLength(1));
    expect(data['recurringTransactions'], hasLength(1));
    expect((data['users'] as Map)['u1']['activeWalletId'], 'w1');
    expect((data['categories'] as Map)[CategoryService.backupKeys.first],
        'custom-cats');
  });

  test('clearAllLocalData tüm kutuları ve kategori tercihlerini temizler',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CategoryService.backupKeys.first, 'custom-cats');

    await Hive.box<WalletModel>('wallets').put('w1', _wallet());
    await Hive.box<TransactionModel>('transactions').put('t1', _transaction());
    await Hive.box<InvestmentModel>('investments_box').put('i1', _investment());
    await Hive.box<DebtModel>('debts').put('d1', _debt());
    await Hive.box<ReceivableModel>('receivables').put('r1', _receivable());
    await Hive.box<BudgetModel>('budgets_box').put(
      'food',
      BudgetModel(categoryId: 'food', limitAmount: 1200, walletId: 'w1'),
    );
    await Hive.box<RecurringTransactionModel>('recurring_transactions_box').put(
      'rec1',
      _recurring(),
    );
    await Hive.box<Map>('users').put('u1', {'activeWalletId': 'w1'});

    await service.clearAllLocalData();

    expect(Hive.box<WalletModel>('wallets').values, isEmpty);
    expect(Hive.box<TransactionModel>('transactions').values, isEmpty);
    expect(Hive.box<InvestmentModel>('investments_box').values, isEmpty);
    expect(Hive.box<DebtModel>('debts').values, isEmpty);
    expect(Hive.box<ReceivableModel>('receivables').values, isEmpty);
    expect(Hive.box<BudgetModel>('budgets_box').values, isEmpty);
    expect(
      Hive.box<RecurringTransactionModel>('recurring_transactions_box').values,
      isEmpty,
    );
    expect(Hive.box<Map>('users').values, isEmpty);
    expect(prefs.getString(CategoryService.backupKeys.first), isNull);
  });

  test('sürümü eşleşmeyen yedek reddedilir ve mevcut veri korunur', () async {
    await Hive.box<WalletModel>('wallets').put('w1', _wallet());

    final oldBackup = jsonEncode({
      'version': DataSerializationService.schemaVersion + 1,
      'wallets': [],
      'transactions': [],
      'investments': [],
      'debts': [],
      'receivables': [],
      'users': {},
    });

    final result = await service.importDataFromJson(oldBackup);

    // `invalidFormat` DEĞİL: dosya sapasağlam, yalnız şeması farklı. Kullanıcıya
    // "yedek bozuk" demek yalan olurdu; bulunan sürüm de mesaja taşınır.
    expect(result.status, DataRestoreStatus.versionMismatch);
    expect(result.foundVersion, DataSerializationService.schemaVersion + 1);
    expect(Hive.box<WalletModel>('wallets').get('w1')?.name, 'Main');
  });

  test('bozuk JSON sürüm uyuşmazlığından ayrı raporlanır', () async {
    await Hive.box<WalletModel>('wallets').put('w1', _wallet());

    final result = await service.importDataFromJson('{ bu json değil');

    expect(result.status, DataRestoreStatus.invalidFormat);
    expect(Hive.box<WalletModel>('wallets').get('w1')?.name, 'Main');
  });

  test('cüzdan para birimi export/import round-trip ile korunur', () async {
    await Hive.box<WalletModel>('wallets')
        .put('w1', _wallet().copyWith(currency: 'USD'));

    final jsonString = await service.exportDataToJson();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    expect((data['wallets'] as List).single['currency'], 'USD');

    await service.clearAllLocalData();
    final result = await service.importDataFromJson(jsonString);

    expect(result.isSuccess, true);
    expect(Hive.box<WalletModel>('wallets').get('w1')?.currency, 'USD');
  });

  test('rejects malformed JSON without touching current data', () async {
    await Hive.box<WalletModel>('wallets').put('w1', _wallet());

    final result = await service.importDataFromJson('{bad json');

    expect(result.status, DataRestoreStatus.invalidFormat);
    expect(Hive.box<WalletModel>('wallets').get('w1')?.name, 'Main');
  });

  group('planlanmış hatırlatmaların yaşam döngüsü', () {
    // REGRESYON: hatırlatmalar Hive'da değil OS'ta yaşar. Kutuları boşaltmak
    // ya da geri yüklemek onları etkilemediğinden, silinmiş/değişmiş kayıtların
    // bildirimleri günlerce gelmeye devam ediyordu.
    test('clearAllLocalData planlanmış tüm bildirimleri de iptal eder',
        () async {
      await service.clearAllLocalData();

      verify(() => notifications.cancelAllNotifications()).called(1);
    });

    test('başarılı geri yükleme eski bildirimleri düşürüp yenilerini kurar',
        () async {
      await Hive.box<WalletModel>('wallets').put('w1', _wallet());
      await Hive.box<RecurringTransactionModel>('recurring_transactions_box')
          .put('rec1', _recurring());
      final backup = await service.exportDataToJson();

      final result = await service.importDataFromJson(backup);

      expect(result.isSuccess, true);
      verify(() => notifications.cancelAllNotifications()).called(1);
      verify(() => reminderSync.syncAll()).called(1);
    });

    test('geçersiz yedekte hatırlatmalara dokunulmaz', () async {
      final result = await service.importDataFromJson('{bad json');

      expect(result.status, DataRestoreStatus.invalidFormat);
      verifyNever(() => notifications.cancelAllNotifications());
      verifyNever(() => reminderSync.syncAll());
    });
  });

  test('rolls back boxes and category prefs when a write fails', () async {
    SharedPreferences.setMockInitialValues({
      CategoryService.backupKeys.first: 'old-cats',
    });

    final mockHive = MockHiveInterface();
    final walletBox = MockBox<WalletModel>();
    final transactionBox = MockBox<TransactionModel>();
    final investmentBox = MockBox<InvestmentModel>();
    final debtBox = MockBox<DebtModel>();
    final receivableBox = MockBox<ReceivableModel>();
    final budgetBox = MockBox<BudgetModel>();
    final recurringBox = MockBox<RecurringTransactionModel>();
    final userBox = MockBox<Map>();

    _stubBox(walletBox, {'old-wallet': _wallet(id: 'old-wallet')});
    _stubBox<TransactionModel>(transactionBox, {});
    _stubBox<InvestmentModel>(investmentBox, {});
    _stubBox<DebtModel>(debtBox, {});
    _stubBox<ReceivableModel>(receivableBox, {});
    _stubBox<BudgetModel>(budgetBox, {});
    _stubBox<RecurringTransactionModel>(recurringBox, {});
    _stubBox<Map>(userBox, {});

    when(() => walletBox.put(any(), any()))
        .thenThrow(Exception('write failed'));

    when(() => mockHive.openBox<WalletModel>('wallets'))
        .thenAnswer((_) async => walletBox);
    when(() => mockHive.openBox<TransactionModel>('transactions'))
        .thenAnswer((_) async => transactionBox);
    when(() => mockHive.openBox<InvestmentModel>('investments_box'))
        .thenAnswer((_) async => investmentBox);
    when(() => mockHive.openBox<DebtModel>('debts'))
        .thenAnswer((_) async => debtBox);
    when(() => mockHive.openBox<ReceivableModel>('receivables'))
        .thenAnswer((_) async => receivableBox);
    when(() => mockHive.openBox<BudgetModel>('budgets_box'))
        .thenAnswer((_) async => budgetBox);
    when(() => mockHive.openBox<RecurringTransactionModel>(
        'recurring_transactions_box')).thenAnswer((_) async => recurringBox);
    when(() => mockHive.openBox<Map>('users')).thenAnswer((_) async => userBox);

    final failingService = DataSerializationService.withHive(
      mockHive,
      ReceiptStorageService.withBaseDir(tempDir),
      notifications,
      reminderSync,
    );
    final backup = jsonEncode({
      'version': DataSerializationService.schemaVersion,
      'wallets': [_wallet().toJson()],
      'transactions': [],
      'investments': [],
      'debts': [],
      'receivables': [],
      'budgets': [],
      'recurringTransactions': [],
      'users': {},
      'categories': {CategoryService.backupKeys.first: 'new-cats'},
    });

    final result = await failingService.importDataFromJson(backup);
    final prefs = await SharedPreferences.getInstance();

    expect(result.status, DataRestoreStatus.writeFailure);
    verify(() => walletBox.putAll(any())).called(1);
    verify(() => transactionBox.putAll(any())).called(1);
    verify(() => budgetBox.putAll(any())).called(1);
    verify(() => recurringBox.putAll(any())).called(1);
    expect(prefs.getString(CategoryService.backupKeys.first), 'old-cats');
  });

  // ===================================================== önizleme (inspect)

  group('inspectBackup', () {
    test('yedeği YAZMADAN özetler', () async {
      await Hive.box<WalletModel>('wallets').put('w1', _wallet());
      await Hive.box<TransactionModel>('transactions')
          .put('t1', _transaction());
      final backup = await service.exportDataToJson();

      // Cihazı boşalt: inceleme yerel veriye dokunmamalı.
      await _clearAllBoxes();

      final inspection = service.inspectBackup(backup);

      expect(inspection.status, BackupInspectionStatus.ok);
      expect(inspection.isRestorable, isTrue);

      final summary = inspection.summary!;
      expect(summary.walletCount, 1);
      expect(summary.transactionCount, 1);
      expect(summary.totalIncome, 1000);
      expect(summary.totalExpense, 0);
      expect(summary.firstTransactionDate, DateTime(2024, 1, 2));
      expect(summary.lastTransactionDate, DateTime(2024, 1, 2));
      expect(summary.wallets.single.name, 'Main');
      expect(summary.wallets.single.currency, 'TRY');
      expect(summary.createdAt, isNotNull);
      expect(summary.isEmpty, isFalse);

      // İncelemenin YAZMADIĞININ kanıtı: kutular hâlâ boş.
      expect(Hive.box<WalletModel>('wallets').length, 0);
      expect(Hive.box<TransactionModel>('transactions').length, 0);
    });

    test('fişli işlem sayısı uyarı için ayrı sayılır', () async {
      await Hive.box<TransactionModel>('transactions').put(
        't1',
        TransactionModel(
          id: 't1',
          userId: 'u1',
          walletId: 'w1',
          title: 'Market',
          tag: 'Yemek',
          amount: 250,
          date: DateTime(2024, 3, 4),
          type: TransactionTypeModel.expense,
          receiptFileName: 'fis1.jpg',
        ),
      );

      final inspection =
          service.inspectBackup(await service.exportDataToJson());

      expect(inspection.summary!.transactionsWithReceipt, 1);
      expect(inspection.summary!.totalExpense, 250);
    });

    test('sürüm uyuşmazlığı bozukluktan ayrı raporlanır', () {
      final foreign = jsonEncode({
        'version': DataSerializationService.schemaVersion + 1,
        'wallets': <dynamic>[],
      });

      final inspection = service.inspectBackup(foreign);

      expect(inspection.status, BackupInspectionStatus.versionMismatch);
      expect(
          inspection.foundVersion, DataSerializationService.schemaVersion + 1);
      expect(
          inspection.expectedVersion, DataSerializationService.schemaVersion);
      expect(inspection.isRestorable, isFalse);
      expect(inspection.summary, isNull);
    });

    // 0 baytlı/yarım yüklenmiş dosya: eski akışta "yedek bulunamadı" deniyordu.
    test('boş veya bozuk içerik corrupt döner', () {
      expect(service.inspectBackup('').status, BackupInspectionStatus.corrupt);
      expect(service.inspectBackup('{ bozuk').status,
          BackupInspectionStatus.corrupt);
      expect(
          service.inspectBackup('[]').status, BackupInspectionStatus.corrupt);
    });

    test('boş yedek geçerlidir ama isEmpty ile işaretlenir', () async {
      await _clearAllBoxes();

      final inspection =
          service.inspectBackup(await service.exportDataToJson());

      expect(inspection.status, BackupInspectionStatus.ok);
      expect(inspection.summary!.isEmpty, isTrue);
      expect(inspection.summary!.recordCount, 0);
    });
  });

  group('currentDataSummary', () {
    test('cihazdaki veriyi yedek özetiyle aynı biçimde sayar', () async {
      await Hive.box<WalletModel>('wallets').put('w1', _wallet());
      await Hive.box<TransactionModel>('transactions')
          .put('t1', _transaction());
      await Hive.box<DebtModel>('debts').put('d1', _debt());

      final summary = await service.currentDataSummary();

      expect(summary.walletCount, 1);
      expect(summary.transactionCount, 1);
      expect(summary.debtCount, 1);
      expect(summary.recordCount, 3);
      expect(summary.isEmpty, isFalse);
      // Cihaz özetinde "yedek tarihi" kavramı yok.
      expect(summary.createdAt, isNull);
    });

    test('veri yokken isEmpty true — boş yedek kapısının dayanağı', () async {
      await _clearAllBoxes();

      final summary = await service.currentDataSummary();

      expect(summary.isEmpty, isTrue);
    });
  });
}

Future<void> _openAllBoxes() async {
  await Hive.openBox<WalletModel>('wallets');
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<InvestmentModel>('investments_box');
  await Hive.openBox<DebtModel>('debts');
  await Hive.openBox<ReceivableModel>('receivables');
  await Hive.openBox<BudgetModel>('budgets_box');
  await Hive.openBox<RecurringTransactionModel>('recurring_transactions_box');
  await Hive.openBox<Map>('users');
}

Future<void> _clearAllBoxes() async {
  if (Hive.isBoxOpen('wallets')) {
    await Hive.box<WalletModel>('wallets').clear();
  }
  if (Hive.isBoxOpen('transactions')) {
    await Hive.box<TransactionModel>('transactions').clear();
  }
  if (Hive.isBoxOpen('investments_box')) {
    await Hive.box<InvestmentModel>('investments_box').clear();
  }
  if (Hive.isBoxOpen('debts')) {
    await Hive.box<DebtModel>('debts').clear();
  }
  if (Hive.isBoxOpen('receivables')) {
    await Hive.box<ReceivableModel>('receivables').clear();
  }
  if (Hive.isBoxOpen('budgets_box')) {
    await Hive.box<BudgetModel>('budgets_box').clear();
  }
  if (Hive.isBoxOpen('recurring_transactions_box')) {
    await Hive.box<RecurringTransactionModel>('recurring_transactions_box')
        .clear();
  }
  if (Hive.isBoxOpen('users')) {
    await Hive.box<Map>('users').clear();
  }
}

void _stubBox<T>(MockBox<T> box, Map<dynamic, T> snapshot) {
  when(() => box.toMap()).thenReturn(snapshot);
  when(() => box.clear()).thenAnswer((_) async => 0);
  when(() => box.put(any(), any())).thenAnswer((_) async {});
  when(() => box.putAll(any())).thenAnswer((_) async {});
}

WalletModel _wallet({String id = 'w1'}) {
  return WalletModel(
    id: id,
    userId: 'u1',
    name: 'Main',
    balance: 100,
    debt: 50,
    credit: 25,
    investment: 75,
    colorHex: '0xFF2196F3',
    iconName: 'wallet',
    createdAt: DateTime(2024, 1, 1),
    isActive: true,
    openingBalance: 100,
  );
}

TransactionModel _transaction() {
  return TransactionModel(
    id: 't1',
    userId: 'u1',
    walletId: 'w1',
    title: 'Salary',
    tag: 'Work',
    amount: 1000,
    date: DateTime(2024, 1, 2),
    type: TransactionTypeModel.income,
  );
}

InvestmentModel _investment() {
  return InvestmentModel(
    id: 'i1',
    userId: 'u1',
    walletId: 'w1',
    name: 'Gold',
    amount: 500,
    currentValue: 650,
    type: InvestmentType.gold,
    color: const Color(0xFFFFD700),
    dateAdded: DateTime(2024, 1, 3),
    goalCategory: 'araba',
  );
}

DebtModel _debt() {
  return DebtModel(
    id: 'd1',
    userId: 'u1',
    walletId: 'w1',
    title: 'Loan',
    counterparty: 'Bank',
    type: DebtType.bankLoan,
    principalAmount: 1000,
    interestRate: 1.5,
    termMonths: 12,
    startDate: DateTime(2024, 1, 4),
    payments: [
      PaymentModel(date: DateTime(2024, 2, 1), amount: 100),
    ],
  );
}

ReceivableModel _receivable() {
  return ReceivableModel(
    id: 'r1',
    userId: 'u1',
    walletId: 'w1',
    debtorName: 'Client',
    amount: 250,
    dueDate: DateTime(2024, 1, 5),
    createdAt: DateTime(2026, 1, 1),
  );
}

RecurringTransactionModel _recurring({String id = 'rec1'}) {
  return RecurringTransactionModel(
    id: id,
    userId: 'u1',
    walletId: 'w1',
    title: 'Rent',
    tag: 'Home',
    amount: 700,
    type: TransactionTypeModel.expense,
    frequency: RecurringFrequency.monthly,
    nextExecutionDate: DateTime(2024, 2, 1),
    anchorDay: 1,
  );
}
