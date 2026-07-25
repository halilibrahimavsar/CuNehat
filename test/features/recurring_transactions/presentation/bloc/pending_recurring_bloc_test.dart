import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/approve_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/delete_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_pending_recurring_transactions_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/skip_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetPendingRecurringTransactionsUsecase extends Mock
    implements GetPendingRecurringTransactionsUsecase {}

class MockApproveRecurringTransactionUsecase extends Mock
    implements ApproveRecurringTransactionUsecase {}

class MockDeleteRecurringTransactionUsecase extends Mock
    implements DeleteRecurringTransactionUsecase {}

class MockSkipRecurringTransactionUsecase extends Mock
    implements SkipRecurringTransactionUsecase {}

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

void main() {
  late MockGetPendingRecurringTransactionsUsecase mockGetPendingUsecase;
  late MockApproveRecurringTransactionUsecase mockApproveUsecase;
  late MockDeleteRecurringTransactionUsecase mockDeleteUsecase;
  late MockSkipRecurringTransactionUsecase mockSkipUsecase;
  late MockWalletMetricsService mockMetricsService;
  late TransactionsChangedNotifier changedNotifier;
  late PendingRecurringBloc pendingRecurringBloc;

  setUpAll(() {
    registerFallbackValue(
      RecurringTransactionEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        title: 'Fallback',
        tag: 'tag',
        amount: 0.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockGetPendingUsecase = MockGetPendingRecurringTransactionsUsecase();
    mockApproveUsecase = MockApproveRecurringTransactionUsecase();
    mockDeleteUsecase = MockDeleteRecurringTransactionUsecase();
    mockSkipUsecase = MockSkipRecurringTransactionUsecase();
    mockMetricsService = MockWalletMetricsService();
    changedNotifier = TransactionsChangedNotifier();

    pendingRecurringBloc = PendingRecurringBloc(
      mockGetPendingUsecase,
      mockApproveUsecase,
      mockDeleteUsecase,
      mockSkipUsecase,
      mockMetricsService,
      changedNotifier,
    );
  });

  tearDown(() {
    pendingRecurringBloc.close();
    changedNotifier.dispose();
  });

  final testTemplate = RecurringTransactionEntity(
    id: 'rec_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Netflix Subscription',
    tag: 'Entertainment',
    amount: 15.0,
    type: TransactionTypeModel.expense,
    frequency: RecurringFrequency.monthly,
    nextExecutionDate: DateTime(2026, 6, 20),
    isActive: true,
  );

  group('LoadPendingTransactionsEvent', () {
    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'emits [PendingRecurringLoading, PendingRecurringLoaded] on success',
      build: () {
        when(() => mockGetPendingUsecase())
            .thenAnswer((_) async => Right([testTemplate]));
        return pendingRecurringBloc;
      },
      act: (bloc) => bloc.add(LoadPendingTransactionsEvent()),
      expect: () => [
        PendingRecurringLoading(),
        PendingRecurringLoaded([testTemplate]),
      ],
    );

    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'emits [PendingRecurringLoading, PendingRecurringFailure] on failure',
      build: () {
        when(() => mockGetPendingUsecase()).thenAnswer(
            (_) async => const Left(ServerFailure('Pending load error')));
        return pendingRecurringBloc;
      },
      act: (bloc) => bloc.add(LoadPendingTransactionsEvent()),
      expect: () => [
        PendingRecurringLoading(),
        const PendingRecurringFailure(ServerFailure('Pending load error')),
      ],
    );
  });

  group('ApproveTransactionEvent', () {
    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'emits loading and loaded states via reload after successful approve',
      build: () {
        when(() => mockApproveUsecase(testTemplate,
                overrideAmount: any(named: 'overrideAmount')))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetPendingUsecase())
            .thenAnswer((_) async => const Right([]));
        return pendingRecurringBloc;
      },
      act: (bloc) => bloc.add(ApproveTransactionEvent(testTemplate)),
      expect: () => [
        PendingRecurringLoading(),
        const PendingRecurringLoaded([]),
      ],
      verify: (_) {
        verify(() => mockApproveUsecase(testTemplate)).called(1);
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
      },
    );

    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'passes overrideAmount to approveUsecase when provided',
      build: () {
        when(() => mockApproveUsecase(testTemplate, overrideAmount: 20.0))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetPendingUsecase())
            .thenAnswer((_) async => const Right([]));
        return pendingRecurringBloc;
      },
      act: (bloc) =>
          bloc.add(ApproveTransactionEvent(testTemplate, overrideAmount: 20.0)),
      expect: () => [
        PendingRecurringLoading(),
        const PendingRecurringLoaded([]),
      ],
      verify: (_) {
        verify(() => mockApproveUsecase(testTemplate, overrideAmount: 20.0))
            .called(1);
      },
    );

    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'completes approve successfully even when syncBalance fails',
      build: () {
        when(() => mockApproveUsecase(testTemplate,
                overrideAmount: any(named: 'overrideAmount')))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => false);
        when(() => mockGetPendingUsecase())
            .thenAnswer((_) async => const Right([]));
        return pendingRecurringBloc;
      },
      act: (bloc) => bloc.add(ApproveTransactionEvent(testTemplate)),
      expect: () => [
        PendingRecurringLoading(),
        const PendingRecurringLoaded([]),
      ],
      verify: (_) {
        verify(() => mockApproveUsecase(testTemplate)).called(1);
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
      },
    );

    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'emits [PendingRecurringFailure] on approveUsecase failure',
      build: () {
        when(() => mockApproveUsecase(testTemplate,
                overrideAmount: any(named: 'overrideAmount')))
            .thenAnswer(
                (_) async => const Left(ServerFailure('Approve error')));
        return pendingRecurringBloc;
      },
      act: (bloc) => bloc.add(ApproveTransactionEvent(testTemplate)),
      expect: () => [
        const PendingRecurringFailure(ServerFailure('Approve error')),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.syncBalance(any()));
      },
    );
  });

  group('çift dokunuş koruması', () {
    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'aynı şablon için arka arkaya iki onay tek işlem yaratır',
      build: () {
        when(() => mockApproveUsecase(testTemplate,
                overrideAmount: any(named: 'overrideAmount')))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetPendingUsecase())
            .thenAnswer((_) async => const Right([]));
        return pendingRecurringBloc;
      },
      // Bloc'un varsayılan olay dönüştürücüsü eşzamanlı (flatMap): koruma
      // olmadan iki onay akışı paralel çalışıp AYNI vade için iki gerçek
      // finansal işlem yaratıyordu.
      act: (bloc) => bloc
        ..add(ApproveTransactionEvent(testTemplate))
        ..add(ApproveTransactionEvent(testTemplate)),
      expect: () => [
        PendingRecurringLoading(),
        const PendingRecurringLoaded([]),
      ],
      verify: (_) {
        verify(() => mockApproveUsecase(testTemplate)).called(1);
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
      },
    );

    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'işlem sürerken satır meşgul olarak işaretlenir',
      build: () {
        when(() => mockApproveUsecase(testTemplate,
                overrideAmount: any(named: 'overrideAmount')))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetPendingUsecase())
            .thenAnswer((_) async => const Right([]));
        return pendingRecurringBloc;
      },
      seed: () => PendingRecurringLoaded([testTemplate]),
      act: (bloc) => bloc.add(ApproveTransactionEvent(testTemplate)),
      expect: () => [
        PendingRecurringLoaded([testTemplate],
            busyTemplateIds: const {'rec_123'}),
        PendingRecurringLoading(),
        const PendingRecurringLoaded([]),
      ],
    );
  });

  group('ApproveAllOccurrencesEvent', () {
    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'birikmiş tüm vadeleri tek seferde işler',
      build: () {
        when(() => mockApproveUsecase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetPendingUsecase())
            .thenAnswer((_) async => const Right([]));
        return pendingRecurringBloc;
      },
      // Günlük şablon, 2 gün gecikmiş: bugün dahil 3 vade birikmiş demektir.
      // Tek tek onayda kullanıcı 3 kez dokunmak zorunda kalıyordu.
      act: (bloc) => bloc.add(ApproveAllOccurrencesEvent(
        testTemplate.copyWith(
          frequency: RecurringFrequency.daily,
          nextExecutionDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
      )),
      expect: () => [
        PendingRecurringLoading(),
        const PendingRecurringLoaded([]),
      ],
      verify: (_) {
        verify(() => mockApproveUsecase(any())).called(3);
        // Bakiye her vade için değil, toplu işlem sonunda bir kez senkronlanır.
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
      },
    );

    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'vadesi gelmemiş şablonda hiçbir şey yapmaz',
      build: () {
        when(() => mockApproveUsecase(any()))
            .thenAnswer((_) async => const Right(null));
        return pendingRecurringBloc;
      },
      act: (bloc) => bloc.add(ApproveAllOccurrencesEvent(
        testTemplate.copyWith(nextExecutionDate: DateTime(2099, 1, 1)),
      )),
      expect: () => <PendingRecurringState>[],
      verify: (_) {
        verifyNever(() => mockApproveUsecase(any()));
        verifyNever(() => mockMetricsService.syncBalance(any()));
      },
    );
  });

  group('forceShow', () {
    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'bildirimden gelen yükleme forceShow bayrağını state\'e taşır',
      build: () {
        when(() => mockGetPendingUsecase())
            .thenAnswer((_) async => Right([testTemplate]));
        return pendingRecurringBloc;
      },
      act: (bloc) =>
          bloc.add(const LoadPendingTransactionsEvent(forceShow: true)),
      expect: () => [
        PendingRecurringLoading(),
        PendingRecurringLoaded([testTemplate], forceShow: true),
      ],
    );
  });

  group('SkipTransactionEvent', () {
    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'emits loading and loaded states via reload after successful skip',
      build: () {
        when(() => mockSkipUsecase(testTemplate))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetPendingUsecase())
            .thenAnswer((_) async => const Right([]));
        return pendingRecurringBloc;
      },
      act: (bloc) => bloc.add(SkipTransactionEvent(testTemplate)),
      expect: () => [
        PendingRecurringLoading(),
        const PendingRecurringLoaded([]),
      ],
      verify: (_) {
        verify(() => mockSkipUsecase(testTemplate)).called(1);
        verifyNever(() => mockMetricsService.syncBalance(any()));
      },
    );

    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'emits [PendingRecurringFailure] on skipUsecase failure',
      build: () {
        when(() => mockSkipUsecase(testTemplate))
            .thenAnswer((_) async => const Left(ServerFailure('Skip error')));
        return pendingRecurringBloc;
      },
      act: (bloc) => bloc.add(SkipTransactionEvent(testTemplate)),
      expect: () => [
        const PendingRecurringFailure(ServerFailure('Skip error')),
      ],
    );
  });

  group('DeleteTransactionEvent', () {
    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'emits loading and loaded states via reload after successful delete',
      build: () {
        when(() => mockDeleteUsecase('rec_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetPendingUsecase())
            .thenAnswer((_) async => const Right([]));
        return pendingRecurringBloc;
      },
      act: (bloc) => bloc.add(const DeleteTransactionEvent('rec_123')),
      expect: () => [
        PendingRecurringLoading(),
        const PendingRecurringLoaded([]),
      ],
      verify: (_) {
        verify(() => mockDeleteUsecase('rec_123')).called(1);
        verifyNever(() => mockMetricsService.syncBalance(any()));
      },
    );

    blocTest<PendingRecurringBloc, PendingRecurringState>(
      'emits [PendingRecurringFailure] on deleteUsecase failure',
      build: () {
        when(() => mockDeleteUsecase('rec_123'))
            .thenAnswer((_) async => const Left(ServerFailure('Delete error')));
        return pendingRecurringBloc;
      },
      act: (bloc) => bloc.add(const DeleteTransactionEvent('rec_123')),
      expect: () => [
        const PendingRecurringFailure(ServerFailure('Delete error')),
      ],
    );
  });
}
