import 'dart:async';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/presentation/widgets/contribute_sheet.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';

class MockGetLiveQuoteUseCase extends Mock implements GetLiveQuoteUseCase {}

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

  late MockGetLiveQuoteUseCase mockGetLiveQuoteUseCase;

  setUpAll(() {
    getIt.allowReassignment = true;
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

  final cashInvestment = InvestmentEntity(
    id: 'inv_cash',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Bireysel Emeklilik',
    amount: 1000.0,
    currentValue: 1000.0,
    type: InvestmentType.custom,
    color: Colors.teal,
    dateAdded: DateTime(2026, 1, 1),
  );

  final assetInvestment = InvestmentEntity(
    id: 'inv_asset',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Gram Altın',
    amount: 2500.0,
    currentValue: 2500.0,
    type: InvestmentType.gold,
    color: Colors.amber,
    dateAdded: DateTime(2026, 1, 1),
    symbol: 'XAU',
    quantity: 1.5,
  );

  testWidgets(
      'renders ContributeSheet in Cash Mode (no symbol) and validates input',
      (WidgetTester tester) async {
    InvestmentEntity? savedInvestment;

    await tester.pumpWidget(
      buildTestableWidget(
        ContributeSheet(
          investment: cashInvestment,
          onSave: (inv) => savedInvestment = inv,
        ),
      ),
    );

    expect(find.text('Bireysel Emeklilik · Para Ekle'), findsOneWidget);
    expect(find.text('Miktar'),
        findsNothing); // Quantity field not rendered in cash mode

    // Tap Ekle without input to verify validation error
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Geçerli bir tutar girin'), findsOneWidget);

    // Enter valid amount
    final amountField = find.byType(TextField);
    await tester.enterText(amountField, '500');
    await tester.pumpAndSettle();

    // Tap Ekle
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    // Verify it updates cash investment and calls onSave
    expect(savedInvestment, isNotNull);
    expect(savedInvestment!.amount, 1500.0);
    expect(savedInvestment!.currentValue, 1500.0);
  });

  testWidgets(
      'renders ContributeSheet in Asset Mode (with symbol), fetches live price and saves',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    InvestmentEntity? savedInvestment;

    final completer = Completer<Either<Failure, LivePriceQuote>>();
    when(() =>
            mockGetLiveQuoteUseCase(symbol: 'XAU', type: InvestmentType.gold))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      buildTestableWidget(
        ContributeSheet(
          investment: assetInvestment,
          onSave: (inv) => savedInvestment = inv,
        ),
      ),
    );

    expect(find.text('Gram Altın · Varlık Ekle'), findsOneWidget);

    // Locate TextFields: Quantity and Amount
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    final quantityField = textFields.first;

    // Enter invalid quantity and check validation
    await tester.enterText(quantityField, '0');
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Geçerli bir miktar girin'), findsOneWidget);

    // Enter valid quantity: 0.5 units
    await tester.enterText(quantityField, '0.5');
    await tester.pumpAndSettle();

    // Tap Live Price Button
    await tester.tap(find.text('Güncel Fiyatı Getir'));
    await tester.pump(); // Start fetching

    // Check loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete the live price fetch
    completer.complete(const Right(
      LivePriceQuote(price: 1800.0, currency: 'TRY', priceTl: 1800.0),
    ));
    await tester.pumpAndSettle(); // Settle live price response

    // Verify price message and amount autofill (0.5 * 1800 = 900)
    expect(find.text('Güncel Fiyat: 1.800,00 ₺'), findsOneWidget);

    // Tap Ekle
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    expect(savedInvestment, isNotNull);
    // Quantity: 1.5 + 0.5 = 2.0
    // Amount (cost): 2500 + 900 = 3400
    // CurrentValue: quantity * livePrice = 2.0 * 1800 = 3600
    expect(savedInvestment!.quantity, 2.0);
    expect(savedInvestment!.amount, 3400.0);
    expect(savedInvestment!.currentValue, 3600.0);
  });

  testWidgets('handles live price quote failure gracefully',
      (WidgetTester tester) async {
    when(() =>
            mockGetLiveQuoteUseCase(symbol: 'XAU', type: InvestmentType.gold))
        .thenAnswer(
      (_) async => const Left(ServerFailure('Connection Error')),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        ContributeSheet(
          investment: assetInvestment,
          onSave: (_) {},
        ),
      ),
    );

    // Tap Live Price Button
    await tester.tap(find.text('Güncel Fiyatı Getir'));
    await tester.pumpAndSettle();

    expect(find.text('Fiyat alınamadı.'), findsOneWidget);
  });
}
