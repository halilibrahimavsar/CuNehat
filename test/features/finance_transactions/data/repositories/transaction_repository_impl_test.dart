import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/data/repositories/transaction_repository_impl.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionHiveDataSource extends Mock
    implements TransactionHiveDataSource {}

class MockReceiptStorageService extends Mock implements ReceiptStorageService {}

void main() {
  late TransactionRepositoryImpl repository;
  late MockTransactionHiveDataSource mockLocalDatasource;
  late MockReceiptStorageService mockReceiptStorage;

  setUpAll(() {
    registerFallbackValue(
      TransactionModel(
        id: 'fallback',
        userId: 'user',
        walletId: 'wallet',
        title: 'fallback',
        tag: 'fallback',
        amount: 0.0,
        date: DateTime(2026, 1, 1),
        type: TransactionTypeModel.expense,
      ),
    );
  });

  setUp(() {
    mockLocalDatasource = MockTransactionHiveDataSource();
    mockReceiptStorage = MockReceiptStorageService();
    // Fiş temizliği varsayılan olarak no-op; ilgili testler ayrıca stub'lar.
    when(() => mockReceiptStorage.delete(any())).thenAnswer((_) async {});
    repository = TransactionRepositoryImpl(
      localDatasource: mockLocalDatasource,
      receiptStorage: mockReceiptStorage,
    );
  });

  final date = DateTime(2026, 6, 15);
  final testEntity = TransactionEntity(
    id: 'tx_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    title: 'Lunch',
    tag: 'Food',
    amount: 150.0,
    date: date,
    type: TransactionTypeModel.expense,
  );

  final testModel = TransactionModel.fromEntity(testEntity);

  group('addTransaction', () {
    test('should return Right(id) when local datasource call is successful',
        () async {
      when(() => mockLocalDatasource.addTransaction(any()))
          .thenAnswer((_) async => 'tx_1');

      final result = await repository.addTransaction(testEntity);

      expect(result, const Right<Failure, String>('tx_1'));
      verify(() => mockLocalDatasource.addTransaction(any())).called(1);
    });

    test('should return Left(CacheFailure) when local datasource call fails',
        () async {
      when(() => mockLocalDatasource.addTransaction(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.addTransaction(testEntity);

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, String>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('İşlem eklenemedi'));
    });
  });

  group('updateTransaction', () {
    test('should return Right(null) when update is successful', () async {
      when(() => mockLocalDatasource.updateTransaction(any()))
          .thenAnswer((_) async => {});

      final result = await repository.updateTransaction(testEntity);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.updateTransaction(any())).called(1);
    });

    test('should return Left(CacheFailure) when update fails', () async {
      when(() => mockLocalDatasource.updateTransaction(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.updateTransaction(testEntity);

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('İşlem güncellenemedi'));
    });
  });

  group('deleteTransaction', () {
    test('should return Right(null) when delete is successful', () async {
      when(() => mockLocalDatasource.deleteTransaction(any()))
          .thenAnswer((_) async => {});

      final result = await repository.deleteTransaction('tx_1');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.deleteTransaction('tx_1')).called(1);
    });

    test('should return Left(CacheFailure) when delete fails', () async {
      when(() => mockLocalDatasource.deleteTransaction(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.deleteTransaction('tx_1');

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('İşlem silinemedi'));
    });
  });

  group('getTransactionById', () {
    test(
        'should return Right(TransactionEntity) when local datasource call is successful',
        () async {
      when(() => mockLocalDatasource.getTransactionById(any()))
          .thenAnswer((_) async => testModel);

      final result = await repository.getTransactionById('tx_1');

      expect(result, Right<Failure, TransactionEntity>(testEntity));
      verify(() => mockLocalDatasource.getTransactionById('tx_1')).called(1);
    });

    test('should return Left(CacheFailure) when local datasource call fails',
        () async {
      when(() => mockLocalDatasource.getTransactionById(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.getTransactionById('tx_1');

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, TransactionEntity>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('İşlem getirilemedi'));
    });
  });

  group('getTransactions', () {
    test('should return Right(List<TransactionEntity>) when call is successful',
        () async {
      when(() => mockLocalDatasource.getTransactions(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => [testModel]);

      final result = await repository.getTransactions(
          userId: 'user_1', walletId: 'wallet_1');

      expect(result.isRight(), true);
      expect((result as Right<Failure, List<TransactionEntity>>).value,
          [testEntity]);
    });

    test('should return Left(CacheFailure) when call fails', () async {
      when(() => mockLocalDatasource.getTransactions(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            type: any(named: 'type'),
          )).thenThrow(Exception('DB Error'));

      final result = await repository.getTransactions(
          userId: 'user_1', walletId: 'wallet_1');

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, List<TransactionEntity>>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('İşlemler getirilemedi'));
    });
  });

  group('getTransactionsGroupedByDate', () {
    test(
        'should return Right(Map<DateTime, List<TransactionEntity>>) when call is successful',
        () async {
      final groupedModels = {
        date: [testModel]
      };
      when(() => mockLocalDatasource.getTransactionsGroupedByDate(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => groupedModels);

      final result = await repository.getTransactionsGroupedByDate(
          userId: 'user_1', walletId: 'wallet_1');

      expect(result.isRight(), true);
      final mapValue =
          (result as Right<Failure, Map<DateTime, List<TransactionEntity>>>)
              .value;
      expect(mapValue.containsKey(date), true);
      expect(mapValue[date], [testEntity]);
    });

    test('should return Left(CacheFailure) when call fails', () async {
      when(() => mockLocalDatasource.getTransactionsGroupedByDate(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            type: any(named: 'type'),
          )).thenThrow(Exception('DB Error'));

      final result = await repository.getTransactionsGroupedByDate(
          userId: 'user_1', walletId: 'wallet_1');

      expect(result.isLeft(), true);
      final failure =
          (result as Left<Failure, Map<DateTime, List<TransactionEntity>>>)
              .value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('Gruplanmış işlemler getirilemedi'));
    });
  });
}
