import 'dart:ui';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetInvestmentsUseCase extends Mock implements GetInvestmentsUseCase {}

class MockAddInvestmentUseCase extends Mock implements AddInvestmentUseCase {}

class MockUpdateInvestmentUseCase extends Mock
    implements UpdateInvestmentUseCase {}

class MockDeleteInvestmentUseCase extends Mock
    implements DeleteInvestmentUseCase {}

class MockGetLiveQuoteUseCase extends Mock implements GetLiveQuoteUseCase {}

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

void main() {
  late MockGetInvestmentsUseCase mockGetInvestmentsUseCase;
  late MockAddInvestmentUseCase mockAddInvestmentUseCase;
  late MockUpdateInvestmentUseCase mockUpdateUseCase;
  late MockDeleteInvestmentUseCase mockDeleteUseCase;
  late MockGetLiveQuoteUseCase mockGetLiveQuoteUseCase;
  late MockWalletMetricsService mockMetricsService;
  late InvestmentBloc investmentBloc;

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
    mockGetInvestmentsUseCase = MockGetInvestmentsUseCase();
    mockAddInvestmentUseCase = MockAddInvestmentUseCase();
    mockUpdateUseCase = MockUpdateInvestmentUseCase();
    mockDeleteUseCase = MockDeleteInvestmentUseCase();
    mockGetLiveQuoteUseCase = MockGetLiveQuoteUseCase();
    mockMetricsService = MockWalletMetricsService();

    investmentBloc = InvestmentBloc(
      getInvestmentsUseCase: mockGetInvestmentsUseCase,
      addInvestmentUseCase: mockAddInvestmentUseCase,
      updateInvestmentUseCase: mockUpdateUseCase,
      deleteInvestmentUseCase: mockDeleteUseCase,
      getLiveQuoteUseCase: mockGetLiveQuoteUseCase,
      walletMetricsService: mockMetricsService,
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
        const InvestmentError('Fetch Error'),
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
        const InvestmentActionSuccess('Yatırım başarıyla eklendi'),
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
        const InvestmentActionSuccess(
            'Yatırım başarıyla eklendi (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
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
        const InvestmentError('Add failed'),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
            ));
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
        const InvestmentActionSuccess('Yatırım güncellendi'),
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
        const InvestmentActionSuccess('Yatırım güncellendi'),
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
        const InvestmentActionSuccess('Yatırım güncellendi'),
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
      priceTl: 1600.0,
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
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess('1 yatırımın fiyatı güncellendi'),
        InvestmentLoading(),
        InvestmentLoaded([refreshableInvestment], totalAmount: 2000.0),
      ],
      verify: (_) {
        final captured = verify(() => mockUpdateUseCase(captureAny()))
            .captured
            .first as InvestmentEntity;
        // quantity (1.5) * priceTl (1600.0) = 2400.0
        expect(captured.currentValue, 2400.0);
        expect(captured.currency, 'USD');
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
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentError(
            'Yenilenebilir yatırım yok (sembol ve miktar gerekli)'),
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
                ))
            .thenAnswer((_) async => const Left(ServerFailure('Quote failed')));
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const RefreshPricesEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentError('Fiyatlar alınamadı, değerler değiştirilmedi'),
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
        investmentId: 'inv_refresh',
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess('1 yatırımın fiyatı güncellendi'),
        InvestmentLoading(),
        InvestmentLoaded([refreshableInvestment], totalAmount: 2000.0),
      ],
      verify: (_) {
        verify(() => mockGetLiveQuoteUseCase(
            symbol: 'XAU', type: InvestmentType.gold)).called(1);
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
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess('1 güncellendi, 1 alınamadı'),
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
      const InvestmentActionSuccess(
          'Yatırım güncellendi (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
      InvestmentLoading(),
      InvestmentLoaded([testInvestment.copyWith(amount: 1500.0)],
          totalAmount: 1500.0),
    ],
  );

  group('DeleteInvestmentEvent', () {
    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentActionSuccess] and records cash movement (income) for currentValue when recordSale is true',
      build: () {
        when(() => mockDeleteUseCase('inv_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1200.0, // currentValue is 1200.0
              isIncome: true,
              title: 'Yatırım Satışı',
              tag: CashMovementTags.investmentSell,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const DeleteInvestmentEvent(
        id: 'inv_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        currentValue: 1200.0,
        recordSale: true,
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess('Yatırım satıldı'),
        InvestmentLoading(),
        const InvestmentLoaded([], totalAmount: 0.0),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentActionSuccess] and records cash movement (income) for cost amount (correction) when recordSale is false and amount > 0',
      build: () {
        when(() => mockDeleteUseCase('inv_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0, // amount is 1000.0
              isIncome: true,
              title: 'Yatırım kaydı silindi (düzeltme)',
              tag: CashMovementTags.investmentCorrection,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const DeleteInvestmentEvent(
        id: 'inv_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        currentValue: 1200.0,
        recordSale: false,
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess('Kayıt silindi, alım kaydı düzeltildi'),
        InvestmentLoading(),
        const InvestmentLoaded([], totalAmount: 0.0),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits success with cash warning when recordCashMovement returns false during sale',
      build: () {
        when(() => mockDeleteUseCase('inv_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
            )).thenAnswer((_) async => false);
        when(() => mockMetricsService.syncInvestment('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetInvestmentsUseCase(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return investmentBloc;
      },
      act: (bloc) => bloc.add(const DeleteInvestmentEvent(
        id: 'inv_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        currentValue: 1200.0,
        recordSale: true,
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess(
            'Yatırım satıldı (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
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
      act: (bloc) => bloc.add(const DeleteInvestmentEvent(
        id: 'inv_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 0.0,
        currentValue: 0.0,
        recordSale: false,
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentActionSuccess('Kayıt silindi, alım kaydı düzeltildi'),
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
      act: (bloc) => bloc.add(const DeleteInvestmentEvent(
        id: 'inv_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        currentValue: 1200.0,
        recordSale: true,
      )),
      expect: () => [
        InvestmentLoading(),
        const InvestmentError('Delete failed'),
      ],
    );
  });
}
