import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/delete_recurring_transaction_usecase.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletGetUseCase extends Mock implements WalletGetUseCase {}

class MockWalletWatchUseCase extends Mock implements WalletWatchUseCase {}

class MockWalletCreateUseCase extends Mock implements WalletCreateUseCase {}

class MockWalletUpdateUseCase extends Mock implements WalletUpdateUseCase {}

class MockWalletDeleteUseCase extends Mock implements WalletDeleteUseCase {}

class MockWalletSetActiveUseCase extends Mock
    implements WalletSetActiveUseCase {}

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

class MockDeleteBudgetsForWalletUsecase extends Mock
    implements DeleteBudgetsForWalletUsecase {}

class MockDeleteRecurringTemplatesForWalletUsecase extends Mock
    implements DeleteRecurringTemplatesForWalletUsecase {}

void main() {
  late MockWalletGetUseCase mockGetUseCase;
  late MockWalletWatchUseCase mockWatchUseCase;
  late MockWalletCreateUseCase mockCreateUseCase;
  late MockWalletUpdateUseCase mockUpdateUseCase;
  late MockWalletDeleteUseCase mockDeleteUseCase;
  late MockWalletSetActiveUseCase mockSetActiveUseCase;
  late MockWalletMetricsService mockMetricsService;
  late MockDeleteBudgetsForWalletUsecase mockDeleteBudgetsForWallet;
  late MockDeleteRecurringTemplatesForWalletUsecase
      mockDeleteRecurringTemplatesForWallet;
  late WalletBloc walletBloc;

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
        openingBalance: 0,
      ),
    );
  });

  setUp(() {
    mockGetUseCase = MockWalletGetUseCase();
    mockWatchUseCase = MockWalletWatchUseCase();
    mockCreateUseCase = MockWalletCreateUseCase();
    mockUpdateUseCase = MockWalletUpdateUseCase();
    mockDeleteUseCase = MockWalletDeleteUseCase();
    mockSetActiveUseCase = MockWalletSetActiveUseCase();
    mockMetricsService = MockWalletMetricsService();
    mockDeleteBudgetsForWallet = MockDeleteBudgetsForWalletUsecase();
    mockDeleteRecurringTemplatesForWallet =
        MockDeleteRecurringTemplatesForWalletUsecase();
    // Cüzdan silme testleri: bütçe/şablon temizliği varsayılan olarak başarılı.
    when(() => mockDeleteBudgetsForWallet(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => mockDeleteRecurringTemplatesForWallet(any()))
        .thenAnswer((_) async => const Right(null));

    walletBloc = WalletBloc(
      getWalletsUseCase: mockGetUseCase,
      watchWalletsUseCase: mockWatchUseCase,
      createWalletUseCase: mockCreateUseCase,
      updateWalletUseCase: mockUpdateUseCase,
      deleteWalletUseCase: mockDeleteUseCase,
      setActiveWalletUseCase: mockSetActiveUseCase,
      walletMetricsService: mockMetricsService,
      deleteBudgetsForWalletUsecase: mockDeleteBudgetsForWallet,
      deleteRecurringTemplatesForWalletUsecase:
          mockDeleteRecurringTemplatesForWallet,
    );
  });

  tearDown(() {
    walletBloc.close();
  });

  final testActiveWallet = WalletEntity(
    id: 'wallet_active',
    userId: 'user_123',
    name: 'Active Wallet',
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

  final testInactiveWallet = WalletEntity(
    id: 'wallet_inactive',
    userId: 'user_123',
    name: 'Inactive Wallet',
    balance: 300,
    debt: 0,
    credit: 0,
    investment: 0,
    colorHex: '#000000',
    iconName: 'wallet',
    createdAt: DateTime(2026, 6, 13),
    isActive: false,
    sortOrder: 2,
    openingBalance: 300,
  );

  group('GetWalletsEvent', () {
    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoadingSt, WalletLoadedSt] when wallets exist and one is active',
      build: () {
        when(() => mockGetUseCase('user_123')).thenAnswer(
            (_) async => Right([testActiveWallet, testInactiveWallet]));
        when(() => mockMetricsService.syncBalance('wallet_active'))
            .thenAnswer((_) async => true);
        return walletBloc;
      },
      act: (bloc) => bloc.add(const GetWalletsEvent('user_123')),
      expect: () => [
        const WalletLoadingSt(),
        WalletLoadedSt(
            [testActiveWallet, testInactiveWallet], testActiveWallet),
      ],
      verify: (_) {
        verify(() => mockGetUseCase('user_123')).called(1);
        verify(() => mockMetricsService.syncBalance('wallet_active')).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits fallback SetActiveWalletEvent flow when wallets exist but none are active',
      build: () {
        when(() => mockGetUseCase('user_123'))
            .thenAnswer((_) async => Right([testInactiveWallet]));
        when(() => mockSetActiveUseCase(
              userId: 'user_123',
              walletId: 'wallet_inactive',
            )).thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncBalance('wallet_inactive'))
            .thenAnswer((_) async => true);
        return walletBloc;
      },
      act: (bloc) => bloc.add(const GetWalletsEvent('user_123')),
      expect: () => [
        const WalletLoadingSt(),
        WalletLoadedSt([testInactiveWallet], testInactiveWallet),
        WalletLoadedSt(
          [testInactiveWallet],
          testInactiveWallet,
          messageType: WalletMessageType.selected,
        ),
      ],
      verify: (_) {
        verify(() => mockGetUseCase('user_123')).called(1);
        verify(() => mockSetActiveUseCase(
              userId: 'user_123',
              walletId: 'wallet_inactive',
            )).called(1);
        verify(() => mockMetricsService.syncBalance('wallet_inactive'))
            .called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoadingSt, NoWalletSt] when wallets list is empty',
      build: () {
        when(() => mockGetUseCase('user_123'))
            .thenAnswer((_) async => const Right([]));
        return walletBloc;
      },
      act: (bloc) => bloc.add(const GetWalletsEvent('user_123')),
      expect: () => [
        const WalletLoadingSt(),
        const NoWalletSt(),
      ],
      verify: (_) {
        verify(() => mockGetUseCase('user_123')).called(1);
        verifyNoMoreInteractions(mockMetricsService);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoadingSt, WalletErrorSt] when use case fails',
      build: () {
        when(() => mockGetUseCase('user_123')).thenAnswer(
            (_) async => const Left(ServerFailure('Database error')));
        return walletBloc;
      },
      act: (bloc) => bloc.add(const GetWalletsEvent('user_123')),
      expect: () => [
        const WalletLoadingSt(),
        const WalletErrorSt('Database error'),
      ],
      verify: (_) {
        verify(() => mockGetUseCase('user_123')).called(1);
      },
    );
  });

  group('WatchWalletsEvent', () {
    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoadingSt, WalletLoadedSt] reactively when watch stream emits wallets',
      build: () {
        when(() => mockWatchUseCase('user_123'))
            .thenAnswer((_) => Stream.value(Right([testActiveWallet])));
        return walletBloc;
      },
      act: (bloc) => bloc.add(const WatchWalletsEvent('user_123')),
      expect: () => [
        const WalletLoadingSt(),
        WalletLoadedSt([testActiveWallet], testActiveWallet),
      ],
      verify: (_) {
        verify(() => mockWatchUseCase('user_123')).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoadingSt, NoWalletSt] when watch stream emits empty list',
      build: () {
        when(() => mockWatchUseCase('user_123'))
            .thenAnswer((_) => Stream.value(const Right([])));
        return walletBloc;
      },
      act: (bloc) => bloc.add(const WatchWalletsEvent('user_123')),
      expect: () => [
        const WalletLoadingSt(),
        const NoWalletSt(),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits [WalletLoadingSt, WalletErrorSt] when watch stream emits failure',
      build: () {
        when(() => mockWatchUseCase('user_123')).thenAnswer(
            (_) => Stream.value(const Left(ServerFailure('Stream failed'))));
        return walletBloc;
      },
      act: (bloc) => bloc.add(const WatchWalletsEvent('user_123')),
      expect: () => [
        const WalletLoadingSt(),
        const WalletErrorSt('Stream failed'),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'WatchWalletsEvent sets active wallet to fallback when no active wallet found in stream',
      build: () {
        when(() => mockWatchUseCase('user_123'))
            .thenAnswer((_) => Stream.value(Right([testInactiveWallet])));
        when(() => mockSetActiveUseCase(
              userId: 'user_123',
              walletId: 'wallet_inactive',
            )).thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      act: (bloc) => bloc.add(const WatchWalletsEvent('user_123')),
      expect: () => [
        const WalletLoadingSt(),
        WalletLoadedSt([testInactiveWallet], testInactiveWallet),
        WalletLoadedSt(
          [testInactiveWallet],
          testInactiveWallet,
          messageType: WalletMessageType.selected,
        ),
      ],
      verify: (_) {
        verify(() => mockWatchUseCase('user_123')).called(1);
        verify(() => mockSetActiveUseCase(
              userId: 'user_123',
              walletId: 'wallet_inactive',
            )).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'WatchWalletsEvent emits WalletErrorSt when watch stream throws exception',
      build: () {
        when(() => mockWatchUseCase('user_123'))
            .thenAnswer((_) => Stream.error(Exception('Stream error')));
        return walletBloc;
      },
      act: (bloc) => bloc.add(const WatchWalletsEvent('user_123')),
      expect: () => [
        const WalletLoadingSt(),
        const WalletErrorSt('Exception: Stream error'),
      ],
    );
  });

  group('GetWalletsEvent syncBalance error handling', () {
    blocTest<WalletBloc, WalletState>(
      'GetWalletsEvent safely catches error when syncBalance throws exception',
      build: () {
        when(() => mockGetUseCase('user_123'))
            .thenAnswer((_) async => Right([testActiveWallet]));
        when(() => mockMetricsService.syncBalance('wallet_active'))
            .thenAnswer((_) => Future<bool>.error(Exception('Sync failed')));
        return walletBloc;
      },
      act: (bloc) => bloc.add(const GetWalletsEvent('user_123')),
      expect: () => [
        const WalletLoadingSt(),
        WalletLoadedSt([testActiveWallet], testActiveWallet),
      ],
    );
  });

  group('CreateWalletEvent', () {
    blocTest<WalletBloc, WalletState>(
      'emits WalletLoadedSt with messageType created when success',
      build: () {
        when(() => mockCreateUseCase(testInactiveWallet))
            .thenAnswer((_) async => const Right('wallet_inactive'));
        when(() => mockSetActiveUseCase(
              userId: 'user_123',
              walletId: 'wallet_inactive',
            )).thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      seed: () => WalletLoadedSt([testActiveWallet], testActiveWallet),
      act: (bloc) => bloc.add(CreateWalletEvent(testInactiveWallet)),
      expect: () => [
        WalletLoadedSt(
          [testActiveWallet],
          testActiveWallet,
          messageType: WalletMessageType.created,
        ),
      ],
      verify: (_) {
        verify(() => mockCreateUseCase(testInactiveWallet)).called(1);
        verify(() => mockSetActiveUseCase(
              userId: 'user_123',
              walletId: 'wallet_inactive',
            )).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits WalletLoadedSt with error when creation fails',
      build: () {
        when(() => mockCreateUseCase(testInactiveWallet))
            .thenAnswer((_) async => const Left(ServerFailure('Create error')));
        return walletBloc;
      },
      seed: () => WalletLoadedSt([testActiveWallet], testActiveWallet),
      act: (bloc) => bloc.add(CreateWalletEvent(testInactiveWallet)),
      expect: () => [
        WalletLoadedSt(
          [testActiveWallet],
          testActiveWallet,
          error: 'Cüzdan oluşturulamadı: Create error',
        ),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits WalletLoadedSt with error when setting active wallet fails',
      build: () {
        when(() => mockCreateUseCase(testInactiveWallet))
            .thenAnswer((_) async => const Right('wallet_inactive'));
        when(() => mockSetActiveUseCase(
                  userId: 'user_123',
                  walletId: 'wallet_inactive',
                ))
            .thenAnswer(
                (_) async => const Left(ServerFailure('Set active error')));
        return walletBloc;
      },
      seed: () => WalletLoadedSt([testActiveWallet], testActiveWallet),
      act: (bloc) => bloc.add(CreateWalletEvent(testInactiveWallet)),
      expect: () => [
        WalletLoadedSt(
          [testActiveWallet],
          testActiveWallet,
          error: 'Aktif cüzdan ayarlanamadı: Set active error',
        ),
      ],
    );
  });

  group('UpdateWalletEvent', () {
    blocTest<WalletBloc, WalletState>(
      'calculates delta and calls update with new opening balance, emitting success messageType',
      build: () {
        // Test setup: old balance = 300, old opening = 300.
        // New balance updated via event = 350.
        // Delta = +50. New opening balance should be 300 + 50 = 350.
        final expectedWallet = testInactiveWallet.copyWith(
          balance: 350,
          openingBalance: 350,
        );
        when(() => mockUpdateUseCase(expectedWallet))
            .thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      seed: () => WalletLoadedSt([testInactiveWallet], testInactiveWallet),
      act: (bloc) => bloc.add(UpdateWalletEvent(
        testInactiveWallet.copyWith(balance: 350),
        // Form açılırken gösterilen bakiye; kullanıcı 300 → 350 yaptı.
        baselineBalance: 300,
      )),
      expect: () => [
        WalletLoadedSt(
          [testInactiveWallet],
          testInactiveWallet,
          messageType: WalletMessageType.updated,
        ),
      ],
      verify: (_) {
        final expectedWallet = testInactiveWallet.copyWith(
          balance: 350,
          openingBalance: 350,
        );
        verify(() => mockUpdateUseCase(expectedWallet)).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits loaded state with error when update fails',
      build: () {
        when(() => mockUpdateUseCase(any())).thenAnswer(
            (_) async => const Left(ServerFailure('Update failed')));
        return walletBloc;
      },
      seed: () => WalletLoadedSt([testActiveWallet], testActiveWallet),
      act: (bloc) => bloc.add(UpdateWalletEvent(testActiveWallet)),
      expect: () => [
        WalletLoadedSt(
          [testActiveWallet],
          testActiveWallet,
          error: 'Cüzdan güncellenemedi: Update failed',
        ),
      ],
    );

    // REGRESYON: form açıkken defter değişirse (düzenli işlem onayı, banka
    // içe aktarımı) ve kullanıcı bakiyeye DOKUNMADAN kaydederse, eski kod
    // farkı bayat anlık görüntüye göre ölçüp opening'i kalıcı kaydırıyordu.
    blocTest<WalletBloc, WalletState>(
      'bakiyeye dokunulmadıysa defter değişse bile opening kaydırılmaz',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      // Bloc'un bildiği canlı kayıt: bakiye 300 → 500 olmuş (opening aynı).
      seed: () => WalletLoadedSt(
        [testInactiveWallet.copyWith(balance: 500)],
        testInactiveWallet.copyWith(balance: 500),
      ),
      // Form 300 bakiyeyle açılmıştı; kullanıcı yalnız adı değiştirdi.
      act: (bloc) => bloc.add(UpdateWalletEvent(
        testInactiveWallet.copyWith(name: 'Yeni Ad'),
        baselineBalance: 300,
      )),
      verify: (_) {
        final captured =
            verify(() => mockUpdateUseCase(captureAny())).captured.single
                as WalletEntity;
        expect(captured.name, 'Yeni Ad');
        // Opening kaydırılmadı ve bakiye canlı defterden korundu.
        expect(captured.openingBalance, testInactiveWallet.openingBalance);
        expect(captured.balance, 500);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'bakiye gerçekten düzenlendiyse fark CANLI opening üzerine uygulanır',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      // Canlı opening 300 → 320 olmuş (başka bir yol yazmış).
      seed: () => WalletLoadedSt(
        [testInactiveWallet.copyWith(openingBalance: 320)],
        testInactiveWallet.copyWith(openingBalance: 320),
      ),
      // Form 300'le açıldı, kullanıcı 350 yazdı → delta +50.
      act: (bloc) => bloc.add(UpdateWalletEvent(
        testInactiveWallet.copyWith(balance: 350),
        baselineBalance: 300,
      )),
      verify: (_) {
        final captured =
            verify(() => mockUpdateUseCase(captureAny())).captured.single
                as WalletEntity;
        expect(captured.balance, 350);
        // Bayat 300 değil, canlı 320 + 50.
        expect(captured.openingBalance, 370);
      },
    );
  });

  group('DeleteWalletEvent', () {
    blocTest<WalletBloc, WalletState>(
      'purges wallet metrics first, then deletes wallet, emitting success messageType',
      build: () {
        when(() => mockMetricsService.purgeWalletData(
            'wallet_inactive', 'user_123')).thenAnswer((_) async {});
        when(() => mockDeleteUseCase('wallet_inactive'))
            .thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      seed: () => WalletLoadedSt([testInactiveWallet], testInactiveWallet),
      act: (bloc) => bloc.add(const DeleteWalletEvent('wallet_inactive')),
      expect: () => [
        WalletLoadedSt(
          [testInactiveWallet],
          testInactiveWallet,
          messageType: WalletMessageType.deleted,
        ),
      ],
      verify: (_) {
        verify(() => mockMetricsService.purgeWalletData(
            'wallet_inactive', 'user_123')).called(1);
        verify(() => mockDeleteBudgetsForWallet('wallet_inactive')).called(1);
        verify(() => mockDeleteRecurringTemplatesForWallet('wallet_inactive'))
            .called(1);
        verify(() => mockDeleteUseCase('wallet_inactive')).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits loaded state with error when deletion fails',
      build: () {
        when(() => mockMetricsService.purgeWalletData(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockDeleteUseCase('wallet_active')).thenAnswer(
            (_) async => const Left(ServerFailure('Delete failed')));
        return walletBloc;
      },
      seed: () => WalletLoadedSt([testActiveWallet], testActiveWallet),
      act: (bloc) => bloc.add(const DeleteWalletEvent('wallet_active')),
      expect: () => [
        WalletLoadedSt(
          [testActiveWallet],
          testActiveWallet,
          error: 'Cüzdan silinemedi: Delete failed',
        ),
      ],
    );
  });

  group('SetActiveWalletEvent', () {
    blocTest<WalletBloc, WalletState>(
      'emits loaded state with selected messageType when success',
      build: () {
        when(() => mockSetActiveUseCase(
              userId: 'user_123',
              walletId: 'wallet_inactive',
            )).thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      seed: () => WalletLoadedSt(
          [testActiveWallet, testInactiveWallet], testActiveWallet),
      act: (bloc) => bloc.add(const SetActiveWalletEvent(
        userId: 'user_123',
        walletId: 'wallet_inactive',
      )),
      expect: () => [
        WalletLoadedSt(
          [testActiveWallet, testInactiveWallet],
          testActiveWallet,
          messageType: WalletMessageType.selected,
        ),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits loaded state with error when changing active wallet fails',
      build: () {
        when(() => mockSetActiveUseCase(
                  userId: 'user_123',
                  walletId: 'wallet_inactive',
                ))
            .thenAnswer(
                (_) async => const Left(ServerFailure('Change active failed')));
        return walletBloc;
      },
      seed: () => WalletLoadedSt(
          [testActiveWallet, testInactiveWallet], testActiveWallet),
      act: (bloc) => bloc.add(const SetActiveWalletEvent(
        userId: 'user_123',
        walletId: 'wallet_inactive',
      )),
      expect: () => [
        WalletLoadedSt(
          [testActiveWallet, testInactiveWallet],
          testActiveWallet,
          error: 'Aktif cüzdan değiştirilemedi: Change active failed',
        ),
      ],
    );
  });

  group('WalletBloc Edge Cases and Helpers', () {
    blocTest<WalletBloc, WalletState>(
      'UpdateWalletEvent when state is not WalletLoadedSt',
      build: () {
        when(() => mockUpdateUseCase(testInactiveWallet))
            .thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      seed: () => const WalletLoadingSt(),
      act: (bloc) => bloc.add(UpdateWalletEvent(testInactiveWallet)),
      expect: () => const [],
      verify: (_) {
        verify(() => mockUpdateUseCase(testInactiveWallet)).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'DeleteWalletEvent when state is not WalletLoadedSt',
      build: () {
        when(() => mockDeleteUseCase('wallet_inactive'))
            .thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      seed: () => const WalletLoadingSt(),
      act: (bloc) => bloc.add(const DeleteWalletEvent('wallet_inactive')),
      expect: () => const [],
      verify: (_) {
        verifyNoMoreInteractions(mockMetricsService);
        verify(() => mockDeleteUseCase('wallet_inactive')).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'DeleteWalletEvent when wallet is not in loaded wallets list',
      build: () {
        when(() => mockDeleteUseCase('wallet_unknown'))
            .thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      seed: () => WalletLoadedSt([testActiveWallet], testActiveWallet),
      act: (bloc) => bloc.add(const DeleteWalletEvent('wallet_unknown')),
      expect: () => [
        WalletLoadedSt(
          [testActiveWallet],
          testActiveWallet,
          messageType: WalletMessageType.deleted,
        ),
      ],
      verify: (_) {
        verifyNoMoreInteractions(mockMetricsService);
        verify(() => mockDeleteUseCase('wallet_unknown')).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits NoWalletSt with error when creation fails in NoWalletSt state',
      build: () {
        when(() => mockCreateUseCase(testInactiveWallet))
            .thenAnswer((_) async => const Left(ServerFailure('Create error')));
        return walletBloc;
      },
      seed: () => const NoWalletSt(),
      act: (bloc) => bloc.add(CreateWalletEvent(testInactiveWallet)),
      expect: () => [
        const NoWalletSt(error: 'Cüzdan oluşturulamadı: Create error'),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits NoWalletSt with messageType created when success in NoWalletSt state',
      build: () {
        when(() => mockCreateUseCase(testInactiveWallet))
            .thenAnswer((_) async => const Right('wallet_inactive'));
        when(() => mockSetActiveUseCase(
              userId: 'user_123',
              walletId: 'wallet_inactive',
            )).thenAnswer((_) async => const Right(null));
        return walletBloc;
      },
      seed: () => const NoWalletSt(),
      act: (bloc) => bloc.add(CreateWalletEvent(testInactiveWallet)),
      expect: () => [
        const NoWalletSt(messageType: WalletMessageType.created),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits WalletErrorSt when active wallet setting fails in Initial state',
      build: () {
        when(() => mockCreateUseCase(testInactiveWallet))
            .thenAnswer((_) async => const Right('wallet_inactive'));
        when(() => mockSetActiveUseCase(
                  userId: 'user_123',
                  walletId: 'wallet_inactive',
                ))
            .thenAnswer(
                (_) async => const Left(ServerFailure('Set active error')));
        return walletBloc;
      },
      act: (bloc) => bloc.add(CreateWalletEvent(testInactiveWallet)),
      expect: () => [
        const WalletErrorSt('Aktif cüzdan ayarlanamadı: Set active error'),
      ],
    );
  });
}
