import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_stock_sheet.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetLiveQuoteUseCase extends Mock implements GetLiveQuoteUseCase {}

class MockHttpClientIo extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockHttpHeaders extends Mock implements HttpHeaders {}

class FakeStreamListInt extends Fake implements Stream<List<int>> {}

class TestHttpOverrides extends HttpOverrides {
  final HttpClient client;
  TestHttpOverrides(this.client);

  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

void main() {
  late MockGetLiveQuoteUseCase mockGetLiveQuoteUseCase;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(FakeStreamListInt());
  });

  setUp(() {
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
    id: 'inv_stock_edit',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Apple Inc',
    amount: 5000.0,
    currentValue: 5500.0,
    type: InvestmentType.stock,
    color: Colors.blue,
    dateAdded: DateTime(2026, 1, 1),
    symbol: 'AAPL',
    quantity: 1.0,
  );

  testWidgets('renders AddStockSheet in create mode and saves with computed price',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    InvestmentEntity? savedInvestment;
    final completer = Completer<Either<Failure, LivePriceQuote>>();

    when(() => mockGetLiveQuoteUseCase(symbol: 'THYAO.IS', type: InvestmentType.stock))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      buildTestableWidget(
        AddStockSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (inv) => savedInvestment = inv,
        ),
      ),
    );

    // Header validation
    expect(find.text('Yeni Hisse Ekle'), findsOneWidget);

    // Enters symbol
    final symbolFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Sembol (Örn: AAPL, THYAO.IS)');
    expect(symbolFinder, findsOneWidget);
    await tester.enterText(symbolFinder, 'THYAO.IS');

    // Enters quantity
    final quantityFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Adet');
    expect(quantityFinder, findsOneWidget);
    await tester.enterText(quantityFinder, '10.0');

    // Tap 'Hesapla' button
    await tester.tap(find.text('Hesapla'));
    await tester.pump(); // Start loading

    // Verify indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete quote call
    completer.complete(const Right(
      LivePriceQuote(price: 300.0, currency: 'TRY', priceTl: 300.0),
    ));
    await tester.pumpAndSettle();

    // Verify fetched price message
    expect(find.text('Güncel Fiyat: 300 ₺'), findsOneWidget);

    // Verify currentValue and amount TextFields have auto-filled '3000'
    final currentValueFinder = find.byWidgetPredicate((w) =>
        w is TextField &&
        w.decoration?.hintText == '0');
    expect(currentValueFinder, findsOneWidget);
    expect(tester.widget<TextField>(currentValueFinder).controller?.text, '3000');

    final amountFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)');
    expect(amountFinder, findsOneWidget);
    expect(tester.widget<TextField>(amountFinder).controller?.text, '3000');

    // Enter name
    final nameFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Not (İsteğe bağlı) · örn. Uzun vade alım');
    expect(nameFinder, findsOneWidget);
    await tester.enterText(nameFinder, 'Thy Hissem');

    // Tap Save button
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(savedInvestment, isNotNull);
    expect(savedInvestment!.name, 'Thy Hissem');
    expect(savedInvestment!.amount, 3000.0);
    expect(savedInvestment!.currentValue, 3000.0);
    expect(savedInvestment!.quantity, 10.0);
    expect(savedInvestment!.symbol, 'THYAO.IS');
  });

  testWidgets('validates empty inputs and handles live quote errors in AddStockSheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockGetLiveQuoteUseCase(symbol: 'AAPL', type: InvestmentType.stock))
        .thenAnswer(
      (_) async => const Left(ServerFailure('Connection Error')),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        AddStockSheet(
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
    await tester.enterText(amountFinder, '2000');
    
    // Tap Save again, now it fails on currentValue being invalid
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Geçerli bir mevcut değer girin'), findsOneWidget);

    // Now test Live Price fetch warning on empty symbol
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    expect(find.text('Sembol girin!'), findsOneWidget);

    // Enters symbol
    final symbolFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Sembol (Örn: AAPL, THYAO.IS)');
    await tester.enterText(symbolFinder, 'AAPL');

    // Tap Hesapla again to trigger fetch failure
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    expect(find.text('Fiyat alınamadı.'), findsOneWidget);
  });

  testWidgets('renders AddStockSheet in edit mode, displays correct details and updates',
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
        AddStockSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          investmentToEdit: testInvestment,
          onSave: (inv) => updatedInvestment = inv,
        ),
      ),
    );

    // Header validation
    expect(find.text('Hisse Yatırımını Düzenle'), findsOneWidget);

    // Verify initial values in TextFields
    final nameFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Not (İsteğe bağlı) · örn. Uzun vade alım');
    expect(tester.widget<TextField>(nameFinder).controller?.text, 'Apple Inc');

    final amountFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)');
    expect(tester.widget<TextField>(amountFinder).controller?.text, '5000');

    // Goal category warning should be rendered
    expect(find.text('Maliyeti değiştirirseniz fark, cüzdana düzeltme hareketi olarak işlenir.'), findsOneWidget);

    // Enter a target amount to trigger goal category selection
    final targetFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Hedef Tutar (İsteğe Bağlı)');
    await tester.enterText(targetFinder, '12000');
    await tester.pumpAndSettle();

    // Now Goal Category section should be visible
    expect(find.text('Hedef Kategorisi'), findsOneWidget);

    // Tap category chip 'Eğitim'
    await tester.tap(find.text('Eğitim'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Tap color option circle to change color (e.g. index 5 is Orange)
    final colorFinders = find.byWidgetPredicate((widget) =>
        widget is GestureDetector &&
        widget.child is AnimatedContainer);
    expect(colorFinders, findsNWidgets(8));
    await tester.tap(colorFinders.at(5));
    await tester.pumpAndSettle();

    // Save changes
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();

    expect(updatedInvestment, isNotNull);
    expect(updatedInvestment!.name, 'Apple Inc');
    expect(updatedInvestment!.amount, 5000.0);
    expect(updatedInvestment!.targetAmount, 12000.0);
    expect(updatedInvestment!.goalCategory, 'egitim');
    expect(updatedInvestment!.color, Colors.orange);
  });

  testWidgets('renders AddStockSheet and handles foreign currency conversion quote display and save',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    InvestmentEntity? savedInvestment;

    when(() => mockGetLiveQuoteUseCase(symbol: 'AAPL', type: InvestmentType.stock))
        .thenAnswer((_) async => const Right(
              LivePriceQuote(price: 150.0, currency: 'USD', priceTl: 4875.0),
            ));

    await tester.pumpWidget(
      buildTestableWidget(
        AddStockSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (inv) => savedInvestment = inv,
        ),
      ),
    );

    // Enter AAPL
    final symbolFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Sembol (Örn: AAPL, THYAO.IS)');
    await tester.enterText(symbolFinder, 'AAPL');

    // Enter quantity
    final quantityFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Adet');
    await tester.enterText(quantityFinder, '2');

    // Tap Hesapla
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();

    // Verify foreign price message shows USD and price and priceTl with approximation sign
    expect(find.text('Güncel Fiyat: 150.0 USD (≈4875.00 ₺)'), findsOneWidget);

    // Save should succeed with name field empty (which uses localized fallback "Hisse Yatırımı")
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(savedInvestment, isNotNull);
    expect(savedInvestment!.name, 'Hisse Yatırımı');
    expect(savedInvestment!.amount, 9750.0);
    expect(savedInvestment!.currentValue, 9750.0);
    expect(savedInvestment!.currency, 'USD');
  });

  testWidgets('renders AddStockSheet and handles autocomplete symbol search selection',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockHttpClient = MockHttpClientIo();
    final mockRequest = MockHttpClientRequest();
    final mockResponse = MockHttpClientResponse();
    final mockHeaders = MockHttpHeaders();

    HttpOverrides.global = TestHttpOverrides(mockHttpClient);
    addTearDown(() {
      HttpOverrides.global = null;
    });

    registerFallbackValue(Uri());

    when(() => mockHttpClient.openUrl(any(), any())).thenAnswer((_) async => mockRequest);
    when(() => mockRequest.headers).thenReturn(mockHeaders);
    when(() => mockRequest.close()).thenAnswer((_) async => mockResponse);
    when(() => mockRequest.done).thenAnswer((_) async => mockResponse);
    when(() => mockRequest.flush()).thenAnswer((_) async => null);
    when(() => mockRequest.addStream(any())).thenAnswer((_) async => null);
    when(() => mockResponse.statusCode).thenReturn(200);
    when(() => mockResponse.headers).thenReturn(mockHeaders);
    when(() => mockResponse.contentLength).thenReturn(-1);
    when(() => mockResponse.isRedirect).thenReturn(false);
    when(() => mockResponse.persistentConnection).thenReturn(false);
    when(() => mockResponse.redirects).thenReturn(<RedirectInfo>[]);
    when(() => mockResponse.reasonPhrase).thenReturn('OK');
    when(() => mockHeaders.forEach(any())).thenAnswer((_) {});

    final body = json.encode({
      'quotes': [
        {
          'symbol': 'AAPL',
          'shortname': 'Apple Inc',
          'longname': 'Apple Inc.'
        }
      ]
    });
    final bodyBytes = utf8.encode(body);
    final stream = Stream.fromIterable([bodyBytes]);
    when(() => mockResponse.listen(any(),
        cancelOnError: any(named: 'cancelOnError'),
        onDone: any(named: 'onDone'),
        onError: any(named: 'onError')
    )).thenAnswer((invocation) {
      return stream.listen(
        invocation.positionalArguments[0] as void Function(List<int>)?,
        onError: invocation.namedArguments[#onError] as Function?,
        onDone: invocation.namedArguments[#onDone] as void Function()?,
        cancelOnError: invocation.namedArguments[#cancelOnError] as bool?,
      );
    });

    await tester.pumpWidget(
      buildTestableWidget(
        AddStockSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (_) {},
        ),
      ),
    );

    // Enter 'AAP'
    final symbolFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Sembol (Örn: AAPL, THYAO.IS)');
    await tester.enterText(symbolFinder, 'AAP');
    await tester.pump(const Duration(milliseconds: 500));

    // Verify option is displayed
    expect(find.text('AAPL - Apple Inc'), findsOneWidget);

    // Tap option
    await tester.tap(find.text('AAPL - Apple Inc'));
    await tester.pumpAndSettle();

    // Verify text field now has selected text
    expect(tester.widget<TextField>(symbolFinder).controller?.text, 'AAPL - Apple Inc');

    // Verify name field auto-filled to 'Apple Inc'
    final nameFinder = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Not (İsteğe bağlı) · örn. Uzun vade alım');
    expect(tester.widget<TextField>(nameFinder).controller?.text, 'Apple Inc');
  });
}
