import 'dart:io';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockHiveInterface extends Mock implements HiveInterface {}

class MockBox extends Mock implements Box<TransactionModel> {}

void main() {
  late TransactionHiveDataSource dataSource;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_transactions');
    Hive.init(tempDir.path);
    Hive.registerAdapter(TransactionTypeModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
  });

  setUp(() {
    dataSource = TransactionHiveDataSource(Hive);
  });

  tearDown(() async {
    if (Hive.isBoxOpen('transactions')) {
      final box = Hive.box<TransactionModel>('transactions');
      await box.clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TransactionHiveDataSource', () {
    final t1 = TransactionModel(
      id: 'tx_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Lunch',
      tag: 'Food',
      amount: 150.0,
      date: DateTime(2026, 6, 15, 12, 30),
      type: TransactionTypeModel.expense,
    );

    final t2 = TransactionModel(
      id: 'tx_2',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Salary',
      tag: 'Job',
      amount: 5000.0,
      date: DateTime(2026, 6, 16, 9, 0),
      type: TransactionTypeModel.income,
    );

    final t3 = TransactionModel(
      id: 'tx_3',
      userId: 'user_2',
      walletId: 'wallet_1',
      title: 'Coffee',
      tag: 'Food',
      amount: 50.0,
      date: DateTime(2026, 6, 15, 14, 0),
      type: TransactionTypeModel.expense,
    );

    test('should add and get transactions successfully with correct sorting',
        () async {
      await dataSource.addTransaction(t1);
      await dataSource.addTransaction(t2);

      final results = await dataSource.getTransactions(
          userId: 'user_1', walletId: 'wallet_1');

      expect(results.length, 2);
      // Sorted desc: t2 (June 16) should be first, then t1 (June 15)
      expect(results[0].id, 'tx_2');
      expect(results[1].id, 'tx_1');
    });

    test('should filter by type correctly', () async {
      await dataSource.addTransaction(t1);
      await dataSource.addTransaction(t2);

      final expenses = await dataSource.getTransactions(
        userId: 'user_1',
        walletId: 'wallet_1',
        type: TransactionTypeModel.expense,
      );

      expect(expenses.length, 1);
      expect(expenses.first.id, 'tx_1');
    });

    test('should filter by date range correctly', () async {
      await dataSource.addTransaction(t1); // June 15
      await dataSource.addTransaction(t2); // June 16

      final results = await dataSource.getTransactions(
        userId: 'user_1',
        walletId: 'wallet_1',
        startDate: DateTime(2026, 6, 16),
        endDate: DateTime(2026, 6, 17),
      );

      expect(results.length, 1);
      expect(results.first.id, 'tx_2');
    });

    test(
        'addTransaction throws ValidationException on missing id or empty userId',
        () async {
      final invalidTx1 = TransactionModel(
        id: null,
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Title',
        tag: 'Tag',
        amount: 10.0,
        date: DateTime.now(),
        type: TransactionTypeModel.expense,
      );

      final invalidTx2 = TransactionModel(
        id: 'tx_invalid',
        userId: '',
        walletId: 'wallet_1',
        title: 'Title',
        tag: 'Tag',
        amount: 10.0,
        date: DateTime.now(),
        type: TransactionTypeModel.expense,
      );

      expect(() => dataSource.addTransaction(invalidTx1),
          throwsA(isA<CacheException>()));
      expect(() => dataSource.addTransaction(invalidTx2),
          throwsA(isA<CacheException>()));
    });

    test(
        'getTransactionById returns correct transaction or throws NotFoundException',
        () async {
      await dataSource.addTransaction(t1);

      final result = await dataSource.getTransactionById('tx_1');
      expect(result.title, 'Lunch');

      expect(() => dataSource.getTransactionById('tx_non_existent'),
          throwsA(isA<NotFoundException>()));
    });

    test('updateTransaction updates successfully or throws NotFoundException',
        () async {
      await dataSource.addTransaction(t1);
      final updated = t1.copyWith(title: 'Updated Lunch');
      await dataSource.updateTransaction(updated);

      final result = await dataSource.getTransactionById('tx_1');
      expect(result.title, 'Updated Lunch');

      final nonExistent = t2.copyWith(id: 'tx_non_existent');
      expect(() => dataSource.updateTransaction(nonExistent),
          throwsA(isA<NotFoundException>()));
    });

    test('deleteTransaction deletes successfully or throws NotFoundException',
        () async {
      await dataSource.addTransaction(t1);
      await dataSource.deleteTransaction('tx_1');

      expect(() => dataSource.getTransactionById('tx_1'),
          throwsA(isA<NotFoundException>()));
      expect(() => dataSource.deleteTransaction('tx_non_existent'),
          throwsA(isA<NotFoundException>()));
    });

    test('getTransactionsGroupedByDate groups correctly', () async {
      await dataSource.addTransaction(t1); // June 15 12:30
      await dataSource.addTransaction(t3); // June 15 14:00 (user_2)
      // Since it filters by userId, if we group for user_1:
      final grouped = await dataSource.getTransactionsGroupedByDate(
          userId: 'user_1', walletId: 'wallet_1');

      final dateKey = DateTime(2026, 6, 15);
      expect(grouped.containsKey(dateKey), true);
      expect(grouped[dateKey]?.length, 1);
      expect(grouped[dateKey]?.first.id, 'tx_1');
    });

    test('should sort by ID when transaction dates are identical', () async {
      final tSameDate1 = TransactionModel(
        id: 'tx_same_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'A',
        tag: 'Food',
        amount: 10.0,
        date: DateTime(2026, 6, 15, 12, 30),
        type: TransactionTypeModel.expense,
      );
      final tSameDate2 = TransactionModel(
        id: 'tx_same_2',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'B',
        tag: 'Food',
        amount: 20.0,
        date: DateTime(2026, 6, 15, 12, 30),
        type: TransactionTypeModel.expense,
      );

      await dataSource.addTransaction(tSameDate1);
      await dataSource.addTransaction(tSameDate2);

      final results = await dataSource.getTransactions(
          userId: 'user_1', walletId: 'wallet_1');

      // Should find tx_same_2 first, then tx_same_1 (because of alphabetical descending ID sort)
      final sameDateResults =
          results.where((r) => r.id!.startsWith('tx_same_')).toList();
      expect(sameDateResults[0].id, 'tx_same_2');
      expect(sameDateResults[1].id, 'tx_same_1');
    });

    test('should return box directly if already open', () async {
      final mockHive = MockHiveInterface();
      final mockBox = MockBox();
      dataSource = TransactionHiveDataSource(mockHive);

      when(() => mockHive.isBoxOpen('transactions')).thenReturn(true);
      when(() => mockHive.box<TransactionModel>('transactions'))
          .thenReturn(mockBox);
      when(() => mockBox.values).thenReturn([]);

      final result = await dataSource.getTransactions(
          userId: 'user_1', walletId: 'wallet_1');
      expect(result, isEmpty);
    });

    group('CacheException Triggers', () {
      late MockHiveInterface mockHive;

      setUp(() {
        mockHive = MockHiveInterface();
        dataSource = TransactionHiveDataSource(mockHive);

        when(() => mockHive.isBoxOpen(any())).thenReturn(false);
        when(() => mockHive.openBox<TransactionModel>(any()))
            .thenThrow(HiveError('Mock Hive Error'));
      });

      test('should throw CacheException on getTransactions when Hive throws',
          () async {
        expect(
          () => dataSource.getTransactions(
              userId: 'user_1', walletId: 'wallet_1'),
          throwsA(isA<CacheException>()),
        );
      });

      test('should throw CacheException on getTransactionById when Hive throws',
          () async {
        expect(
          () => dataSource.getTransactionById('tx_1'),
          throwsA(isA<CacheException>()),
        );
      });

      test('should throw CacheException on updateTransaction when Hive throws',
          () async {
        expect(
          () => dataSource.updateTransaction(t1),
          throwsA(isA<CacheException>()),
        );
      });

      test('should throw CacheException on deleteTransaction when Hive throws',
          () async {
        expect(
          () => dataSource.deleteTransaction('tx_1'),
          throwsA(isA<CacheException>()),
        );
      });

      test(
          'should throw CacheException on getTransactionsGroupedByDate when Hive throws',
          () async {
        expect(
          () => dataSource.getTransactionsGroupedByDate(
              userId: 'user_1', walletId: 'wallet_1'),
          throwsA(isA<CacheException>()),
        );
      });
    });

    group('addTransactions (toplu yazım)', () {
      // Borç silme gibi mutabakat akışları ödeme başına bir ters kayıt üretir;
      // tek tek addTransaction her kayıt için ayrı await turu + disk flush
      // demekti (36 taksitli borçta 37 tur, silme diyaloğu bloklu).

      test('hepsini tek çağrıda yazar', () async {
        await dataSource.addTransactions([t1, t2]);

        final all = await dataSource.getTransactions(
          userId: t1.userId,
          walletId: t1.walletId,
        );
        expect(all.map((t) => t.id), containsAll([t1.id, t2.id]));
      });

      test('boş liste no-op', () async {
        await dataSource.addTransactions([]);

        final all = await dataSource.getTransactions(
          userId: t1.userId,
          walletId: t1.walletId,
        );
        expect(all, isEmpty);
      });

      test('id boşsa HİÇBİRİ yazılmaz', () async {
        // `copyWith(id: null)` işe yaramaz (`id ?? this.id`); geçersiz kayıt
        // doğrudan kurulur.
        final invalid = TransactionModel(
          id: null,
          userId: 'user_1',
          walletId: 'wallet_1',
          title: 'Broken',
          tag: 'Food',
          amount: 10.0,
          date: DateTime(2026, 6, 17),
          type: TransactionTypeModel.expense,
        );

        expect(
          () => dataSource.addTransactions([t1, invalid]),
          throwsA(isA<CacheException>()),
        );

        final all = await dataSource.getTransactions(
          userId: t1.userId,
          walletId: t1.walletId,
        );
        expect(all, isEmpty, reason: 'ya hepsi ya hiçbiri');
      });
    });
  });
}
