import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_custom_sheet.dart';
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
    when(() => onboardingCoordinator.registerKeys(any(), any()))
        .thenReturn(null);
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

  final testInvestment = InvestmentEntity(
    id: 'inv_custom_edit',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Bireysel Emeklilik',
    amount: 3000.0,
    currentValue: 3500.0,
    type: InvestmentType.custom,
    color: Colors.purple,
    dateAdded: DateTime(2026, 1, 1),
  );

  testWidgets('renders AddCustomSheet in create mode and saves successfully',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    InvestmentEntity? savedInvestment;

    await tester.pumpWidget(
      buildTestableWidget(
        AddCustomSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (inv) => savedInvestment = inv,
        ),
      ),
    );

    // Header validation
    expect(find.text('Yeni Özel Yatırım Ekle'), findsOneWidget);

    // Enter currentValue
    final currentValueFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == '0');
    expect(currentValueFinder, findsOneWidget);
    await tester.enterText(currentValueFinder, '4500');

    // Enter cost (amount)
    final amountFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)');
    expect(amountFinder, findsOneWidget);
    await tester.enterText(amountFinder, '4000');

    // Enter name
    final nameFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText ==
            'Not (İsteğe bağlı) · örn. Arsa, Kripto, Döviz');
    expect(nameFinder, findsOneWidget);
    await tester.enterText(nameFinder, 'Kripto Sepetim');

    // Tap Save button
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(savedInvestment, isNotNull);
    expect(savedInvestment!.name, 'Kripto Sepetim');
    expect(savedInvestment!.amount, 4000.0);
    expect(savedInvestment!.currentValue, 4500.0);
    expect(savedInvestment!.type, InvestmentType.custom);
  });

  testWidgets('validates empty inputs and errors in AddCustomSheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestableWidget(
        AddCustomSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (_) {},
        ),
      ),
    );

    // Tap Save button immediately to trigger validation
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    // Verify validation error
    expect(find.text('Geçerli bir yatırım miktarı girin'), findsOneWidget);

    // Enter valid amount but clear/invalid current value
    final amountFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)');
    await tester.enterText(amountFinder, '2000');

    // Tap Save again, now it fails on currentValue being invalid
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Geçerli bir mevcut değer girin'), findsOneWidget);

    // Enter valid currentValue
    final currentValueFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == '0');
    await tester.enterText(currentValueFinder, '2200');

    // Geçersiz hedef tutar → doğrulama hatası. AmountInputFormatter
    // allowNegative:false olduğundan '-' zaten yazılamıyor; sıfır bu alanda
    // hâlâ geçersizdir (bkz. AddCustomSheet doğrulaması: targetAmount <= 0).
    final targetFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Hedef Tutar (İsteğe Bağlı)');
    await tester.enterText(targetFinder, '0');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Geçerli bir hedef tutar girin'), findsOneWidget);
  });

  testWidgets(
      'renders AddCustomSheet in edit mode, displays correct details and updates',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    InvestmentEntity? updatedInvestment;

    await tester.pumpWidget(
      buildTestableWidget(
        AddCustomSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          investmentToEdit: testInvestment,
          onSave: (inv) => updatedInvestment = inv,
        ),
      ),
    );

    // Header validation
    expect(find.text('Özel Yatırımını Düzenle'), findsOneWidget);

    // Verify initial values in TextFields
    final nameFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText ==
            'Not (İsteğe bağlı) · örn. Arsa, Kripto, Döviz');
    expect(tester.widget<TextField>(nameFinder).controller?.text,
        'Bireysel Emeklilik');

    final amountFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)');
    expect(tester.widget<TextField>(amountFinder).controller?.text, '3.000');

    // Goal category warning should be rendered
    expect(
        find.text(
            'Maliyeti değiştirirseniz fark, cüzdana düzeltme hareketi olarak işlenir.'),
        findsOneWidget);

    // Enter a target amount to trigger goal category selection
    final targetFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Hedef Tutar (İsteğe Bağlı)');
    await tester.enterText(targetFinder, '15000');
    await tester.pumpAndSettle();

    // Now Goal Category section should be visible
    expect(find.text('Hedef Kategorisi'), findsOneWidget);

    // Tap category chip 'Acil Fon'
    await tester.tap(find.text('Acil Fon'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Tap color option circle to change color (e.g. index 5 is Teal)
    final colorFinders = find.byWidgetPredicate((widget) =>
        widget is GestureDetector && widget.child is AnimatedContainer);
    expect(colorFinders, findsNWidgets(8));
    await tester.tap(colorFinders.at(5));
    await tester.pumpAndSettle();

    // Save changes
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();

    expect(updatedInvestment, isNotNull);
    expect(updatedInvestment!.name, 'Bireysel Emeklilik');
    expect(updatedInvestment!.amount, 3000.0);
    expect(updatedInvestment!.targetAmount, 15000.0);
    expect(updatedInvestment!.goalCategory, 'acil_fon');
    expect(updatedInvestment!.color, Colors.teal);
  });
}
