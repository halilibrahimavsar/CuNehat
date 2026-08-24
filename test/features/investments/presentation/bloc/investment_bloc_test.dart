import 'dart:ui';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/goal_usecases.dart';
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';

class MockGetInvestmentsUseCase extends Mock implements GetInvestmentsUseCase {}

class MockAddInvestmentUseCase extends Mock implements AddInvestmentUseCase {}

class MockUpdateInvestmentUseCase extends Mock
    implements UpdateInvestmentUseCase {}

class MockDeleteInvestmentUseCase extends Mock
    implements DeleteInvestmentUseCase {}

class MockGetLiveQuoteUseCase extends Mock implements GetLiveQuoteUseCase {}

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

class MockGetGoalsUseCase extends Mock implements GetGoalsUseCase {}

class MockSaveGoalUseCase extends Mock implements SaveGoalUseCase {}

class MockDeleteGoalUseCase extends Mock implements DeleteGoalUseCase {}

void main() {
  late MockGetInvestmentsUseCase mockGetInvestmentsUseCase;
  late MockAddInvestmentUseCase mockAddInvestmentUseCase;
  late MockUpdateInvestmentUseCase mockUpdateUseCase;
  late MockDeleteInvestmentUseCase mockDeleteUseCase;
  late MockGetLiveQuoteUseCase mockGetLiveQuoteUseCase;
  late MockWalletMetricsService mockMetricsService;
  late MockGetGoalsUseCase mockGetGoalsUseCase;
  late MockSaveGoalUseCase mockSaveGoalUseCase;
  late MockDeleteGoalUseCase mockDeleteGoalUseCase;
  late InvestmentBloc investmentBloc;
  late TransactionsChangedNotifier changedNotifier;

  setUpAll(() {
    registerFallbackValue(InvestmentType.stock);
    registerFallbackValue(
      InvestmentEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        name: 'Fallback',
        amount: 0.0,
        currentValue: 0.0,
        type: InvestmentType.stock,
        color: const Color(0xFF000000),
        dateAdded: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    changedNotifier = TransactionsChangedNotifier();
    mockGetInvestmentsUseCase = MockGetInvestmentsUseCase();
    mockAddInvestmentUseCase = MockAddInvestmentUseCase();
    mockUpdateUseCase = MockUpdateInvestmentUseCase();
    mockDeleteUseCase = MockDeleteInvestmentUseCase();
    mockGetLiveQuoteUseCase = MockGetLiveQuoteUseCase();
    mockMetricsService = MockWalletMetricsService();
    mockGetGoalsUseCase = MockGetGoalsUseCase();
    mockSaveGoalUseCase = MockSaveGoalUseCase();
    mockDeleteGoalUseCase = MockDeleteGoalUseCase();
    // Hedefler listeyle birlikte okunuyor; varsayılan olarak boş.
    when(() => mockGetGoalsUseCase(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async => const Right([]));

    investmentBloc = InvestmentBloc(
      getInvestmentsUseCase: mockGetInvestmentsUseCase,
      addInvestmentUseCase: mockAddInvestmentUseCase,
      updateInvestmentUseCase: mockUpdateUseCase,
      deleteInvestmentUseCase: mockDeleteUseCase,
      getLiveQuoteUseCase: mockGetLiveQuoteUseCase,
      getGoalsUseCase: mockGetGoalsUseCase,
      saveGoalUseCase: mockSaveGoalUseCase,
      deleteGoalUseCase: mockDeleteGoalUseCase,
      walletMetricsService: mockMetricsService,
      transactionsChangedNotifier: changedNotifier,
    );
  });

  tearDown(() {
    investmentBloc.close();
  });

  final testInvestment = InvestmentEntity(
    id: 'inv_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Apple Inc.',
    amount: 1000.0,
    currentValue: 1200.0,
    type: InvestmentType.stock,
    color: const Color(0xFF00FF00),
    dateAdded: DateTime(2026, 6, 13),
    symbol: 'AAPL',
    quantity: 5.0,
  );

  group('GetInvestmentsEvent', () {
    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentLoaded] on success',
      build: () {
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([testInvestment]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const GetInvestmentsEvent(
          userId: 'user_123', walletId: 'wallet_123')),
      expect: () => [
        InvestmentLoading(),
        InvestmentLoaded([testInvestment], totalAmount: 1000.0),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentError] on failure',
      build: () {
        when(() => mockGetInvestmentsUseCase(
                  userId: 'user_123',
                  walletId: 'wallet_123',
                ))
            .thenAnswer((_) async => const Left(ServerFailure('Fetch Error')));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const GetInvestmentsEvent(
          userId: 'user_123', walletId: 'wallet_123')),
      expect: () => [
        InvestmentLoading(),
        const InvestmentError(RawFailureNotice('Fetch Error')),
      ],
    );
  });

  group('CreateInvestmentEvent', () {
    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentActionSuccess] and reloads list on success',
      build: () {
        when(() => mockAddInvestmentUseCase(testInvestment))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: false,
              title: 'Apple Inc.',
              tag: CashMovementTags.investmentBuy,
              date: any(named: 'date'),
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([testInvestment]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(CreateInvestmentEvent(
        investment: testInvestment,
        userId: 'user_123',
        walletId: 'wallet_123',
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(InvestmentAddedNotice()),
        InvestmentLoading(),
        InvestmentLoaded([testInvestment], totalAmount: 1000.0),
      ],
      verify: (_) {
        verify(() => mockAddInvestmentUseCase(testInvestment)).called(1);
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: false,
              title: 'Apple Inc.',
              tag: CashMovementTags.investmentBuy,
              date: any(named: 'date'),
            )).called(1);
        verify(() => mockMetricsService.syncInvestment('wallet_123')).called(1);
      },
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentActionSuccess] with warning suffix when cash record fails',
      build: () {
        when(() => mockAddInvestmentUseCase(testInvestment))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
            )).thenAnswer((_) async => false);
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([testInvestment]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(CreateInvestmentEvent(
        investment: testInvestment,
        userId: 'user_123',
        walletId: 'wallet_123',
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(InvestmentAddedNotice(), cashOk: false),
        InvestmentLoading(),
        InvestmentLoaded([testInvestment], totalAmount: 1000.0),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentError] on usecase failure',
      build: () {
        when(() => mockAddInvestmentUseCase(testInvestment))
            .thenAnswer((_) async => const Left(ServerFailure('Add failed')));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(CreateInvestmentEvent(
        investment: testInvestment,
        userId: 'user_123',
        walletId: 'wallet_123',
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentError(RawFailureNotice('Add failed')),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
            ));
      },
    );
    blocTest<InvestmentBloc, InvestmentState>(
      '"zaten bende" kaydı deftere gider yazmaz',
      build: () {
        when(() => mockAddInvestmentUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(CreateInvestmentEvent(
        investment: testInvestment.copyWith(unbookedCost: 1000.0),
        userId: 'user_123',
        walletId: 'wallet_123',
      )),
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
            ));
      },
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'alım gideri BUGÜNE değil kaydın alım TARİHİNE yazılır',
      build: () {
        when(() => mockAddInvestmentUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(CreateInvestmentEvent(
        // Geçen ay alınmış varlık: gider kendi ayında görünmeli.
        investment: testInvestment.copyWith(dateAdded: DateTime(2026, 5, 3)),
        userId: 'user_123',
        walletId: 'wallet_123',
      )),
      verify: (_) {
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: false,
              title: any(named: 'title'),
              tag: CashMovementTags.investmentBuy,
              date: DateTime(2026, 5, 3),
            )).called(1);
      },
    );
  });

  group('UpdateInvestmentEvent', () {
    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentActionSuccess] and triggers cash movement when cost increases',
      build: () {
        final updated = testInvestment.copyWith(amount: 1500.0);
        when(() => mockUpdateUseCase(updated))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 500.0, // cost diff is 1500 - 1000 = 500.
              isIncome:
                  false, // positive cost diff means we spent money (expense)
              title: 'Yatırım güncellendi: Apple Inc.',
              tag: CashMovementTags.investmentBuy,
              date: any(named: 'date'),
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([updated]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(UpdateInvestmentEvent(
        investment: testInvestment.copyWith(amount: 1500.0),
        userId: 'user_123',
        walletId: 'wallet_123',
        prevAmount: 1000.0,
        newAmount: 1500.0,
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(InvestmentUpdatedNotice()),
        InvestmentLoading(),
        InvestmentLoaded([testInvestment.copyWith(amount: 1500.0)],
            totalAmount: 1500.0),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentActionSuccess] and triggers income cash movement when cost decreases',
      build: () {
        final updated = testInvestment.copyWith(amount: 800.0);
        when(() => mockUpdateUseCase(updated))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 200.0, // cost diff absolute is 200.
              isIncome:
                  true, // negative cost diff means we got money back (income)
              title: 'Yatırım güncellendi: Apple Inc.',
              tag: CashMovementTags.investmentBuy,
              date: any(named: 'date'),
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([updated]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(UpdateInvestmentEvent(
        investment: testInvestment.copyWith(amount: 800.0),
        userId: 'user_123',
        walletId: 'wallet_123',
        prevAmount: 1000.0,
        newAmount: 800.0,
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(InvestmentUpdatedNotice()),
        InvestmentLoading(),
        InvestmentLoaded([testInvestment.copyWith(amount: 800.0)],
            totalAmount: 800.0),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'does NOT trigger cash movement when cost is unchanged',
      build: () {
        when(() => mockUpdateUseCase(testInvestment))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([testInvestment]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(UpdateInvestmentEvent(
        investment: testInvestment,
        userId: 'user_123',
        walletId: 'wallet_123',
        prevAmount: 1000.0,
        newAmount: 1000.0,
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(InvestmentUpdatedNotice()),
        InvestmentLoading(),
        InvestmentLoaded([testInvestment], totalAmount: 1000.0),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
            ));
      },
    );
  });

  group('RefreshPricesEvent', () {
    final refreshableInvestment = InvestmentEntity(
      id: 'inv_refresh',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Gold Portfolio',
      amount: 2000.0,
      currentValue: 2000.0,
      type: InvestmentType.gold,
      color: const Color(0xFFFFFF00),
      dateAdded: DateTime(2026, 6, 13),
      symbol: 'XAU',
      quantity: 1.5,
    );

    final secondInvestment = InvestmentEntity(
      id: 'inv_second',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Gold Extra',
      amount: 3000.0,
      currentValue: 3000.0,
      type: InvestmentType.gold,
      color: const Color(0xFFFFFF00),
      dateAdded: DateTime(2026, 6, 13),
      symbol: 'XAU',
      quantity: 2.0,
    );

    const testQuote = LivePriceQuote(
      price: 1500.0,
      currency: 'USD',
      convertedPrice: 1600.0,
      targetCurrency: 'TRY',
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'successfully fetches live quote and updates matching investments',
      build: () {
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([refreshableInvestment]));
        when(() => mockGetLiveQuoteUseCase(
              symbol: 'XAU',
              type: InvestmentType.gold,
              targetCurrency: 'TRY',
            )).thenAnswer((_) async => const Right(testQuote));
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const RefreshPricesEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
        walletCurrency: 'TRY',
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(
            PricesRefreshedNotice(updated: 1, failed: 0)),
        InvestmentLoading(),
        InvestmentLoaded([refreshableInvestment], totalAmount: 2000.0),
      ],
      verify: (_) {
        final captured = verify(() => mockUpdateUseCase(captureAny()))
            .captured
            .first as InvestmentEntity;
        // quantity (1.5) * convertedPrice (1600.0) = 2400.0
        expect(captured.currentValue, 2400.0);
        expect(captured.currency, 'USD');
      },
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'cüzdanın birimini değerleme hedefi olarak fiyat servisine iletir',
      build: () {
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([refreshableInvestment]));
        // USD cüzdan: fiyat USD'ye çevrilmiş gelir (150 $/birim).
        when(() => mockGetLiveQuoteUseCase(
              symbol: 'XAU',
              type: InvestmentType.gold,
              targetCurrency: 'USD',
            )).thenAnswer((_) async => const Right(LivePriceQuote(
              price: 1500.0,
              currency: 'TRY',
              convertedPrice: 150.0,
              targetCurrency: 'USD',
            )));
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const RefreshPricesEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
        walletCurrency: 'USD',
      )),
      verify: (_) {
        // Hedef birim gerçekten geçti (TRY'ye düşülmedi).
        verify(() => mockGetLiveQuoteUseCase(
              symbol: 'XAU',
              type: InvestmentType.gold,
              targetCurrency: 'USD',
            )).called(1);
        final captured = verify(() => mockUpdateUseCase(captureAny()))
            .captured
            .first as InvestmentEntity;
        // Değerleme çevrilmiş fiyattan: 1.5 × 150 $ = 225 $ (ham 1500 ₺ değil).
        expect(captured.currentValue, 225.0);
        // Kayıtta saklanan birim fiyat KAYNAĞININ birimi.
        expect(captured.currency, 'TRY');
      },
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits error when no investments can be refreshed (e.g. missing symbol/quantity)',
      build: () {
        final nonRefreshable = InvestmentEntity(
          id: 'inv_123',
          userId: 'user_123',
          walletId: 'wallet_123',
          name: 'Apple Inc.',
          amount: 1000.0,
          currentValue: 1200.0,
          type: InvestmentType.stock,
          color: const Color(0xFF00FF00),
          dateAdded: DateTime(2026, 6, 13),
          symbol: null,
          quantity: null,
        );
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([nonRefreshable]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const RefreshPricesEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
        walletCurrency: 'TRY',
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentError(NoRefreshablePricesNotice()),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits error but still reloads list when quote fetching fails',
      build: () {
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([refreshableInvestment]));
        when(() => mockGetLiveQuoteUseCase(
                  symbol: 'XAU',
                  type: InvestmentType.gold,
                  targetCurrency: 'TRY',
                ))
            .thenAnswer((_) async => const Left(ServerFailure('Quote failed')));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const RefreshPricesEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
        walletCurrency: 'TRY',
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentError(PricesUnavailableNotice()),
        InvestmentLoading(),
        InvestmentLoaded([refreshableInvestment], totalAmount: 2000.0),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'refreshes only the investment matching the provided investmentId filter',
      build: () {
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([refreshableInvestment]));
        when(() => mockGetLiveQuoteUseCase(
              symbol: 'XAU',
              type: InvestmentType.gold,
              targetCurrency: 'TRY',
            )).thenAnswer((_) async => const Right(testQuote));
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const RefreshPricesEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
        walletCurrency: 'TRY',
        investmentId: 'inv_refresh',
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(
            PricesRefreshedNotice(updated: 1, failed: 0)),
        InvestmentLoading(),
        InvestmentLoaded([refreshableInvestment], totalAmount: 2000.0),
      ],
      verify: (_) {
        verify(() => mockGetLiveQuoteUseCase(
            symbol: 'XAU',
            type: InvestmentType.gold,
            targetCurrency: 'TRY')).called(1);
      },
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits partial success message when some refreshes succeed and some fail',
      build: () {
        bool firstUpdate = true;
        when(() => mockGetInvestmentsUseCase(
                  userId: 'user_123',
                  walletId: 'wallet_123',
                ))
            .thenAnswer(
                (_) async => Right([refreshableInvestment, secondInvestment]));
        when(() => mockGetLiveQuoteUseCase(
              symbol: 'XAU',
              type: InvestmentType.gold,
              targetCurrency: 'TRY',
            )).thenAnswer((_) async => const Right(testQuote));
        when(() => mockUpdateUseCase(any())).thenAnswer((_) async {
          if (firstUpdate) {
            firstUpdate = false;
            return const Right(null);
          }
          return const Left(ServerFailure('Save failed'));
        });
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const RefreshPricesEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
        walletCurrency: 'TRY',
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(
            PricesRefreshedNotice(updated: 1, failed: 1)),
        InvestmentLoading(),
        InvestmentLoaded([refreshableInvestment, secondInvestment],
            totalAmount: 5000.0),
      ],
    );
  });

  blocTest<InvestmentBloc, InvestmentState>(
    'emits success with cash warning when recordCashMovement returns false during update',
    build: () {
      final updated = testInvestment.copyWith(amount: 1500.0);
      when(() => mockUpdateUseCase(updated))
          .thenAnswer((_) async => const Right(null));
      when(() => mockMetricsService.recordCashMovement(
            walletId: any(named: 'walletId'),
            userId: any(named: 'userId'),
            amount: any(named: 'amount'),
            isIncome: any(named: 'isIncome'),
            title: any(named: 'title'),
            tag: any(named: 'tag'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => false);
      when(() => mockMetricsService.syncInvestment('wallet_123'))
          .thenAnswer((_) async => true);
      when(() => mockGetInvestmentsUseCase(
            userId: 'user_123',
            walletId: 'wallet_123',
          )).thenAnswer((_) async => Right([updated]));
      return investmentBloc;
    },
    act: (bloc) => bloc.add(UpdateInvestmentEvent(
      investment: testInvestment.copyWith(amount: 1500.0),
      userId: 'user_123',
      walletId: 'wallet_123',
      prevAmount: 1000.0,
      newAmount: 1500.0,
    )),
    expect: () => [
      InvestmentLoading(),
      const InvestmentActionSuccess(InvestmentUpdatedNotice(), cashOk: false),
      InvestmentLoading(),
      InvestmentLoaded([testInvestment.copyWith(amount: 1500.0)],
          totalAmount: 1500.0),
    ],
  );

  blocTest<InvestmentBloc, InvestmentState>(
    'hata yayınlandıktan sonra son liste geri konur (ekran boşalmaz)',
    build: () {
      when(() => mockGetInvestmentsUseCase(
            userId: 'user_123',
            walletId: 'wallet_123',
          )).thenAnswer((_) async => Right([testInvestment]));
      when(() => mockUpdateUseCase(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Yazılamadı')));
      return investmentBloc;
    },
    act: (bloc) async {
      bloc.add(GetInvestmentsEvent(userId: 'user_123', walletId: 'wallet_123'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(UpdateInvestmentEvent(
        investment: testInvestment,
        userId: 'user_123',
        walletId: 'wallet_123',
        prevAmount: 1000.0,
        newAmount: 1000.0,
      ));
    },
    expect: () => [
      InvestmentLoading(),
      InvestmentLoaded([testInvestment], totalAmount: 1000.0),
      InvestmentLoading(),
      const InvestmentError(RawFailureNotice('Yazılamadı')),
      // Hata mesajı gösterilir ama portföy "0 yatırım"a düşmez.
      InvestmentLoaded([testInvestment], totalAmount: 1000.0),
    ],
  );

  group('hedef olayları', () {
    final goal = GoalEntity(
      id: 'goal_1',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Ev peşinatı',
      targetAmount: 100000,
      category: 'ev',
      color: const Color(0xFF00897B),
      createdAt: DateTime(2026, 1, 1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'liste hedeflerle BİRLİKTE yüklenir',
      build: () {
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([testInvestment]));
        when(() => mockGetGoalsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([goal]));
        return investmentBloc;
      },
      act: (bloc) => bloc
          .add(GetInvestmentsEvent(userId: 'user_123', walletId: 'wallet_123')),
      expect: () => [
        InvestmentLoading(),
        InvestmentLoaded([testInvestment], goals: [goal], totalAmount: 1000.0),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'hedef kaydetmek DEFTERE dokunmaz (hedef bir kap, para hareketi değil)',
      build: () {
        when(() => mockSaveGoalUseCase(goal))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(SaveGoalEvent(goal)),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(GoalSavedNotice()),
        InvestmentLoading(),
        const InvestmentLoaded([], totalAmount: 0.0),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
            ));
        verifyNever(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            ));
      },
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'hedef silme başarılı olunca liste tazelenir',
      build: () {
        when(() => mockDeleteGoalUseCase(goal))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(DeleteGoalEvent(goal)),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(GoalDeletedNotice()),
        InvestmentLoading(),
        const InvestmentLoaded([], totalAmount: 0.0),
      ],
    );
  });

  group('PartialSellInvestmentEvent', () {
    final previous = InvestmentEntity(
      id: 'inv_123',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Altın Birikimi',
      amount: 4000.0,
      currentValue: 5000.0,
      type: InvestmentType.gold,
      color: const Color(0xFFFFC107),
      dateAdded: DateTime(2026, 1, 1),
      symbol: 'gram-altin',
      quantity: 4.0,
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'cüzdana MALİYET FARKI değil ELİNE GEÇEN tutar gelir yazılır',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
                  walletId: any(named: 'walletId'),
                  entries: any(named: 'entries'),
                ))
            .thenAnswer((_) async =>
                const CashWriteResult(ok: true, transactionIds: ['tx_1']));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(PartialSellInvestmentEvent(
        previous: previous,
        // Çeyreği satıldı: maliyet 3.000, değer 3.750, miktar 3.
        remaining: previous.copyWith(
          amount: 3000.0,
          currentValue: 3750.0,
          quantity: 3.0,
        ),
        proceeds: 1300.0,
        userId: 'user_123',
        walletId: 'wallet_123',
      )),
      expect: () => [
        InvestmentLoading(),
        isA<InvestmentActionSuccess>()
            .having((s) => s.notice, 'notice',
                const InvestmentPartiallySoldNotice())
            .having(
              (s) => s.undo,
              'undo',
              isA<InvestmentDeletionUndo>()
                  .having((u) => u.investment, 'satıştan önceki hâli', previous)
                  .having(
                      (u) => u.reversalTransactionIds, 'satış kaydı', ['tx_1']),
            ),
        InvestmentLoading(),
        const InvestmentLoaded([], totalAmount: 0.0),
      ],
      verify: (_) {
        final entries = verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;
        expect(entries, hasLength(1));
        // Maliyet farkı 1.000 olurdu; deftere giren satış bedeli 1.300.
        expect(entries.single.amount, 1300.0);
        expect(entries.single.isIncome, isTrue);
        expect(entries.single.tag, CashMovementTags.investmentSell);
      },
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'bedelsiz devirde (0) deftere 0 tutarlı hareket yazılmaz',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(PartialSellInvestmentEvent(
        previous: previous,
        remaining: previous.copyWith(quantity: 3.0),
        proceeds: 0.0,
        userId: 'user_123',
        walletId: 'wallet_123',
      )),
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            ));
      },
    );
  });

  group('DeleteInvestmentEvent', () {
    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentActionSuccess] and records cash movement (income) for currentValue when recordSale is true',
      build: () {
        when(() => mockDeleteUseCase('inv_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => const CashWriteResult(ok: true));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(DeleteInvestmentEvent(
        id: 'inv_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        currentValue: 1200.0,
        recordSale: true,
        dateAdded: DateTime(2026, 1, 1),
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(InvestmentSoldNotice()),
        InvestmentLoading(),
        const InvestmentLoaded([], totalAmount: 0.0),
      ],
      verify: (_) {
        final entries = verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;
        expect(entries, hasLength(1));
        expect(entries.single.amount, 1200.0); // currentValue
        expect(entries.single.isIncome, isTrue);
        expect(entries.single.tag, CashMovementTags.investmentSell);
        // Satış BUGÜN gerçekleşen bir olay: tarih verilmez, "şimdi" olur.
        expect(entries.single.date, isNull);
      },
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'düzeltme ters kaydı KAYIT TARİHİNE yazılır (satış değil)',
      build: () {
        when(() => mockDeleteUseCase('inv_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => const CashWriteResult(ok: true));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(DeleteInvestmentEvent(
        id: 'inv_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        currentValue: 1200.0,
        recordSale: false,
        dateAdded: DateTime(2026, 1, 1),
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(InvestmentDeletedNotice()),
        InvestmentLoading(),
        const InvestmentLoaded([], totalAmount: 0.0),
      ],
      verify: (_) {
        final entries = verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;
        expect(entries, hasLength(1));
        expect(entries.single.amount, 1000.0);
        expect(entries.single.isIncome, isTrue);
        expect(entries.single.tag, CashMovementTags.investmentCorrection);
        // Satış BUGÜN olan gerçek bir olaydır; düzeltme ise geçmişteki alımı
        // iptal eder → kaydın açılış tarihine yazılır.
        expect(entries.single.date, DateTime(2026, 1, 1));
      },
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits success with cash warning when recordCashMovement returns false during sale',
      build: () {
        when(() => mockDeleteUseCase('inv_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => const CashWriteResult(ok: false));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(DeleteInvestmentEvent(
        id: 'inv_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        currentValue: 1200.0,
        recordSale: true,
        dateAdded: DateTime(2026, 1, 1),
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(InvestmentSoldNotice(), cashOk: false),
        InvestmentLoading(),
        const InvestmentLoaded([], totalAmount: 0.0),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'does NOT record cash movement when recordSale is false and amount is 0',
      build: () {
        when(() => mockDeleteUseCase('inv_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(DeleteInvestmentEvent(
        id: 'inv_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 0.0,
        currentValue: 0.0,
        recordSale: false,
        dateAdded: DateTime(2026, 1, 1),
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(InvestmentDeletedNotice()),
        InvestmentLoading(),
        const InvestmentLoaded([], totalAmount: 0.0),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
            ));
      },
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentError] on failure',
      build: () {
        when(() => mockDeleteUseCase('inv_123')).thenAnswer(
            (_) async => const Left(ServerFailure('Delete failed')));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(DeleteInvestmentEvent(
        id: 'inv_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        currentValue: 1200.0,
        recordSale: true,
        dateAdded: DateTime(2026, 1, 1),
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentError(RawFailureNotice('Delete failed')),
      ],
    );
  });
}
