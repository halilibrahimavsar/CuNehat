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
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';

class MockGetLiveQuoteUseCase extends Mock implements GetLiveQuoteUseCase {}

/// Showcase turları getIt üzerinden koordinatörü çeker; widget testlerinde
/// gerçek koordinatör kayıtlı olmadığından mock'lanır.
class _MockOnboardingCoordinator extends Mock
    implements OnboardingCoordinator {}

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

  late MockGetLiveQuoteUseCase mockGetLiveQuoteUseCase;

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
        type: InvestmentType.gold,
        targetCurrency: 'TRY')).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      buildTestableWidget(
        AddGoldSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
          onSave: (inv) => savedInvestment = inv,
        ),
      ),
    );

    // Header validation
    expect(find.text('Yeni Altın Ekle'), findsOneWidget);

    // Locate quantity textfield (hint: 'Adet')
    final quantityFinder = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.hintText == 'Gram Altın');
    expect(quantityFinder, findsOneWidget);
    await tester.enterText(quantityFinder, '2.0');

    // Tap 'Hesapla' button
    await tester.tap(find.text('Hesapla'));
    await tester.pump(); // Start loading

    // Verify indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete quote call
    completer.complete(const Right(
      LivePriceQuote(
          price: 1500.0,
          currency: 'TRY',
          convertedPrice: 1500.0,
          targetCurrency: 'TRY'),
    ));
    await tester.pumpAndSettle();

    // Verify fetched price message
    expect(find.text('Güncel Fiyat: 1.500,00 ₺'), findsOneWidget);

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
        symbol: 'gram-altin',
        type: InvestmentType.gold,
        targetCurrency: 'TRY')).thenAnswer(
      (_) async => const Left(ServerFailure('Connection Error')),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        AddGoldSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
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
        widget is TextField && widget.decoration?.hintText == 'Gram Altın');
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
          walletCurrency: 'TRY',
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
    expect(updatedInvestment!.color, Colors.blue);
  });

  // Tur adımları kapanı: altın/hisse sheet'lerinde üç adım da ağaçta olmalı.
  testWidgets('turun üç adımı da ağaçta', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      AddGoldSheet(
        walletId: 'wallet_123',
        userId: 'user_123',
        walletCurrency: 'TRY',
        onSave: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    final showcase = ShowcaseView.get();
    expect(showcase.isTargetRendered(OnboardingKeys.investmentAddForm), isTrue);
    expect(showcase.isTargetRendered(OnboardingKeys.investmentAddCost), isTrue);
    expect(showcase.isTargetRendered(OnboardingKeys.investmentAddQuantity),
        isTrue);
  });

  testWidgets('"zaten bende" seçilince maliyet deftere işlenmez',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    InvestmentEntity? saved;
    await tester.pumpWidget(
      buildTestableWidget(
        AddGoldSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
          onSave: (inv) => saved = inv,
        ),
      ),
    );

    // Mevcut değer ve maliyet.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '5.000');
    await tester.enterText(fields.at(1), '4.000');
    await tester.pumpAndSettle();

    // Varsayılan: tamamı cüzdandan düşülür.
    expect(find.textContaining('cüzdandan düşülecek'), findsOneWidget);

    final switchFinder = find.byType(SwitchListTile);
    await tester.ensureVisible(switchFinder);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Cüzdandan para düşülmeyecek; kayıt yalnız portföye eklenir.'),
        findsOneWidget);

    final saveButton = find.text('Kaydet');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.amount, 4000.0);
    // Maliyetin tamamı işlenmemiş → deftere gider yazılmaz, silmede de
    // iade edilecek bir şey yoktur.
    expect(saved!.unbookedCost, 4000.0);
    expect(saved!.bookedCost, 0.0);
  });

  testWidgets('düzenlemede alım tarihi/zaten bende satırı gösterilmez',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestableWidget(
        AddGoldSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
          investmentToEdit: testInvestment,
          onSave: (_) {},
        ),
      ),
    );

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.textContaining('Alım tarihi'), findsNothing);
  });

  testWidgets('düzenlemede altın türü değişirse miktar uyarısı çıkar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestableWidget(
        AddGoldSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
          investmentToEdit: testInvestment,
          onSave: (_) {},
        ),
      ),
    );

    expect(find.textContaining('Tür değişiyor'), findsNothing);

    final dropdown = find.byType(DropdownButton<String>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çeyrek Altın').last);
    await tester.pumpAndSettle();

    // 1 gram sessizce 1 çeyreğe dönüşmesin: uyarı kaydetmeden önce görünür.
    expect(find.textContaining('kayıttaki 1 miktarı bundan sonra Çeyrek Altın'),
        findsOneWidget);
  });

  testWidgets('maliyet ve değer birlikte sıfırsa boş kayıt reddedilir',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    InvestmentEntity? saved;
    await tester.pumpWidget(
      buildTestableWidget(
        AddGoldSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
          onSave: (inv) => saved = inv,
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '0');
    await tester.enterText(fields.at(1), '0');
    await tester.pumpAndSettle();

    final saveButton = find.text('Kaydet');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(saved, isNull);
    expect(
        find.text(
            'Maliyet ya da mevcut değerden en az biri sıfırdan büyük olmalı'),
        findsOneWidget);
  });

  testWidgets('düzenlemede miktar alanı boşaltılırsa miktar silinir',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    InvestmentEntity? saved;
    await tester.pumpWidget(
      buildTestableWidget(
        AddGoldSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
          investmentToEdit: testInvestment,
          onSave: (inv) => saved = inv,
        ),
      ),
    );

    final quantityField = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.hintText == 'Gram Altın');
    await tester.ensureVisible(quantityField);
    await tester.enterText(quantityField, '');
    await tester.pumpAndSettle();

    final saveButton = find.text('Güncelle');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.quantity, isNull);
  });

  testWidgets('geçmiş tarihli alımda mevcut değer uyarısı ve kısayol çıkar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockGetLiveQuoteUseCase(
        symbol: 'gram-altin',
        type: InvestmentType.gold,
        targetCurrency: 'TRY')).thenAnswer(
      (_) async => const Right(LivePriceQuote(
        price: 2500.0,
        currency: 'TRY',
        convertedPrice: 2500.0,
        targetCurrency: 'TRY',
      )),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        AddGoldSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
          onSave: (_) {},
        ),
      ),
    );

    // Bugün seçiliyken uyarı yok.
    expect(find.textContaining('BUGÜNKÜ değerdir'), findsNothing);

    // Takvimden dünü seç.
    final dateField = find.textContaining('Alım tarihi:');
    await tester.ensureVisible(dateField);
    await tester.tap(dateField);
    await tester.pumpAndSettle();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await tester.tap(find.text('${yesterday.day}').last);
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(find.textContaining('BUGÜNKÜ değerdir'), findsOneWidget);

    // Kısayol miktar × güncel fiyattan bugünkü değeri yazar.
    final quantityField = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.hintText == 'Gram Altın');
    await tester.ensureVisible(quantityField);
    await tester.enterText(quantityField, '2');
    await tester.pumpAndSettle();

    final shortcut = find.text('Bugünkü değeri hesapla');
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pumpAndSettle();

    final currentValueField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == '0');
    expect(
      tester.widget<TextField>(currentValueField).controller?.text,
      '5.000',
    );
  });
}
