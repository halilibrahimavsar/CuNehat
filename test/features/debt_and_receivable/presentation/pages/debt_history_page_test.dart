import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';

class MockDebtBloc extends MockBloc<DebtEvent, DebtState> implements DebtBloc {}

class MockReceivableBloc extends MockBloc<ReceivableEvent, ReceivableState>
    implements ReceivableBloc {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  late MockDebtBloc mockDebtBloc;
  late MockReceivableBloc mockReceivableBloc;
  late MockOnboardingCoordinator mockOnboardingCoordinator;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(GetDebtsEvent('wallet_123'));
    registerFallbackValue(GetReceivablesEvent('wallet_123'));
    registerFallbackValue(OnboardingFlow.debtAdd);
    // Sayfa Showcase kullanır; kayıtlı bir scope yoksa initState fırlatır.
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    mockDebtBloc = MockDebtBloc();
    mockReceivableBloc = MockReceivableBloc();
    mockOnboardingCoordinator = MockOnboardingCoordinator();
    getIt.registerSingleton<DebtBloc>(mockDebtBloc);
    getIt.registerSingleton<ReceivableBloc>(mockReceivableBloc);
    // OnboardingAutoTourTrigger getIt üzerinden koordinatörü çeker.
    getIt.registerSingleton<OnboardingCoordinator>(mockOnboardingCoordinator);
    when(() => mockOnboardingCoordinator.isSeen(any())).thenReturn(true);
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
      home: child,
    );
  }

  final testPaidDebt = DebtEntity(
    calcMode: DebtCalcMode.none,
    expectedTotalAmount: 150000.0,
    id: 'debt_1',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Araba Kredisi',
    counterparty: 'Ziraat Bankası',
    type: DebtType.bankLoan,
    principalAmount: 150000.0,
    interestRate: 0.0,
    termMonths: 12,
    startDate: DateTime(2026, 1, 1),
    dueDate: DateTime(2026, 6, 1),
    isPaid: true,
    payments: [
      Payment(id: 'p1', date: DateTime(2026, 1, 15), amount: 150000.0),
    ],
  );

  final testPaidReceivable = ReceivableEntity(
    id: 'rec_1',
    userId: 'user_123',
    walletId: 'wallet_123',
    debtorName: 'Ahmet Yılmaz',
    amount: 5000.0,
    dueDate: DateTime(2026, 6, 10),
    isPaid: true,
    createdAt: DateTime(2026, 1, 1),
  );

  testWidgets('renders CircularProgressIndicator when loading in either tab',
      (WidgetTester tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoading());
    when(() => mockReceivableBloc.state).thenReturn(ReceivableLoading());

    await tester.pumpWidget(
      buildTestableWidget(
        const DebtHistoryPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          walletCurrency: 'TRY',
        ),
      ),
    );

    // Initial tab is Debt, so it should render CircularProgressIndicator of DebtBloc
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'renders empty state when there are no closed debts or receivables',
      (WidgetTester tester) async {
    when(() => mockDebtBloc.state).thenReturn(const DebtLoaded([]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(
      buildTestableWidget(
        const DebtHistoryPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          walletCurrency: 'TRY',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Debt empty state
    expect(find.text('Henüz Kapanan Borç Yok'), findsOneWidget);
    expect(
      find.text(
          'Ödemesi tamamlanıp kapatılan borçlarınızın geçmişi burada görüntülenecektir.'),
      findsOneWidget,
    );

    // Switch to Receivables Tab
    await tester.tap(find.text('Alacak Geçmişi'));
    await tester.pumpAndSettle();

    // Verify Receivable empty state
    expect(find.text('Henüz Tahsil Edilen Alacak Yok'), findsOneWidget);
    expect(
      find.text(
          'Ödendi olarak işaretlenen alacaklarınızın geçmişi burada görüntülenecektir.'),
      findsOneWidget,
    );
  });

  testWidgets('renders list of paid debts and receivables when loaded',
      (WidgetTester tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([testPaidDebt]));
    when(() => mockReceivableBloc.state)
        .thenReturn(ReceivableLoaded([testPaidReceivable]));

    await tester.pumpWidget(
      buildTestableWidget(
        const DebtHistoryPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          walletCurrency: 'TRY',
          showAppBar: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar Title
    expect(find.text('Geçmiş'), findsOneWidget);

    // Verify Debt history summary and card
    expect(find.text('Araba Kredisi'), findsOneWidget);
    expect(find.text('Ziraat Bankası'), findsOneWidget);
    expect(find.text('Ödendi'), findsWidgets);
    expect(find.text('150.000,00 ₺'), findsWidgets);

    // Switch to Receivables Tab
    await tester.tap(find.text('Alacak Geçmişi'));
    await tester.pumpAndSettle();

    // Verify Receivable history summary and card
    expect(find.text('Ahmet Yılmaz'), findsOneWidget);
    expect(find.text('Tahsil Edildi'), findsWidgets);
    expect(find.text('5.000,00 ₺'), findsWidgets);
  });

  testWidgets('döviz cüzdanda geçmiş tutarları cüzdanın biriminde yazılır',
      (WidgetTester tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([testPaidDebt]));
    when(() => mockReceivableBloc.state)
        .thenReturn(ReceivableLoaded([testPaidReceivable]));

    await tester.pumpWidget(
      buildTestableWidget(
        const DebtHistoryPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          walletCurrency: 'USD',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Özet kartı + borç kartı: ikisi de aynı tutarı $ ile yazar.
    expect(find.text('150.000,00 \$'), findsNWidgets(2));
    expect(find.textContaining('₺'), findsNothing);

    await tester.tap(find.text('Alacak Geçmişi'));
    await tester.pumpAndSettle();

    expect(find.text('5.000,00 \$'), findsNWidgets(2));
    expect(find.textContaining('₺'), findsNothing);
  });
}
