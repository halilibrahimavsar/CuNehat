import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_insights_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/daily_safe_to_spend_card.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_all_recurring_templates_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class MockGetAllRecurringTemplatesUsecase extends Mock
    implements GetAllRecurringTemplatesUsecase {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  late MockTransactionBloc mockTransactionBloc;
  late MockGetAllRecurringTemplatesUsecase mockGetAllRecurringTemplatesUsecase;
  late MockOnboardingCoordinator mockOnboardingCoordinator;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.transactionsInsights);
    ShowcaseView.register(
      onFinish: () {},
      onDismiss: (_) {},
    );
  });

  setUp(() {
    mockTransactionBloc = MockTransactionBloc();
    mockGetAllRecurringTemplatesUsecase = MockGetAllRecurringTemplatesUsecase();
    mockOnboardingCoordinator = MockOnboardingCoordinator();

    getIt.registerSingleton<TransactionBloc>(mockTransactionBloc);
    getIt.registerSingleton<GetAllRecurringTemplatesUsecase>(
        mockGetAllRecurringTemplatesUsecase);
    getIt.registerSingleton<OnboardingCoordinator>(mockOnboardingCoordinator);

    when(() => mockGetAllRecurringTemplatesUsecase()).thenAnswer(
      (_) async => const Right<Failure, List<RecurringTransactionEntity>>([]),
    );

    when(() => mockOnboardingCoordinator.isSeen(any())).thenReturn(true);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return BlocProvider<AmountVisibilityCubit>(
      create: (_) => AmountVisibilityCubit(),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr'),
          Locale('en'),
        ],
        locale: const Locale('tr'),
        home: child,
      ),
    );
  }

  testWidgets('renders empty state when transaction list is empty',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state).thenReturn(
      const TransactionLoaded(
        groupedTransactions: {},
        allTransactions: [],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionInsightsPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Detay Gösterilecek İşlem Yok'), findsOneWidget);
  });

  testWidgets(
      'renders summary and daily safe-to-spend card when income > expense',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final transactions = [
      TransactionEntity(
        id: 'tx_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Salary',
        tag: 'Maaş',
        amount: 10000.0,
        date: now,
        type: TransactionTypeModel.income,
      ),
      TransactionEntity(
        id: 'tx_2',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Market',
        tag: 'Market',
        amount: 2000.0,
        date: now,
        type: TransactionTypeModel.expense,
      ),
    ];

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: transactions},
        allTransactions: transactions,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionInsightsPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          showAppBar: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Akıllı İçgörüler'), findsWidgets);
    expect(find.byType(DailySafeToSpendCard), findsOneWidget);
  });
}
