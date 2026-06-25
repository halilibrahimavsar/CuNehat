import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/data/datasources/local/budget_local_datasource.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetLocalDataSource extends Mock implements BudgetLocalDataSource {}

void main() {
  late BudgetRepositoryImpl repository;
  late MockBudgetLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue(
        BudgetModel(categoryId: 'fallback', limitAmount: 0.0));
  });

  setUp(() {
    mockLocalDataSource = MockBudgetLocalDataSource();
    repository = BudgetRepositoryImpl(mockLocalDataSource);
  });

  final testModel = BudgetModel(categoryId: 'Food', limitAmount: 1000.0);
  final testEntity =
      const BudgetEntity(categoryId: 'Food', limitAmount: 1000.0);

  group('getBudgets', () {
    test(
        'should return Right(List<BudgetEntity>) when local call is successful',
        () async {
      when(() => mockLocalDataSource.getBudgets())
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getBudgets();

      expect(result.isRight(), true);
      expect(
          (result as Right<Failure, List<BudgetEntity>>).value, [testEntity]);
      verify(() => mockLocalDataSource.getBudgets()).called(1);
    });

    test('should return Left(CacheFailure) when local call fails', () async {
      when(() => mockLocalDataSource.getBudgets())
          .thenThrow(Exception('DB Error'));

      final result = await repository.getBudgets();

      expect(
          result,
          const Left<Failure, List<BudgetEntity>>(
              CacheFailure('Bütçeler yüklenemedi.')));
      verify(() => mockLocalDataSource.getBudgets()).called(1);
    });
  });

  group('saveBudget', () {
    test('should return Right(null) when save is successful', () async {
      when(() => mockLocalDataSource.saveBudget(any()))
          .thenAnswer((_) async => {});

      final result = await repository.saveBudget(testEntity);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDataSource.saveBudget(any())).called(1);
    });

    test('should return Left(CacheFailure) when save fails', () async {
      when(() => mockLocalDataSource.saveBudget(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.saveBudget(testEntity);

      expect(result,
          const Left<Failure, void>(CacheFailure('Bütçe kaydedilemedi.')));
      verify(() => mockLocalDataSource.saveBudget(any())).called(1);
    });
  });

  group('deleteBudget', () {
    test('should return Right(null) when delete is successful', () async {
      when(() => mockLocalDataSource.deleteBudget('Food'))
          .thenAnswer((_) async => {});

      final result = await repository.deleteBudget('Food');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDataSource.deleteBudget('Food')).called(1);
    });

    test('should return Left(CacheFailure) when delete fails', () async {
      when(() => mockLocalDataSource.deleteBudget('Food'))
          .thenThrow(Exception('DB Error'));

      final result = await repository.deleteBudget('Food');

      expect(
          result, const Left<Failure, void>(CacheFailure('Bütçe silinemedi.')));
      verify(() => mockLocalDataSource.deleteBudget('Food')).called(1);
    });
  });
}
