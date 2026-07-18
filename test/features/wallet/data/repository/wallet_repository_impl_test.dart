import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/wallet/data/datasource/wallet_local_datasource.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletLocalDataSource extends Mock implements WalletLocalDataSource {}

void main() {
  late MockWalletLocalDataSource mockLocalDataSource;
  late WalletRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      WalletModel(
        id: 'wallet_1',
        userId: 'user_1',
        name: 'Cash',
        balance: 1000.0,
        debt: 100.0,
        credit: 50.0,
        investment: 200.0,
        colorHex: '0xFF4CAF50',
        iconName: 'money',
        createdAt: DateTime(2026, 6, 1),
        openingBalance: 1000.0,
      ),
    );
  });

  setUp(() {
    mockLocalDataSource = MockWalletLocalDataSource();
    repository = WalletRepositoryImpl(dataSource: mockLocalDataSource);
  });

  group('WalletRepositoryImpl', () {
    final createdDate = DateTime(2026, 6, 1);
    final entity = WalletEntity(
      id: 'wallet_1',
      userId: 'user_1',
      name: 'Cash',
      balance: 1000.0,
      debt: 100.0,
      credit: 50.0,
      investment: 200.0,
      colorHex: '0xFF4CAF50',
      iconName: 'money',
      createdAt: createdDate,
      isActive: true,
      sortOrder: 1,
      openingBalance: 800.0,
    );

    final model = WalletModel.fromEntity(entity);

    group('createWallet', () {
      test('should return Right(String) when call is successful', () async {
        when(() => mockLocalDataSource.createWallet(any()))
            .thenAnswer((_) async => 'wallet_1');

        final result = await repository.createWallet(entity);

        expect(result, const Right('wallet_1'));
        verify(() => mockLocalDataSource.createWallet(any())).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.createWallet(any()))
            .thenThrow(Exception('Hive error'));

        final result = await repository.createWallet(entity);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('should not return right'),
        );
      });
    });

    group('deleteWallet', () {
      test('should return Right(null) when call is successful', () async {
        when(() => mockLocalDataSource.deleteWallet(any()))
            .thenAnswer((_) async => {});

        final result = await repository.deleteWallet('wallet_1');

        expect(result, const Right(null));
        verify(() => mockLocalDataSource.deleteWallet('wallet_1')).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.deleteWallet(any()))
            .thenThrow(Exception('Hive error'));

        final result = await repository.deleteWallet('wallet_1');

        expect(result.isLeft(), true);
      });
    });

    group('getWallets', () {
      test('should return Right(List<WalletEntity>) when call is successful',
          () async {
        when(() => mockLocalDataSource.getWallets(any()))
            .thenAnswer((_) async => [model]);

        final result = await repository.getWallets('user_1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should not return failure'),
          (entities) => expect(entities, [entity]),
        );
        verify(() => mockLocalDataSource.getWallets('user_1')).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.getWallets(any()))
            .thenThrow(Exception('Hive error'));

        final result = await repository.getWallets('user_1');

        expect(result.isLeft(), true);
      });
    });

    group('updateWallet', () {
      test('should return Right(null) when call is successful', () async {
        when(() => mockLocalDataSource.updateWallet(any()))
            .thenAnswer((_) async => {});

        final result = await repository.updateWallet(entity);

        expect(result, const Right(null));
        verify(() => mockLocalDataSource.updateWallet(any())).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.updateWallet(any()))
            .thenThrow(Exception('Hive error'));

        final result = await repository.updateWallet(entity);

        expect(result.isLeft(), true);
      });
    });

    group('getActiveWallet', () {
      test('should return Right(WalletEntity?) when call is successful',
          () async {
        when(() => mockLocalDataSource.getActiveWallet(any()))
            .thenAnswer((_) async => model);

        final result = await repository.getActiveWallet('user_1');

        expect(result, Right(entity));
        verify(() => mockLocalDataSource.getActiveWallet('user_1')).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.getActiveWallet(any()))
            .thenThrow(Exception('Hive error'));

        final result = await repository.getActiveWallet('user_1');

        expect(result.isLeft(), true);
      });
    });

    group('getWalletById', () {
      test('should return Right(WalletEntity?) when call is successful',
          () async {
        when(() => mockLocalDataSource.getWalletById(any()))
            .thenAnswer((_) async => model);

        final result = await repository.getWalletById('wallet_1');

        expect(result, Right(entity));
        verify(() => mockLocalDataSource.getWalletById('wallet_1')).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.getWalletById(any()))
            .thenThrow(Exception('Hive error'));

        final result = await repository.getWalletById('wallet_1');

        expect(result.isLeft(), true);
      });
    });

    group('setActiveWallet', () {
      test('should return Right(null) when call is successful', () async {
        when(() => mockLocalDataSource.setActiveWallet(
              userId: any(named: 'userId'),
              newActiveWalletId: any(named: 'newActiveWalletId'),
            )).thenAnswer((_) async => {});

        final result = await repository.setActiveWallet(
            userId: 'user_1', newActiveWalletId: 'wallet_1');

        expect(result, const Right(null));
        verify(() => mockLocalDataSource.setActiveWallet(
            userId: 'user_1', newActiveWalletId: 'wallet_1')).called(1);
      });

      test('should return Left(CacheFailure) when call fails', () async {
        when(() => mockLocalDataSource.setActiveWallet(
              userId: any(named: 'userId'),
              newActiveWalletId: any(named: 'newActiveWalletId'),
            )).thenThrow(Exception('Hive error'));

        final result = await repository.setActiveWallet(
            userId: 'user_1', newActiveWalletId: 'wallet_1');

        expect(result.isLeft(), true);
      });
    });

    group('watchWallets', () {
      test('should emit Right(List<WalletEntity>) from dataSource stream',
          () async {
        when(() => mockLocalDataSource.watchWallets(any()))
            .thenAnswer((_) => Stream.value([model]));

        final stream = repository.watchWallets('user_1');

        final event = await stream.first;
        expect(event.isRight(), true);
        event.fold(
          (failure) => fail('should not return failure'),
          (entities) => expect(entities, [entity]),
        );
      });

      test('should emit Left(CacheFailure) when watch stream fails', () async {
        when(() => mockLocalDataSource.watchWallets(any()))
            .thenAnswer((_) => Stream.error(Exception('Stream error')));

        final stream = repository.watchWallets('user_1');

        final event = await stream.first;
        expect(event.isLeft(), true);
        event.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('should not return right'),
        );
      });
    });
  });
}
