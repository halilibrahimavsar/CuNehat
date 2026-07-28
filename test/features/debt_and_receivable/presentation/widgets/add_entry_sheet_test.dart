import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtBloc extends Mock implements DebtBloc {}
class MockReceivableBloc extends Mock implements ReceivableBloc {}
class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  late MockDebtBloc mockDebtBloc;
  late MockReceivableBloc mockReceivableBloc;
  late MockOnboardingCoordinator mockOnboardingCoordinator;

  setUpAll(() {
    registerFallbackValue(OnboardingFlow.debtAdd);
    // Showcase scope'u global kayıtla verilir (ShowCaseWidget kullanımdan kalktı).
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
    registerFallbackValue(DebtInitial());
    registerFallbackValue(ReceivableInitial());
  });

  setUp(() {
    mockDebtBloc = MockDebtBloc();
    mockReceivableBloc = MockReceivableBloc();
    mockOnboardingCoordinator = MockOnboardingCoordinator();

    when(() => mockDebtBloc.state).thenReturn(DebtInitial());
    when(() => mockReceivableBloc.state).thenReturn(ReceivableInitial());
    when(() => mockOnboardingCoordinator.isSeen(any())).thenReturn(true);

    if (GetIt.I.isRegistered<OnboardingCoordinator>()) {
      GetIt.I.unregister<OnboardingCoordinator>();
    }
    GetIt.I.registerSingleton<OnboardingCoordinator>(mockOnboardingCoordinator);
  });

  tearDown(() {
    if (GetIt.I.isRegistered<OnboardingCoordinator>()) {
      GetIt.I.unregister<OnboardingCoordinator>();
    }
  });


  Widget buildTestableWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DebtBloc>.value(value: mockDebtBloc),
        BlocProvider<ReceivableBloc>.value(value: mockReceivableBloc),
      ],
      child: MaterialApp(
        // Metin bazlı beklentiler sabit kalsın diye dil sabitlenir.
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders AddEntrySheet for debt addition successfully', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
        walletId: 'w1',
        userId: 'u1',
        initialIsDebt: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AddEntrySheet), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('renders AddEntrySheet for receivable addition successfully', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
        walletId: 'w1',
        userId: 'u1',
        initialIsDebt: false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AddEntrySheet), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  // ------------------------------------------------- Refactor koruma testleri
  // Aşağıdakiler add_entry/* widget'larına bölünen davranışı sabitler: tutar
  // kartındaki canlı geri ödeme özeti ve tür-özel dinamik alanlar.

  testWidgets('banka kredisinde canlı geri ödeme özeti hesaplanır',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(walletId: 'w1', userId: 'u1', initialIsDebt: true),
    ));
    await tester.pumpAndSettle();

    // Varsayılan tür bankLoan; özet kartı tutar girilmeden "—" gösterir.
    expect(find.text('—'), findsWidgets);

    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    final amountField = find.byType(TextField).first;
    await tester.enterText(amountField, '12000');
    await tester.pumpAndSettle();

    // Tutar girilince toplam geri ödeme satırı gerçek bir değere döner.
    expect(find.text(l10n.toplamGeriOdeme), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AddEntrySheet),
        matching: find.textContaining('12.000'),
      ),
      findsWidgets,
    );
  });

  testWidgets('kişisel borçta vade/detay alanları gizlenir', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(walletId: 'w1', userId: 'u1', initialIsDebt: true),
    ));
    await tester.pumpAndSettle();

    // bankLoan modunda vade alanı görünür.
    expect(find.text(l10n.vadeAyHint), findsOneWidget);

    await tester.tap(find.text(l10n.debtTypePersonal));
    await tester.pumpAndSettle();

    // personalDebt'te tür-özel alanlar ve geri ödeme özeti kaldırılır.
    expect(find.text(l10n.vadeAyHint), findsNothing);
    expect(find.text(l10n.toplamGeriOdeme), findsNothing);
  });

  testWidgets('alacak formunda borç-özel alanlar hiç gösterilmez',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(walletId: 'w1', userId: 'u1', initialIsDebt: false),
    ));
    await tester.pumpAndSettle();

    expect(find.text(l10n.alacakTutari), findsOneWidget);
    expect(find.text(l10n.borcTuruLabel), findsNothing);
    expect(find.text(l10n.toplamGeriOdeme), findsNothing);
  });
}
