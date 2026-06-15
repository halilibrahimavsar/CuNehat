import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/data/datasources/recurring_transaction_local_datasource.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionLocalDataSource extends Mock
    implements RecurringTransactionLocalDataSource {}

void main() {
  late MockRecurringTransactionLocalDataSource mockLocalDataSource;
  late RecurringTransactionRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      RecurringTransactionModel(
        id: 'rec_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Rent',
        tag: 'housing',
        amount: 1500.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: DateTime(2026, 6, 1),
      ),
    );
  });

  setUp(() {
    mockLocalDataSource = MockRecurringTransactionLocalDataSource();
    repository = RecurringTransactionRepositoryImpl(mockLocalDataSource);
  });

  group('RecurringTransactionRepositoryImpl', () {
    final nextDate = DateTime(2026, 6, 15);
    final entity = RecurringTransactionEntity(
      id: 'rec_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Rent',
      tag: 'housing',
      amount: 1500.0,
      type: TransactionTypeModel.expense,
      frequency: RecurringFrequency.monthly,
      nextExecutionDate: nextDate,
      isActive: true,
    );

    final model = RecurringTransactionModel.fromEntity(entity);

    group('saveTemplate', () {
      test('should return Right(null) when call is successful', () async {
        when(() => mockLocalDataSource.saveTemplate(any()))
            .thenAnswer((_) async => {});

        final result = await repository.saveTemplate(entity);

        expect(result, const Right(null));
        verify(() => mockLocalDataSource.saveTemplate(model)).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.saveTemplate(any()))
            .thenThrow(Exception('Hive error'));

        final result = await repository.saveTemplate(entity);

        expect(result,
            const Left(CacheFailure('Düzenli işlem şablonu kaydedilemedi.')));
      });
    });

    group('deleteTemplate', () {
      test('should return Right(null) when call is successful', () async {
        when(() => mockLocalDataSource.deleteTemplate(any()))
            .thenAnswer((_) async => {});

        final result = await repository.deleteTemplate('rec_1');

        expect(result, const Right(null));
        verify(() => mockLocalDataSource.deleteTemplate('rec_1')).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.deleteTemplate(any()))
            .thenThrow(Exception('Hive error'));

        final result = await repository.deleteTemplate('rec_1');

        expect(result,
            const Left(CacheFailure('Düzenli işlem şablonu silinemedi.')));
      });
    });

    group('getAllTemplates', () {
      test(
          'should return Right(List<RecurringTransactionEntity>) when call is successful',
          () async {
        when(() => mockLocalDataSource.getAllTemplates())
            .thenAnswer((_) async => [model]);

        final result = await repository.getAllTemplates();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should not return failure'),
          (entities) => expect(entities, [entity]),
        );
        verify(() => mockLocalDataSource.getAllTemplates()).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.getAllTemplates())
            .thenThrow(Exception('Hive error'));

        final result = await repository.getAllTemplates();

        expect(result,
            const Left(CacheFailure('Düzenli işlem şablonları getirilemedi.')));
      });
    });

    group('getPendingTransactions', () {
      test(
          'should return Right(List<RecurringTransactionEntity>) when call is successful',
          () async {
        when(() => mockLocalDataSource.getPendingTransactions())
            .thenAnswer((_) async => [model]);

        final result = await repository.getPendingTransactions();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should not return failure'),
          (entities) => expect(entities, [entity]),
        );
        verify(() => mockLocalDataSource.getPendingTransactions()).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.getPendingTransactions())
            .thenThrow(Exception('Hive error'));

        final result = await repository.getPendingTransactions();

        expect(
            result,
            const Left(
                CacheFailure('Bekleyen düzenli işlemler getirilemedi.')));
      });
    });
  });
}
