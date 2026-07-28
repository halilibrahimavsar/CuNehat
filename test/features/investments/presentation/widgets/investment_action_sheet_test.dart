import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Showcase turları getIt üzerinden koordinatörü çeker; widget testlerinde
/// gerçek koordinatör kayıtlı olmadığından mock'lanır.
class _MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.transactions);
    // Showcase widget'ı kayıtlı bir scope yoksa initState'te fırlatır.
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  setUp(() {
    // tearDown'daki getIt.reset() kayıtları sildiğinden test başına yapılır.
    final onboardingCoordinator = _MockOnboardingCoordinator();
    when(() => onboardingCoordinator.isSeen(any())).thenReturn(true);
    getIt.registerSingleton<OnboardingCoordinator>(onboardingCoordinator);
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
      home: Scaffold(
        body: child,
      ),
    );
  }

  final goldGoalInvestment = InvestmentEntity(
    id: 'inv_gold',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Çeyrek Altın',
    amount: 1000.0,
    currentValue: 1000.0,
    type: InvestmentType.gold,
    color: Colors.amber,
    dateAdded: DateTime(2026, 1, 1),
    symbol: 'XAU',
    quantity: 0.5,
    targetAmount: 5000.0, // isGoal = true
  );

  final stockNonRefreshableInvestment = InvestmentEntity(
    id: 'inv_stock',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'BIST Hisse',
    amount: 2000.0,
    currentValue: 2000.0,
    type: InvestmentType.stock,
    color: Colors.blue,
    dateAdded: DateTime(2026, 1, 1),
    symbol: null,
    quantity: null,
  );

  testWidgets('renders correct action sheet options for gold goal investment',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentActionSheet(investment: goldGoalInvestment),
      ),
    );

    // Verify Title & Header
    expect(find.text('Çeyrek Altın'), findsOneWidget);
    expect(find.byIcon(Icons.monetization_on_rounded), findsOneWidget);

    // Verify Action: Hedefe Para Ekle (since isGoal is true and symbol is XAU)
    // Wait, in build:
    // title: investment.symbol != null
    //    ? context.l10n.varlikEkle
    //    : (investment.isGoal ? context.l10n.hedefeParaEkle : context.l10n.paraEkle),
    // Since symbol is NOT null (XAU), it should render varlikEkle ("Varlık Ekle")
    expect(find.text('Varlık Ekle'), findsOneWidget);

    // Verify action: Fiyatı Güncelle (since canRefreshPrice is true)
    expect(find.text('Fiyatı Güncelle'), findsOneWidget);

    // Verify other options
    expect(find.text('Düzenle'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);
    expect(find.text('Kaydı Sil'), findsOneWidget);
  });

  testWidgets('renders action sheet options for stock without symbol',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentActionSheet(investment: stockNonRefreshableInvestment),
      ),
    );

    expect(find.text('BIST Hisse'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);

    // Since symbol is null and isGoal is false, it should show context.l10n.paraEkle ("Para Ekle")
    expect(find.text('Para Ekle'), findsOneWidget);

    // Since canRefreshPrice is false, it should NOT show Fiyatı Güncelle
    expect(find.text('Fiyatı Güncelle'), findsNothing);
  });

  testWidgets('tapping options pops with correct InvestmentAction',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    InvestmentAction? selectedAction;

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                selectedAction = await InvestmentActionSheet.show(
                  context,
                  investment: goldGoalInvestment,
                );
              },
              child: const Text('Show Sheet'),
            );
          },
        ),
      ),
    );

    // Open action sheet
    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    // Verify open
    expect(find.byType(InvestmentActionSheet), findsOneWidget);

    // Tap 'Sat'
    await tester.tap(find.text('Sat'));
    await tester.pumpAndSettle();

    // Verify popped with InvestmentAction.sell
    expect(find.byType(InvestmentActionSheet), findsNothing);
    expect(selectedAction, InvestmentAction.sell);
  });
}
