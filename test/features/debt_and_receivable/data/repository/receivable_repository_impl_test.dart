import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/debt_and_receivable/data/datasource/receivable_local_datasource.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/repositories/receivable_repository_impl.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReceivableLocalDatasource extends Mock
    implements ReceivableLocalDatasource {}

void main() {
  late ReceivableRepositoryImpl repository;
  late MockReceivableLocalDatasource mockLocalDatasource;

  setUpAll(() {
    registerFallbackValue(
      ReceivableModel(
        id: 'fallback',
        userId: 'user',
        walletId: 'wallet',
        debtorName: 'fallback',
        amount: 0.0,
        dueDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockLocalDatasource = MockReceivableLocalDatasource();
    repository = ReceivableRepositoryImpl(
        receivableDatasourceRepository: mockLocalDatasource);
  });

  final dueDate = DateTime(2026, 12, 31);
  final testEntity = ReceivableEntity(
    id: 'rec_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    debtorName: 'John Doe',
    amount: 1500.0,
    dueDate: dueDate,
    createdAt: DateTime(2026, 1, 1),
  );

  final testModel = ReceivableModel.fromEntity(testEntity);

  group('addReceivable', () {
    test('should return Right(null) when save is successful', () async {
      when(() => mockLocalDatasource.addReceivable(any()))
          .thenAnswer((_) async => {});

      final result = await repository.addReceivable(testEntity);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.addReceivable(any())).called(1);
    });

    test('should return Left(CacheFailure) when save fails', () async {
      when(() => mockLocalDatasource.addReceivable(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.addReceivable(testEntity);

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('Alacak eklenemedi'));
    });
  });

  group('updateReceivable', () {
    test('should return Right(null) when update is successful', () async {
      when(() => mockLocalDatasource.updateReceivable(any()))
          .thenAnswer((_) async => {});

      final result = await repository.updateReceivable(testEntity);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.updateReceivable(any())).called(1);
    });

    test('should return Left(CacheFailure) when update fails', () async {
      when(() => mockLocalDatasource.updateReceivable(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.updateReceivable(testEntity);

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('Alacak güncellenemedi'));
    });
  });

  group('deleteReceivable', () {
    test('should return Right(null) when delete is successful', () async {
      when(() => mockLocalDatasource.deleteReceivable(any()))
          .thenAnswer((_) async => {});

      final result = await repository.deleteReceivable('rec_1');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockLocalDatasource.deleteReceivable('rec_1')).called(1);
    });

    test('should return Left(CacheFailure) when delete fails', () async {
      when(() => mockLocalDatasource.deleteReceivable(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.deleteReceivable('rec_1');

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, void>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('Alacak silinemedi'));
    });
  });

  group('getReceivablesByWalletId', () {
    test(
        'should return Right(List<ReceivableEntity>) when datasource call is successful',
        () async {
      when(() => mockLocalDatasource.getReceivablesByWalletId(any()))
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getReceivablesByWalletId('wallet_1');

      expect(result.isRight(), true);
      expect((result as Right<Failure, List<ReceivableEntity>>).value,
          [testEntity]);
      verify(() => mockLocalDatasource.getReceivablesByWalletId('wallet_1'))
          .called(1);
    });

    test('should return Left(CacheFailure) when datasource call fails',
        () async {
      when(() => mockLocalDatasource.getReceivablesByWalletId(any()))
          .thenThrow(Exception('DB Error'));

      final result = await repository.getReceivablesByWalletId('wallet_1');

      expect(result.isLeft(), true);
      final failure = (result as Left<Failure, List<ReceivableEntity>>).value;
      expect(failure is CacheFailure, true);
      expect(failure.message, contains('Alacaklar getirilemedi'));
    });
  });
}
