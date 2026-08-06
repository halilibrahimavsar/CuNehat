import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

/// Showcase turları getIt üzerinden koordinatörü çeker; widget testlerinde
/// gerçek koordinatör kayıtlı olmadığından mock'lanır.
class _MockOnboardingCoordinator extends Mock
    implements OnboardingCoordinator {}

void main() {
  late MockTransactionBloc mockTransactionBloc;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    // Showcase widget'ı kayıtlı bir scope yoksa initState'te fırlatır.
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
    getIt.allowReassignment = true;
  });

  setUp(() {
    // tearDown'daki getIt.reset() kayıtları sildiğinden test başına yapılır.
    final onboardingCoordinator = _MockOnboardingCoordinator();
    when(() => onboardingCoordinator.isSeen(any())).thenReturn(true);
    getIt.registerSingleton<OnboardingCoordinator>(onboardingCoordinator);
    mockTransactionBloc = MockTransactionBloc();
    getIt.registerSingleton<TransactionBloc>(mockTransactionBloc);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
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
      home: BlocProvider<AmountVisibilityCubit>(
        create: (_) => AmountVisibilityCubit(),
        child: child,
      ),
    );
  }

  final testTransaction1 = TransactionEntity(
    id: 'tx_1',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Altın Alındı',
    tag: CashMovementTags.investmentBuy,
    amount: 1000.0,
    date: DateTime(2026, 1, 1),
    type: TransactionTypeModel.expense,
    isSystem: true,
  );

  final testTransaction2 = TransactionEntity(
    id: 'tx_2',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Normal Gider',
    tag: 'Food',
    amount: 200.0,
    date: DateTime(2026, 1, 2),
    type: TransactionTypeModel.expense,
    isSystem: false,
  );

  testWidgets('renders CircularProgressIndicator when loading',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state)
        .thenReturn(const TransactionLoading(previousTransactions: []));

    await tester.pumpWidget(
      buildTestableWidget(
        const InvestmentDetailPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when there are no investment transactions',
      (WidgetTester tester) async {
    // There is a non-investment transaction, so the list isn't completely empty,
    // but investment filtered list is empty.
    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          testTransaction2.date: [testTransaction2]
        },
        allTransactions: [testTransaction2],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const InvestmentDetailPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Henüz Yatırım Kaydı Yok'), findsOneWidget);
    expect(
      find.text('Yatırım geçmişiniz burada listelenecektir.'),
      findsOneWidget,
    );
  });

  testWidgets('renders list of investment transactions when loaded',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          testTransaction1.date: [testTransaction1],
          testTransaction2.date: [testTransaction2],
        },
        allTransactions: [testTransaction1, testTransaction2],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const InvestmentDetailPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          showAppBar: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar title is present
    expect(find.text('Birikim Detayı'), findsOneWidget);

    // Verify header exists
    expect(find.text('Geçmiş'), findsOneWidget);

    // Verify the investment transaction is shown
    expect(find.text('Altın Alındı'), findsWidgets);

    // Verify the normal transaction is NOT shown (filtered out)
    expect(find.text('Normal Gider'), findsNothing);
  });
}
