import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_and_receivable_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';

class MockDebtBloc extends MockBloc<DebtEvent, DebtState> implements DebtBloc {}

class MockReceivableBloc extends MockBloc<ReceivableEvent, ReceivableState>
    implements ReceivableBloc {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

/// Borç/alacak sayfası artık HER para biriminde açılır: tutarlar cüzdanın
/// kendi birimindedir (kayıtta ayrı birim alanı yok, birim cüzdandan gelir).
void main() {
  late MockDebtBloc mockDebtBloc;
  late MockReceivableBloc mockReceivableBloc;
  late MockOnboardingCoordinator mockOnboardingCoordinator;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(GetDebtsEvent('wallet_1'));
    registerFallbackValue(GetReceivablesEvent('wallet_1'));
    registerFallbackValue(OnboardingFlow.shell);
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  setUp(() {
    // Para metinleri locale'e bağlı (bkz. money_format.dart).
    Intl.defaultLocale = 'tr_TR';
    mockDebtBloc = MockDebtBloc();
    mockReceivableBloc = MockReceivableBloc();
    mockOnboardingCoordinator = MockOnboardingCoordinator();
    getIt.registerSingleton<OnboardingCoordinator>(mockOnboardingCoordinator);
    when(() => mockOnboardingCoordinator.isSeen(any())).thenReturn(true);
  });

  tearDown(() {
    getIt.reset();
  });

  final activeDebt = DebtEntity(
    calcMode: DebtCalcMode.none,
    expectedTotalAmount: 1200.0,
    id: 'debt_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    title: 'Araba Kredisi',
    counterparty: 'Ziraat Bankası',
    type: DebtType.bankLoan,
    principalAmount: 1200.0,
    interestRate: 0.0,
    termMonths: 12,
    startDate: DateTime(2026, 1, 1),
    dueDate: DateTime(2026, 12, 1),
  );

  final activeReceivable = ReceivableEntity(
    id: 'rec_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    debtorName: 'Ahmet Yılmaz',
    amount: 500.0,
    dueDate: DateTime(2026, 6, 10),
    createdAt: DateTime(2026, 1, 1),
  );

  /// Bloc'lar MaterialApp'in ÜSTÜNDE sağlanır: ödeme diyaloğu kök
  /// Navigator'da açılır (bkz. `AppProviders`).
  Widget buildTestableWidget({required String currency}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DebtBloc>.value(value: mockDebtBloc),
        BlocProvider<ReceivableBloc>.value(value: mockReceivableBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: DebtAndReceivablePage(
          userId: 'user_1',
          walletId: 'wallet_1',
          walletCurrency: currency,
        ),
      ),
    );
  }

  testWidgets('döviz cüzdanda liste açılır, TL kısıtı görünmez',
      (tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([activeDebt]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(buildTestableWidget(currency: 'USD'));
    await tester.pumpAndSettle();

    // Eski davranışta burada bir "yalnız TL" bilgilendirmesi vardı ve liste
    // hiç kurulmazdı.
    expect(find.text('Araba Kredisi'), findsOneWidget);
    expect(find.text('1.200,00 \$'), findsOneWidget);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('alacak sekmesi de cüzdanın biriminde yazar', (tester) async {
    when(() => mockDebtBloc.state).thenReturn(const DebtLoaded([]));
    when(() => mockReceivableBloc.state)
        .thenReturn(ReceivableLoaded([activeReceivable]));

    await tester.pumpWidget(buildTestableWidget(currency: 'EUR'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alacaklarım'));
    await tester.pumpAndSettle();

    expect(find.text('Ahmet Yılmaz'), findsOneWidget);
    expect(find.text('500,00 €'), findsOneWidget);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('ödeme diyaloğu cüzdanın birimiyle açılır', (tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([activeDebt]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(buildTestableWidget(currency: 'USD'));
    await tester.pumpAndSettle();

    // Kart üzerindeki "Öde" düğmesi → DebtPaymentDialog.
    await tester.tap(find.text('Öde'));
    await tester.pumpAndSettle();

    // Diyalogdaki toplam/kalan satırları da $ ile: birim zincir boyunca akıyor.
    expect(find.text('1.200,00 \$'), findsWidgets);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('TL cüzdanda gösterim değişmez', (tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([activeDebt]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(buildTestableWidget(currency: 'TRY'));
    await tester.pumpAndSettle();

    expect(find.text('1.200,00 ₺'), findsOneWidget);
  });
}
