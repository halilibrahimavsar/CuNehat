import 'dart:convert';
import 'dart:io';

import 'package:cunehat/core/services/data_serialization_service.dart';
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
    service = DataSerializationService(
        ReceiptStorageService.withBaseDir(tempDir));
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
        mockHive, ReceiptStorageService.withBaseDir(tempDir));
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
  );
}
