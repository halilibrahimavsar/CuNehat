import 'package:cunehat/features/debt_and_receivable/data/models/debt_calc_mode_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'dart:convert';
import 'dart:io';

import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/features/budgets/data/datasources/local/temp_budget_local_datasource.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/budgets/data/models/temp_budget_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_type_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/investments/data/datasource/goal_local_datasource.dart';
import 'package:cunehat/features/investments/data/models/goal_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/models/investment_type_adapter.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/color_adapter.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/wallet/data/models/credit_card_info_model.dart';
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

class FakeTempBudgetModel extends Fake implements TempBudgetModel {}

class FakeCategoryModel extends Fake implements CategoryModel {}

class FakeGoalModel extends Fake implements GoalModel {}

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
    registerFallbackValue(FakeTempBudgetModel());
    registerFallbackValue(FakeRecurringTransactionModel());
    registerFallbackValue(FakeCategoryModel());
    registerFallbackValue(FakeGoalModel());

    tempDir = await Directory.systemTemp.createTemp('cunehat_backup_test_');
    Hive.init(tempDir.path);

    void register<T>(TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }
    }

    register(WalletModelAdapter());
    // Cüzdan alan 15'in (kredi kartı) iç içe kayıtları.
    register(CreditCardInfoModelAdapter());
    register(CardStatementModelAdapter());
    register(TransactionModelAdapter());
    register(TransactionTypeModelAdapter());
    register(InvestmentModelAdapter());
    register(InvestmentTypeAdapter());
    register(DebtModelAdapter());
    register(ReceivableModelAdapter());
    register(PaymentModelAdapter());
    register(DebtTypeAdapter());
    register(DebtCalcModeAdapter());
    register(BudgetModelAdapter());
    register(TempBudgetModelAdapter());
    register(RecurringTransactionModelAdapter());
    register(RecurringFrequencyAdapter());
    register(CategoryModelAdapter());
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
    await Hive.box<CategoryModel>(CategoryLocalDataSource.boxName)
        .put('c1', _category());
    await Hive.box<CategoryModel>(CategoryLocalDataSource.boxName)
        .put('c2', _category(id: 'c2', parentId: 'c1'));

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
    // Kategoriler artık ham prefs string'i değil, gerçek bir liste.
    final categories = data['categories'] as List;
    expect(categories, hasLength(2));
    expect((categories[1] as Map)['parentId'], 'c1');
  });

  test('clearAllLocalData tüm kutuları (kategoriler dahil) temizler', () async {
    await Hive.box<CategoryModel>(CategoryLocalDataSource.boxName)
        .put('c1', _category());

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
    expect(
      Hive.box<CategoryModel>(CategoryLocalDataSource.boxName).values,
      isEmpty,
    );
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

  group('geri yüklemede bakiye defterden YENİDEN TÜRETİLİR', () {
    // Yedekteki `balance`/`openingBalance` çifti normalde tutarlıdır, ama bu
    // varsayım KAYNAĞIN sağlığına bağlı: başarısız bir `syncBalance` ya da
    // yarıda kalmış bir yazım, yedeğe tutarsız bir üçlü kopyalayabilir.
    // Geri yükleme, defterin tamamının elde olduğu tek andır.
    //
    // Ayrıca `WalletBloc` yalnız AKTİF cüzdanı senkronlar ve
    // `WatchWalletsEvent` bilerek hiç senkronlamaz; tutarsız dönen PASİF bir
    // cüzdan aktif yapılana kadar yanlış kalırdı.
    String inconsistentBackup() => jsonEncode({
          'version': DataSerializationService.schemaVersion,
          'timestamp': '2026-09-01T10:00:00.000',
          // balance 100, opening 100 — ama defterde +1000 gelir var.
          'wallets': [_wallet().toJson()],
          'transactions': [_transaction().toJson()],
          'investments': [],
          'debts': [],
          'receivables': [],
          'budgets': [],
          'recurringTransactions': [],
          'users': {
            'u1': {'activeWalletId': 'w1'}
          },
          'categories': [_category().toJson()],
        });

    test('tutarsız bakiye onarılır (opening + Σişlem)', () async {
      final result = await service.importDataFromJson(inconsistentBackup());

      expect(result.status, DataRestoreStatus.success);
      final wallet = Hive.box<WalletModel>('wallets').get('w1')!;
      expect(wallet.balance, 1100, reason: '100 + 1000 = 1100');
      // Açılış bakiyesi DEĞİŞMEZ: değişmezin çapası odur.
      expect(wallet.openingBalance, 100);
    });

    test('tutarlı bakiyeye dokunulmaz', () async {
      final consistent = jsonEncode({
        'version': DataSerializationService.schemaVersion,
        'timestamp': '2026-09-01T10:00:00.000',
        'wallets': [_wallet().toJson()],
        'transactions': [],
        'investments': [],
        'debts': [],
        'receivables': [],
        'budgets': [],
        'recurringTransactions': [],
        'users': {},
        'categories': [_category().toJson()],
      });

      await service.importDataFromJson(consistent);

      final wallet = Hive.box<WalletModel>('wallets').get('w1')!;
      expect(wallet.balance, 100);
    });
  });

  group('eski sürüm yedeği (v9) migrasyonla geri yüklenir', () {
    /// Sahadaki gerçek biçim: v9 cüzdanlarında `categoryIds` alanı YOKTUR.
    ///
    /// Kapalı testteki 13 kullanıcının Drive'ında duran yedekler bunlar.
    /// Sürüm kapısı sıkı eşitlikken bu dosya `versionMismatch` ile
    /// reddediliyordu; zincir eklenmeden `schemaVersion`'ı artırmak onları
    /// geri yüklenemez hale getirirdi.
    String v9Backup() {
      final wallet = _wallet().toJson()
        ..remove('categoryIds')
        // v12 alanı v9 yedeğinde de YOKTUR.
        ..remove('creditCard');
      // v11 alanları v9 yedeğinde de YOKTUR.
      final tx = _transaction().toJson()
        ..remove('linkedRecordId')
        ..remove('adoptedFromTag')
        ..remove('origin');
      return jsonEncode({
        'version': 9,
        'timestamp': '2026-09-01T10:00:00.000',
        'wallets': [wallet],
        'transactions': [tx],
        'investments': [],
        'debts': [],
        'receivables': [],
        'budgets': [],
        'recurringTransactions': [],
        'users': {
          'u1': {'activeWalletId': 'w1'}
        },
        'categories': [_category().toJson()],
      });
    }

    test('geri yükleme BAŞARILI olur', () async {
      final result = await service.importDataFromJson(v9Backup());

      expect(result.status, DataRestoreStatus.success);
      expect(Hive.box<WalletModel>('wallets').get('w1')?.name, 'Main');
      expect(Hive.box<TransactionModel>('transactions').values, hasLength(1));
    });

    test('cüzdan KÜRASYONSUZ döner: tüm kategoriler görünür kalır', () async {
      await service.importDataFromJson(v9Backup());

      expect(
        Hive.box<WalletModel>('wallets').get('w1')?.categoryIds,
        isNull,
        reason: 'null = kürasyon yok; başka bir değer kategorileri gizlerdi',
      );
    });

    test('önizleme de v9 dosyasını okunabilir sayar', () async {
      final inspection = service.inspectBackup(v9Backup());

      expect(inspection.status, BackupInspectionStatus.ok);
      expect(inspection.summary?.walletCount, 1);
    });
  });

  group('eski sürüm yedeği (v10) migrasyonla geri yüklenir', () {
    /// Sahadaki gerçek biçim: v10 işlemlerinde kuplaj bağı, benimseme izi ve
    /// köken alanları YOKTUR. 23 Eyl 2026 itibarıyla testerların yedekleri
    /// bu sürümde.
    String v10Backup() {
      final tx = _transaction().toJson()
        ..remove('linkedRecordId')
        ..remove('adoptedFromTag')
        ..remove('origin');
      return jsonEncode({
        'version': 10,
        'timestamp': '2026-09-20T10:00:00.000',
        'wallets': [_wallet().toJson()..remove('creditCard')],
        'transactions': [tx],
        'investments': [],
        'debts': [],
        'receivables': [],
        'budgets': [],
        'recurringTransactions': [],
        'users': {
          'u1': {'activeWalletId': 'w1'}
        },
        'categories': [_category().toJson()],
      });
    }

    test('geri yükleme BAŞARILI; işlemin yeni alanları "bilinmiyor" (null)',
        () async {
      final result = await service.importDataFromJson(v10Backup());

      expect(result.status, DataRestoreStatus.success);
      final txs = Hive.box<TransactionModel>('transactions').values.toList();
      expect(txs, hasLength(1));
      expect(txs.single.linkedRecordId, isNull);
      expect(txs.single.adoptedFromTag, isNull);
      expect(txs.single.origin, isNull);
    });

    test('önizleme de v10 dosyasını okunabilir sayar', () async {
      final inspection = service.inspectBackup(v10Backup());
      expect(inspection.status, BackupInspectionStatus.ok);
      expect(inspection.summary?.transactionCount, 1);
    });
  });

  group('eski sürüm yedeği (v11) migrasyonla geri yüklenir', () {
    /// Sahadaki gerçek biçim: v11 cüzdanlarında `creditCard` alanı YOKTUR.
    String v11Backup() => jsonEncode({
          'version': 11,
          'timestamp': '2026-09-23T10:00:00.000',
          'wallets': [_wallet().toJson()..remove('creditCard')],
          'transactions': [_transaction().toJson()],
          'investments': [],
          'debts': [],
          'receivables': [],
          'budgets': [],
          'recurringTransactions': [],
          'users': {
            'u1': {'activeWalletId': 'w1'}
          },
          'categories': [_category().toJson()],
        });

    test('geri yükleme BAŞARILI; cüzdan DÜZ cüzdan döner', () async {
      final result = await service.importDataFromJson(v11Backup());

      expect(result.status, DataRestoreStatus.success);
      final wallet = Hive.box<WalletModel>('wallets').get('w1')!;
      expect(wallet.name, 'Main');
      expect(wallet.creditCard, isNull);
    });

    test('önizleme de v11 dosyasını okunabilir sayar', () async {
      final inspection = service.inspectBackup(v11Backup());
      expect(inspection.status, BackupInspectionStatus.ok);
      expect(inspection.summary?.walletCount, 1);
    });
  });

  group('eski sürüm yedeği (v15) migrasyonla geri yüklenir', () {
    /// Sahadaki gerçek biçim (12 Eki 2026 öncesi): kartta `dueOffsetDays` /
    /// `monthlyInterestRate` / `lateInterestRate`, yatırımda `isPrimary`
    /// YOKTUR.
    String v15Backup() {
      final cardWallet = _wallet(id: 'card').copyWith(
        creditCard: const CreditCardInfoModel(
          bankName: 'QNB',
          last4: '4321',
          limit: 20000,
          closingDay: 25,
          dueDay: 5,
          paymentWalletId: 'w1',
        ),
      );
      final cardJson = cardWallet.toJson();
      (cardJson['creditCard'] as Map)
        ..remove('dueOffsetDays')
        ..remove('monthlyInterestRate')
        ..remove('lateInterestRate');
      final pot = InvestmentModel(
        id: 'pot',
        userId: 'u1',
        walletId: 'w1',
        name: 'Acil durum',
        amount: 1500,
        currentValue: 1500,
        type: InvestmentType.cash,
        color: const Color(0xFF26A69A),
        dateAdded: DateTime(2026, 9, 1),
      );
      return jsonEncode({
        'version': 15,
        'timestamp': '2026-10-10T10:00:00.000',
        'wallets': [_wallet().toJson(), cardJson],
        'transactions': [_transaction().toJson()],
        'investments': [
          _investment().toJson()..remove('isPrimary'),
          pot.toJson()..remove('isPrimary'),
        ],
        'debts': [],
        'receivables': [],
        'budgets': [],
        'recurringTransactions': [],
        'users': {
          'u1': {'activeWalletId': 'w1'}
        },
        'categories': [_category().toJson()],
        'goals': [],
      });
    }

    test('geri yükleme BAŞARILI; kart ayarlanmamış, hiçbir kasa ana değil',
        () async {
      final result = await service.importDataFromJson(v15Backup());

      expect(result.status, DataRestoreStatus.success);
      final card = Hive.box<WalletModel>('wallets').get('card')!.creditCard!;
      expect(card.bankName, 'QNB');
      expect(card.closingDay, 25);
      expect(card.dueDay, 5);
      expect(card.dueOffsetDays, isNull);
      expect(card.monthlyInterestRate, isNull);
      expect(card.lateInterestRate, isNull);

      final investments =
          Hive.box<InvestmentModel>('investments_box').values.toList();
      expect(investments, hasLength(2));
      expect(investments.every((i) => !i.isPrimary), isTrue);
      expect(investments.firstWhere((i) => i.id == 'pot').amount, 1500);
    });

    test('önizleme de v15 dosyasını okunabilir sayar', () async {
      final inspection = service.inspectBackup(v15Backup());
      expect(inspection.status, BackupInspectionStatus.ok);
      expect(inspection.summary?.walletCount, 2);
      expect(inspection.summary?.investmentCount, 2);
    });
  });

  test('şema 16 alanları export/import round-trip ile korunur', () async {
    const card = CreditCardInfoModel(
      closingDay: 25,
      dueDay: 5,
      dueOffsetDays: 10,
      monthlyInterestRate: 4.25,
      lateInterestRate: 4.55,
    );
    await Hive.box<WalletModel>('wallets')
        .put('w1', _wallet().copyWith(creditCard: card));
    await Hive.box<InvestmentModel>('investments_box').put(
      'pot',
      InvestmentModel(
        id: 'pot',
        userId: 'u1',
        walletId: 'w1',
        name: 'Ana kasa',
        amount: 900,
        currentValue: 900,
        type: InvestmentType.cash,
        color: const Color(0xFF26A69A),
        dateAdded: DateTime(2026, 9, 1),
        isPrimary: true,
      ),
    );

    final jsonString = await service.exportDataToJson();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    expect(data['version'], DataSerializationService.schemaVersion);
    await service.clearAllLocalData();
    final result = await service.importDataFromJson(jsonString);

    expect(result.isSuccess, true);
    final back = Hive.box<WalletModel>('wallets').get('w1')!.creditCard!;
    expect(back.dueOffsetDays, 10);
    expect(back.monthlyInterestRate, 4.25);
    expect(back.lateInterestRate, 4.55);
    expect(Hive.box<InvestmentModel>('investments_box').get('pot')!.isPrimary,
        isTrue);
  });

  test('şema 17: tek seferlik bütçeler export/import round-trip ile korunur',
      () async {
    await Hive.box<TempBudgetModel>(TempBudgetLocalDataSource.boxName)
        .put('tb1', _tempBudget());

    final jsonString = await service.exportDataToJson();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    expect(data['version'], 17);
    expect(data['tempBudgets'], hasLength(1));

    await service.clearAllLocalData();
    expect(
        Hive.box<TempBudgetModel>(TempBudgetLocalDataSource.boxName).length, 0);
    final result = await service.importDataFromJson(jsonString);

    expect(result.isSuccess, true);
    final back = Hive.box<TempBudgetModel>(TempBudgetLocalDataSource.boxName)
        .get('tb1')!;
    expect(back.name, 'Tatil');
    expect(back.walletId, 'w1');
    expect(back.limitAmount, 15000);
    expect(back.startDate, DateTime(2026, 11, 10));
    expect(back.endDate, DateTime(2026, 11, 20));
    expect(back.categoryIds, ['c1', 'c2']);
    // Özet tek "bütçe" sayısı gösterir: aylık + tek seferlik.
    expect(service.inspectBackup(jsonString).summary?.budgetCount, 1);
  });

  group('eski sürüm yedeği (v16) migrasyonla geri yüklenir', () {
    /// Sahadaki gerçek biçim (17 Eki 2026 öncesi): `tempBudgets` dizisi YOK.
    String v16Backup() => jsonEncode({
          'version': 16,
          'timestamp': '2026-10-16T10:00:00.000',
          'wallets': [_wallet().toJson()],
          'transactions': [_transaction().toJson()],
          'investments': [],
          'debts': [],
          'receivables': [],
          'budgets': [
            BudgetModel(categoryId: 'c1', limitAmount: 2000, walletId: 'w1')
                .toJson(),
          ],
          'recurringTransactions': [],
          'users': {
            'u1': {'activeWalletId': 'w1'}
          },
          'categories': [_category().toJson()],
          'goals': [],
        });

    test('geri yükleme BAŞARILI; aylık bütçe yerinde, geçici bütçe yok',
        () async {
      // Cihazda önceden kalan geçici bütçe: tam değişim onu da temizlemeli.
      await Hive.box<TempBudgetModel>(TempBudgetLocalDataSource.boxName)
          .put('stale', _tempBudget(id: 'stale'));

      final result = await service.importDataFromJson(v16Backup());

      expect(result.isSuccess, true);
      expect(Hive.box<BudgetModel>('budgets_box').get('w1::c1')!.limitAmount,
          2000);
      expect(
          Hive.box<TempBudgetModel>(TempBudgetLocalDataSource.boxName).isEmpty,
          isTrue);
    });

    test('önizleme de v16 dosyasını okunabilir sayar', () {
      final inspection = service.inspectBackup(v16Backup());
      expect(inspection.status, BackupInspectionStatus.ok);
      expect(inspection.summary?.budgetCount, 1);
    });
  });

  test('kart cüzdanı export/import round-trip ile kart bilgisini korur',
      () async {
    final card = CreditCardInfoModel(
      bankName: 'Garanti BBVA',
      last4: '5690',
      limit: 50000,
      closingDay: 15,
      dueDay: 25,
      paymentWalletId: 'w-bank',
      lastStatement: CardStatementModel(
        closingDate: DateTime(2026, 9, 15),
        dueDate: DateTime(2026, 9, 25),
        statementBalance: 12345.67,
        minimumPayment: 4938.27,
        source: 'manual',
        recordedAt: DateTime(2026, 9, 16, 10, 30),
      ),
    );
    await Hive.box<WalletModel>('wallets')
        .put('w1', _wallet().copyWith(creditCard: card));

    final jsonString = await service.exportDataToJson();
    await service.clearAllLocalData();
    final result = await service.importDataFromJson(jsonString);

    expect(result.isSuccess, true);
    final back = Hive.box<WalletModel>('wallets').get('w1')!.toEntity();
    expect(back.creditCard, card.toEntity());
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

  test('yazım başarısızsa kutular (kategoriler dahil) geri sarılır', () async {
    final mockHive = MockHiveInterface();
    final walletBox = MockBox<WalletModel>();
    final transactionBox = MockBox<TransactionModel>();
    final investmentBox = MockBox<InvestmentModel>();
    final debtBox = MockBox<DebtModel>();
    final receivableBox = MockBox<ReceivableModel>();
    final budgetBox = MockBox<BudgetModel>();
    final tempBudgetBox = MockBox<TempBudgetModel>();
    final recurringBox = MockBox<RecurringTransactionModel>();
    final userBox = MockBox<Map>();
    final categoryBox = MockBox<CategoryModel>();
    final goalBox = MockBox<GoalModel>();

    _stubBox(walletBox, {'old-wallet': _wallet(id: 'old-wallet')});
    _stubBox<TransactionModel>(transactionBox, {});
    _stubBox<InvestmentModel>(investmentBox, {});
    _stubBox<DebtModel>(debtBox, {});
    _stubBox<ReceivableModel>(receivableBox, {});
    _stubBox<BudgetModel>(budgetBox, {});
    _stubBox<TempBudgetModel>(tempBudgetBox, {'old-temp': _tempBudget()});
    _stubBox<RecurringTransactionModel>(recurringBox, {});
    _stubBox<Map>(userBox, {});
    _stubBox<CategoryModel>(categoryBox, {'old-cat': _category(id: 'old-cat')});
    _stubBox<GoalModel>(goalBox, {});

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
    when(() => mockHive
            .openBox<TempBudgetModel>(TempBudgetLocalDataSource.boxName))
        .thenAnswer((_) async => tempBudgetBox);
    when(() => mockHive.openBox<RecurringTransactionModel>(
        'recurring_transactions_box')).thenAnswer((_) async => recurringBox);
    when(() => mockHive.openBox<Map>('users')).thenAnswer((_) async => userBox);
    when(() => mockHive.openBox<CategoryModel>(CategoryLocalDataSource.boxName))
        .thenAnswer((_) async => categoryBox);
    when(() => mockHive.openBox<GoalModel>(GoalLocalDataSource.boxName))
        .thenAnswer((_) async => goalBox);

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
      'categories': [_category(id: 'new-cat').toJson()],
    });

    final result = await failingService.importDataFromJson(backup);

    expect(result.status, DataRestoreStatus.writeFailure);
    verify(() => walletBox.putAll(any())).called(1);
    verify(() => transactionBox.putAll(any())).called(1);
    verify(() => budgetBox.putAll(any())).called(1);
    verify(() => recurringBox.putAll(any())).called(1);
    // Kategori kutusu da geri sarılır: yazım yarıda kalırsa kullanıcı hem
    // eski hem yeni kategorilerden yoksun kalırdı.
    verify(() => categoryBox.putAll(any())).called(greaterThanOrEqualTo(1));
    // Tek seferlik bütçeler de: yarıda kalan geri yükleme onları silmemeli.
    verify(() => tempBudgetBox.putAll(any())).called(greaterThanOrEqualTo(1));
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

CategoryModel _category({String id = 'c1', String? parentId}) => CategoryModel(
      id: id,
      name: 'Fatura',
      iconName: 'receipt_long',
      isExpense: true,
      parentId: parentId,
      sortOrder: 1,
    );

Future<void> _openAllBoxes() async {
  await Hive.openBox<WalletModel>('wallets');
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<InvestmentModel>('investments_box');
  await Hive.openBox<DebtModel>('debts');
  await Hive.openBox<ReceivableModel>('receivables');
  await Hive.openBox<BudgetModel>('budgets_box');
  await Hive.openBox<TempBudgetModel>(TempBudgetLocalDataSource.boxName);
  await Hive.openBox<RecurringTransactionModel>('recurring_transactions_box');
  await Hive.openBox<Map>('users');
  await Hive.openBox<CategoryModel>(CategoryLocalDataSource.boxName);
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
  if (Hive.isBoxOpen(CategoryLocalDataSource.boxName)) {
    await Hive.box<CategoryModel>(CategoryLocalDataSource.boxName).clear();
  }
  if (Hive.isBoxOpen('budgets_box')) {
    await Hive.box<BudgetModel>('budgets_box').clear();
  }
  if (Hive.isBoxOpen(TempBudgetLocalDataSource.boxName)) {
    await Hive.box<TempBudgetModel>(TempBudgetLocalDataSource.boxName).clear();
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
  );
}

DebtModel _debt() {
  return DebtModel(
    calcMode: DebtCalcMode.none,
    expectedTotalAmount: 1000,
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
      PaymentModel(id: 'p1', date: DateTime(2024, 2, 1), amount: 100),
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

TempBudgetModel _tempBudget({String id = 'tb1'}) => TempBudgetModel(
      id: id,
      walletId: 'w1',
      name: 'Tatil',
      limitAmount: 15000,
      startDate: DateTime(2026, 11, 10),
      endDate: DateTime(2026, 11, 20),
      categoryIds: const ['c1', 'c2'],
    );
