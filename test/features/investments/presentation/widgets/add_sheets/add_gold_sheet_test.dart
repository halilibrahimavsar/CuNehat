import 'dart:async';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_gold_sheet.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetLiveQuoteUseCase extends Mock implements GetLiveQuoteUseCase {}

/// Showcase turları getIt üzerinden koordinatörü çeker; widget testlerinde
/// gerçek koordinatör kayıtlı olmadığından mock'lanır.
class _MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  late MockGetLiveQuoteUseCase mockGetLiveQuoteUseCase;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.transactions);
    // Showcase widget'ı kayıtlı bir scope yoksa initState'te fırlatır.
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
    getIt.allowReassignment = true;
  });

  setUp(() {
    // tearDown'daki getIt.reset() kayıtları sildiğinden test başına yapılır.
    final onboardingCoordinator = _MockOnboardingCoordinator();
    when(() => onboardingCoordinator.isSeen(any())).thenReturn(true);
    when(() => onboardingCoordinator.registerKeys(any(), any()))
        .thenReturn(null);
    getIt.registerSingleton<OnboardingCoordinator>(onboardingCoordinator);
    mockGetLiveQuoteUseCase = MockGetLiveQuoteUseCase();
    getIt.registerSingleton<GetLiveQuoteUseCase>(mockGetLiveQuoteUseCase);
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
      home: Scaffold(
        body: child,
      ),
    );
  }

  final testInvestment = InvestmentEntity(
    id: 'inv_gold_edit',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Yastık Altı Altın',
    amount: 2000.0,
    currentValue: 2200.0,
    type: InvestmentType.gold,
    color: Colors.amber,
    dateAdded: DateTime(2026, 1, 1),
    symbol: 'gram-altin',
    quantity: 1.0,
  );

  testWidgets(
      'renders AddGoldSheet in create mode and saves with computed price',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    InvestmentEntity? savedInvestment;
    final completer = Completer<Either<Failure, LivePriceQuote>>();

    when(() => mockGetLiveQuoteUseCase(
        symbol: 'gram-altin',
        type: InvestmentType.gold)).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      buildTestableWidget(
        AddGoldSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (inv) => savedInvestment = inv,
        ),
      ),
    );

    // Header validation
    expect(find.text('Yeni Altın Ekle'), findsOneWidget);

    // Locate quantity textfield (hint: 'Adet')
    final quantityFinder = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.hintText == 'Adet');
    expect(quantityFinder, findsOneWidget);
    await tester.enterText(quantityFinder, '2.0');

    // Tap 'Hesapla' button
    await tester.tap(find.text('Hesapla'));
    await tester.pump(); // Start loading

    // Verify indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete quote call
    completer.complete(const Right(
      LivePriceQuote(price: 1500.0, currency: 'TRY', priceTl: 1500.0),
    ));
    await tester.pumpAndSettle();

    // Verify fetched price message
    expect(find.text('Güncel Fiyat: 1.500 ₺'), findsOneWidget);

    // Verify currentValue and amount TextFields have auto-filled '3000'
    // currentValue: has hintText: '0'
    final currentValueFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == '0');
    expect(currentValueFinder, findsOneWidget);
    expect(
        tester.widget<TextField>(currentValueFinder).controller?.text, '3.000');

    final amountFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)');
    expect(amountFinder, findsOneWidget);
    expect(tester.widget<TextField>(amountFinder).controller?.text, '3.000');

    // Enter name
    final nameFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText ==
            'Not (İsteğe bağlı) · örn. Düğün Altınları');
    expect(nameFinder, findsOneWidget);
    await tester.enterText(nameFinder, 'Yeni Birikim');

    // Tap Save button
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(savedInvestment, isNotNull);
    expect(savedInvestment!.name, 'Yeni Birikim');
    expect(savedInvestment!.amount, 3000.0);
    expect(savedInvestment!.currentValue, 3000.0);
    expect(savedInvestment!.quantity, 2.0);
    expect(savedInvestment!.symbol, 'gram-altin');
  });

  testWidgets('validates empty inputs and handles live quote errors',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockGetLiveQuoteUseCase(
        symbol: 'gram-altin', type: InvestmentType.gold)).thenAnswer(
      (_) async => const Left(ServerFailure('Connection Error')),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        AddGoldSheet(
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

    // Enter valid amount but clear current value
    final amountFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)');
    await tester.enterText(amountFinder, '1000');

    // Tap Save again, now it fails on currentValue being invalid
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Geçerli bir mevcut değer girin'), findsOneWidget);

    // Now test Live Price fetch failure
    final quantityFinder = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.hintText == 'Adet');
    await tester.enterText(quantityFinder, '1.5');
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();

    // Verify error message from live price fetch failure
    expect(find.text('Fiyat alınamadı.'), findsOneWidget);
  });

  testWidgets(
      'renders AddGoldSheet in edit mode, displays correct details and updates',
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
        AddGoldSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          investmentToEdit: testInvestment,
          onSave: (inv) => updatedInvestment = inv,
        ),
      ),
    );

    // Header validation
    expect(find.text('Altın Yatırımını Düzenle'), findsOneWidget);

    // Verify initial values in TextFields
    final nameFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText ==
            'Not (İsteğe bağlı) · örn. Düğün Altınları');
    expect(tester.widget<TextField>(nameFinder).controller?.text,
        'Yastık Altı Altın');

    final amountFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)');
    expect(tester.widget<TextField>(amountFinder).controller?.text, '2.000');

    // Goal category warning should be rendered
    expect(
        find.text(
            'Maliyeti değiştirirseniz fark, cüzdana düzeltme hareketi olarak işlenir.'),
        findsOneWidget);

    // Enter a target amount to trigger goal category selection
    final targetFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Hedef Tutar (İsteğe Bağlı)');
    await tester.enterText(targetFinder, '10000');
    await tester.pumpAndSettle();

    // Now Goal Category section should be visible
    expect(find.text('Hedef Kategorisi'), findsOneWidget);

    // Tap category chip 'Araba'
    await tester.tap(find.text('Araba'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Tap color option circle to change color (e.g. Colors.blue)
    final colorFinders = find.byWidgetPredicate((widget) =>
        widget is GestureDetector && widget.child is AnimatedContainer);
    expect(colorFinders, findsNWidgets(8));
    await tester.tap(colorFinders.at(3)); // index 3 is Colors.blue
    await tester.pumpAndSettle();

    // Save changes
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();

    expect(updatedInvestment, isNotNull);
    expect(updatedInvestment!.name, 'Yastık Altı Altın');
    expect(updatedInvestment!.amount, 2000.0);
    expect(updatedInvestment!.targetAmount, 10000.0);
    expect(updatedInvestment!.goalCategory, 'araba');
    expect(updatedInvestment!.color, Colors.blue);
  });
}
