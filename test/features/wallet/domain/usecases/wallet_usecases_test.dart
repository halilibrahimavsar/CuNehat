import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockWalletRepository mockRepository;
  late WalletCreateUseCase createUseCase;
  late WalletDeleteUseCase deleteUseCase;
  late WalletGetUseCase getUseCase;
  late WalletWatchUseCase watchUseCase;
  late WalletUpdateUseCase updateUseCase;
  late WalletSetActiveUseCase setActiveUseCase;
  late WalletGetActiveUseCase getActiveUseCase;
  late WalletGetByIdUseCase getByIdUseCase;

  setUpAll(() {
    registerFallbackValue(
      WalletEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        name: 'Fallback',
        balance: 0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '#000000',
        iconName: 'wallet',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockWalletRepository();
    createUseCase = WalletCreateUseCase(mockRepository);
    deleteUseCase = WalletDeleteUseCase(mockRepository);
    getUseCase = WalletGetUseCase(mockRepository);
    watchUseCase = WalletWatchUseCase(mockRepository);
    updateUseCase = WalletUpdateUseCase(mockRepository);
    setActiveUseCase = WalletSetActiveUseCase(mockRepository);
    getActiveUseCase = WalletGetActiveUseCase(mockRepository);
    getByIdUseCase = WalletGetByIdUseCase(mockRepository);
  });

  final testWallet = WalletEntity(
    id: 'wallet_123',
    userId: 'user_123',
    name: 'My Wallet',
    balance: 500,
    debt: 100,
    credit: 50,
    investment: 200,
    colorHex: '#FF5733',
    iconName: 'savings',
    createdAt: DateTime(2026, 6, 13),
    isActive: true,
    sortOrder: 1,
    openingBalance: 400,
  );

  group('WalletCreateUseCase', () {
    test('should return Right(id) when wallet has an ID and creation succeeds',
        () async {
      when(() => mockRepository.createWallet(testWallet))
          .thenAnswer((_) async => const Right('wallet_123'));

      final result = await createUseCase(testWallet);

      expect(result, const Right<Failure, String>('wallet_123'));
      verify(() => mockRepository.createWallet(testWallet)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should generate V7 ID and return Right(id) when wallet ID is null',
        () async {
      final walletWithoutId = WalletEntity(
        id: null,
        userId: 'user_123',
        name: 'No ID Wallet',
        balance: 0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '#000000',
        iconName: 'wallet',
        createdAt: DateTime(2026, 6, 13),
      );

      String? capturedId;
      when(() => mockRepository.createWallet(any()))
          .thenAnswer((invocation) async {
        final wallet = invocation.positionalArguments[0] as WalletEntity;
        capturedId = wallet.id;
        return Right(wallet.id!);
      });

      final result = await createUseCase(walletWithoutId);

      expect(result, Right<Failure, String>(capturedId!));
      expect(capturedId, isNotNull);
      expect(capturedId, isNotEmpty);
      verify(() => mockRepository.createWallet(any())).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(Failure) when creation fails', () async {
      const failure = ServerFailure('Database error');
      when(() => mockRepository.createWallet(testWallet))
          .thenAnswer((_) async => const Left(failure));

      final result = await createUseCase(testWallet);

      expect(result, const Left<Failure, String>(failure));
      verify(() => mockRepository.createWallet(testWallet)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('WalletDeleteUseCase', () {
    test('should return Right(void) when deletion succeeds', () async {
      when(() => mockRepository.deleteWallet('wallet_123'))
          .thenAnswer((_) async => const Right(null));

      final result = await deleteUseCase('wallet_123');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepository.deleteWallet('wallet_123')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(Failure) when deletion fails', () async {
      const failure = ServerFailure('Delete failed');
      when(() => mockRepository.deleteWallet('wallet_123'))
          .thenAnswer((_) async => const Left(failure));

      final result = await deleteUseCase('wallet_123');

      expect(result, const Left<Failure, void>(failure));
      verify(() => mockRepository.deleteWallet('wallet_123')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('WalletGetUseCase', () {
    test('should return Right(List<WalletEntity>) when retrieval succeeds',
        () async {
      final wallets = [testWallet];
      when(() => mockRepository.getWallets('user_123'))
          .thenAnswer((_) async => Right(wallets));

      final result = await getUseCase('user_123');

      expect(result, Right<Failure, List<WalletEntity>>(wallets));
      verify(() => mockRepository.getWallets('user_123')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(Failure) when retrieval fails', () async {
      const failure = ServerFailure('Load failed');
      when(() => mockRepository.getWallets('user_123'))
          .thenAnswer((_) async => const Left(failure));

      final result = await getUseCase('user_123');

      expect(result, const Left<Failure, List<WalletEntity>>(failure));
      verify(() => mockRepository.getWallets('user_123')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('WalletWatchUseCase', () {
    test('should emit Right(List<WalletEntity>) from the stream', () async {
      final wallets = [testWallet];
      when(() => mockRepository.watchWallets('user_123'))
          .thenAnswer((_) => Stream.value(Right(wallets)));

      final resultStream = watchUseCase('user_123');

      await expectLater(
        resultStream,
        emitsInOrder([
          Right<Failure, List<WalletEntity>>(wallets),
        ]),
      );
      verify(() => mockRepository.watchWallets('user_123')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should emit Left(Failure) from the stream when database fails',
        () async {
      const failure = ServerFailure('Stream failure');
      when(() => mockRepository.watchWallets('user_123'))
          .thenAnswer((_) => Stream.value(const Left(failure)));

      final resultStream = watchUseCase('user_123');

      await expectLater(
        resultStream,
        emitsInOrder([
          const Left<Failure, List<WalletEntity>>(failure),
        ]),
      );
      verify(() => mockRepository.watchWallets('user_123')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('WalletUpdateUseCase', () {
    test('should return Right(void) when update succeeds', () async {
      when(() => mockRepository.updateWallet(testWallet))
          .thenAnswer((_) async => const Right(null));

      final result = await updateUseCase(testWallet);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepository.updateWallet(testWallet)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(ValidationFailure) when wallet ID is null',
        () async {
      final walletWithNullId = WalletEntity(
        id: null,
        userId: 'user_123',
        name: 'No ID',
        balance: 0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '#000000',
        iconName: 'wallet',
        createdAt: DateTime(2026, 6, 13),
      );

      final result = await updateUseCase(walletWithNullId);

      expect(
          result,
          const Left<Failure, void>(ValidationFailure(
              'Wallet ID cannot be null for update operation')));
      verifyZeroInteractions(mockRepository);
    });

    test('should return Left(Failure) when repository update fails', () async {
      const failure = ServerFailure('Update failed');
      when(() => mockRepository.updateWallet(testWallet))
          .thenAnswer((_) async => const Left(failure));

      final result = await updateUseCase(testWallet);

      expect(result, const Left<Failure, void>(failure));
      verify(() => mockRepository.updateWallet(testWallet)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('WalletSetActiveUseCase', () {
    test('should return Right(void) when setting active wallet succeeds',
        () async {
      when(() => mockRepository.setActiveWallet(
            userId: 'user_123',
            newActiveWalletId: 'wallet_123',
          )).thenAnswer((_) async => const Right(null));

      final result =
          await setActiveUseCase(userId: 'user_123', walletId: 'wallet_123');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepository.setActiveWallet(
            userId: 'user_123',
            newActiveWalletId: 'wallet_123',
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(Failure) when setting active wallet fails',
        () async {
      const failure = ServerFailure('Failed to set active');
      when(() => mockRepository.setActiveWallet(
            userId: 'user_123',
            newActiveWalletId: 'wallet_123',
          )).thenAnswer((_) async => const Left(failure));

      final result =
          await setActiveUseCase(userId: 'user_123', walletId: 'wallet_123');

      expect(result, const Left<Failure, void>(failure));
      verify(() => mockRepository.setActiveWallet(
            userId: 'user_123',
            newActiveWalletId: 'wallet_123',
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('WalletGetActiveUseCase', () {
    test('should return Right(WalletEntity?) when retrieval succeeds',
        () async {
      when(() => mockRepository.getActiveWallet('user_123'))
          .thenAnswer((_) async => Right(testWallet));

      final result = await getActiveUseCase('user_123');

      expect(result, Right<Failure, WalletEntity?>(testWallet));
      verify(() => mockRepository.getActiveWallet('user_123')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(Failure) when retrieval fails', () async {
      const failure = ServerFailure('Get active failed');
      when(() => mockRepository.getActiveWallet('user_123'))
          .thenAnswer((_) async => const Left(failure));

      final result = await getActiveUseCase('user_123');

      expect(result, const Left<Failure, WalletEntity?>(failure));
      verify(() => mockRepository.getActiveWallet('user_123')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('WalletGetByIdUseCase', () {
    test('should return Right(WalletEntity?) when retrieval succeeds',
        () async {
      when(() => mockRepository.getWalletById('wallet_123'))
          .thenAnswer((_) async => Right(testWallet));

      final result = await getByIdUseCase('wallet_123');

      expect(result, Right<Failure, WalletEntity?>(testWallet));
      verify(() => mockRepository.getWalletById('wallet_123')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(Failure) when retrieval fails', () async {
      const failure = ServerFailure('Get by ID failed');
      when(() => mockRepository.getWalletById('wallet_123'))
          .thenAnswer((_) async => const Left(failure));

      final result = await getByIdUseCase('wallet_123');

      expect(result, const Left<Failure, WalletEntity?>(failure));
      verify(() => mockRepository.getWalletById('wallet_123')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
