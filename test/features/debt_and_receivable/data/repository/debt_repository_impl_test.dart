import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/debt_and_receivable/data/datasource/debt_local_datasource.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/repositories/debt_repository_impl.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtLocalDatasource extends Mock implements DebtLocalDatasource {}

void main() {
  late DebtRepositoryImpl repository;
  late MockDebtLocalDatasource mockLocalDatasource;

  setUpAll(() {
    registerFallbackValue(
      DebtModel(
        id: 'fallback',
        userId: 'user',
        walletId: 'wallet',
        title: 'fallback',
        counterparty: 'fallback',
        type: DebtType.otherDebt,
        principalAmount: 0.0,
        interestRate: 0.0,
        termMonths: 0,
        startDate: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockLocalDatasource = MockDebtLocalDatasource();
    repository =
        DebtRepositoryImpl(debtDatasourceRepository: mockLocalDatasource);
  });

  final startDate = DateTime(2026, 1, 1);
  final testEntity = DebtEntity(
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

  final testModel = DebtModel.fromEntity(testEntity);

  group('addDebt', () {
    test('should return Right(null) when save is successful', () async {
      when(() => mockLocalDatasource.addDebt(any()))
          .thenAnswer((_) async => {});

      final result = await repository.addDebt(testEntity);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.addDebt(any())).called(1);
    });

    test('should return Left(CacheFailure) when save fails', () async {
      when(() => mockLocalDatasource.addDebt(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.addDebt(testEntity);

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('Borç eklenemedi'));
    });
  });

  group('updateDebt', () {
    test('should return Right(null) when update is successful', () async {
      when(() => mockLocalDatasource.updateDebt(any()))
          .thenAnswer((_) async => {});

      final result = await repository.updateDebt(testEntity);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.updateDebt(any())).called(1);
    });

    test('should return Left(CacheFailure) when update fails', () async {
      when(() => mockLocalDatasource.updateDebt(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.updateDebt(testEntity);

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('Borç güncellenemedi'));
    });
  });

  group('deleteDebt', () {
    test('should return Right(null) when delete is successful', () async {
      when(() => mockLocalDatasource.deleteDebt(any()))
          .thenAnswer((_) async => {});

      final result = await repository.deleteDebt('debt_1');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.deleteDebt('debt_1')).called(1);
    });

    test('should return Left(CacheFailure) when delete fails', () async {
      when(() => mockLocalDatasource.deleteDebt(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.deleteDebt('debt_1');

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('Borç silinemedi'));
    });
  });

  group('getDebtsByWalletId', () {
    test(
        'should return Right(List<DebtEntity>) when datasource call is successful',
        () async {
      when(() => mockLocalDatasource.getDebtsByWalletId(any()))
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getDebtsByWalletId('wallet_1');

      expect(result.isRight(), true);
      expect((result as Right<Failure, List<DebtEntity>>).value, [testEntity]);
      verify(() => mockLocalDatasource.getDebtsByWalletId('wallet_1'))
          .called(1);
    });

    test('should return Left(CacheFailure) when datasource call fails',
        () async {
      when(() => mockLocalDatasource.getDebtsByWalletId(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.getDebtsByWalletId('wallet_1');

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, List<DebtEntity>>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('Borçlar getirilemedi'));
    });
  });
}
