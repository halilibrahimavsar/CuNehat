import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/data/datasource/investment_local_datasource.dart';
import 'package:cunehat/features/investments/data/datasource/investment_remote_datasource.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/repositories/investment_repository_impl.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInvestmentLocalDatasource extends Mock
    implements InvestmentLocalDatasource {}

class MockInvestmentRemoteDataSource extends Mock
    implements InvestmentRemoteDataSource {}

void main() {
  late InvestmentRepositoryImpl repository;
  late MockInvestmentLocalDatasource mockLocalDatasource;
  late MockInvestmentRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(
      InvestmentModel(
        id: 'fallback',
        userId: 'user',
        walletId: 'wallet',
        name: 'fallback',
        amount: 0.0,
        currentValue: 0.0,
        type: InvestmentType.custom,
        color: Colors.black,
        dateAdded: DateTime(2026, 1, 1),
      ),
    );
    registerFallbackValue(InvestmentType.custom);
  });

  setUp(() {
    mockLocalDatasource = MockInvestmentLocalDatasource();
    mockRemoteDataSource = MockInvestmentRemoteDataSource();
    repository = InvestmentRepositoryImpl(
      localDataSource: mockLocalDatasource,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  final date = DateTime(2026, 6, 1);
  final testEntity = InvestmentEntity(
    id: 'inv_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    name: 'Bitcoin',
    amount: 1000.0,
    currentValue: 1200.0,
    type: InvestmentType.custom,
    color: Colors.orange,
    dateAdded: date,
  );

  final testModel = InvestmentModel.fromEntity(testEntity);

  group('addInvestment', () {
    test('should return Right(null) when call is successful', () async {
      when(() => mockLocalDatasource.addInvestment(any()))
          .thenAnswer((_) async => {});

      final result = await repository.addInvestment(testEntity);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.addInvestment(any())).called(1);
    });

    test('should return Left(CacheFailure) when call fails', () async {
      when(() => mockLocalDatasource.addInvestment(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.addInvestment(testEntity);

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
    });
  });

  group('deleteInvestment', () {
    test('should return Right(null) when call is successful', () async {
      when(() => mockLocalDatasource.deleteInvestment(id: any(named: 'id')))
          .thenAnswer((_) async => {});

      final result = await repository.deleteInvestment('inv_1');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.deleteInvestment(id: 'inv_1')).called(1);
    });

    test('should return Left(CacheFailure) when call fails', () async {
      when(() => mockLocalDatasource.deleteInvestment(id: any(named: 'id')))
          .thenThrow(Exception('DB Error'));

      final result = await repository.deleteInvestment('inv_1');

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
    });
  });

  group('getInvestments', () {
    test('should return Right(List<InvestmentEntity>) when call is successful',
        () async {
      when(() => mockLocalDatasource.getInvestments(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
          )).thenAnswer((_) async => [testModel]);

      final result = await repository.getInvestments(
          userId: 'user_1', walletId: 'wallet_1');

      expect(result.isRight(), true);
      expect((result as Right<Failure, List<InvestmentEntity>>).value,
          [testModel]);
    });

    test('should return Left(CacheFailure) when call fails', () async {
      when(() => mockLocalDatasource.getInvestments(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
          )).thenThrow(Exception('DB Error'));

      final result = await repository.getInvestments(
          userId: 'user_1', walletId: 'wallet_1');

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, List<InvestmentEntity>>).value;
      expect(failure is CacheFailure, true);
    });
  });

  group('updateInvestment', () {
    test('should return Right(null) when call is successful', () async {
      when(() => mockLocalDatasource.updateInvestment(any()))
          .thenAnswer((_) async => {});

      final result = await repository.updateInvestment(testEntity);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.updateInvestment(any())).called(1);
    });

    test('should return Left(CacheFailure) when call fails', () async {
      when(() => mockLocalDatasource.updateInvestment(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.updateInvestment(testEntity);

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
    });
  });

  group('getLiveQuote', () {
    const quote = LivePriceQuote(price: 100.0, currency: 'TRY', priceTl: 100.0);

    test('should return Right(LivePriceQuote) when call is successful',
        () async {
      when(() => mockRemoteDataSource.getLiveQuote(
            symbol: any(named: 'symbol'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => quote);

      final result = await repository.getLiveQuote(
          symbol: 'THYAO.IS', type: InvestmentType.stock);

      expect(result, const Right<Failure, LivePriceQuote>(quote));
      verify(() => mockRemoteDataSource.getLiveQuote(
          symbol: 'THYAO.IS', type: InvestmentType.stock)).called(1);
    });

    test('should return Left(ServerFailure) when call fails', () async {
      when(() => mockRemoteDataSource.getLiveQuote(
            symbol: any(named: 'symbol'),
            type: any(named: 'type'),
          )).thenThrow(Exception('Server Error'));

      final result = await repository.getLiveQuote(
          symbol: 'THYAO.IS', type: InvestmentType.stock);

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, LivePriceQuote>).value;
      expect(failure is ServerFailure, true);
    });
  });
}
