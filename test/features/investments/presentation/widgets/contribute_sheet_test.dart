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
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';

class MockGetLiveQuoteUseCase extends Mock implements GetLiveQuoteUseCase {}

class _MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

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

  final goldInvestment = InvestmentEntity(
    id: 'inv_gold',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Altın Birikimi',
    amount: 4000.0,
    currentValue: 4400.0,
    type: InvestmentType.gold,
    color: Colors.amber,
    dateAdded: DateTime(2026, 1, 1),
    symbol: 'gram-altin',
    quantity: 2.0,
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
          walletCurrency: 'TRY',
          onSave: (inv, _) => savedInvestment = inv,
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
    when(() => mockGetLiveQuoteUseCase(
        symbol: 'XAU',
        type: InvestmentType.gold,
        targetCurrency: 'TRY')).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      buildTestableWidget(
        ContributeSheet(
          investment: assetInvestment,
          walletCurrency: 'TRY',
          onSave: (inv, _) => savedInvestment = inv,
        ),
      ),
    );

    expect(find.text('Gram Altın · Varlık Ekle'), findsOneWidget);

    // Alanlar: miktar, birim alış fiyatı, ödenen tutar.
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(3));

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
      LivePriceQuote(
          price: 1800.0,
          currency: 'TRY',
          convertedPrice: 1800.0,
          targetCurrency: 'TRY'),
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
    when(() => mockGetLiveQuoteUseCase(
        symbol: 'XAU',
        type: InvestmentType.gold,
        targetCurrency: 'TRY')).thenAnswer(
      (_) async => const Left(ServerFailure('Connection Error')),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        ContributeSheet(
          investment: assetInvestment,
          walletCurrency: 'TRY',
          onSave: (_, __) {},
        ),
      ),
    );

    // Tap Live Price Button
    await tester.tap(find.text('Güncel Fiyatı Getir'));
    await tester.pumpAndSettle();

    expect(find.text('Fiyat alınamadı.'), findsOneWidget);
  });

  testWidgets('farklı altın türü seçilince katkı yerine yeni kayıt sunulur',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    String? requestedType;
    InvestmentEntity? saved;

    await tester.pumpWidget(
      buildTestableWidget(
        ContributeSheet(
          investment: goldInvestment,
          walletCurrency: 'TRY',
          onSave: (inv, _) => saved = inv,
          onCreateForGoldType: (type) => requestedType = type,
        ),
      ),
    );

    // Kaydın kendi türünde form açık.
    expect(find.text('Ekle'), findsOneWidget);
    expect(find.text('Bu birikim Gram Altın cinsinden takip ediliyor.'),
        findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çeyrek Altın').last);
    await tester.pumpAndSettle();

    // Form kapanır: bu kayda çeyrek eklenemez.
    expect(find.text('Çeyrek Altın bu kayda eklenemez'), findsOneWidget);
    expect(find.text('Ekle'), findsNothing);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Çeyrek Altın için yeni kayıt aç'));
    await tester.pumpAndSettle();

    expect(requestedType, 'ceyrek-altin');
    expect(saved, isNull, reason: 'karışık birimle kayıt güncellenmemeli');
  });

  testWidgets('tutar kipi güncel fiyat olmadan kaydetmez',
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
        ContributeSheet(
          investment: goldInvestment,
          walletCurrency: 'TRY',
          onSave: (inv, _) => saved = inv,
        ),
      ),
    );

    await tester.tap(find.text('Tutar ile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '5.000');
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    expect(saved, isNull);
    expect(find.text('Tutarı miktara çevirmek için önce güncel fiyatı getir.'),
        findsOneWidget);
  });

  testWidgets('tutar kipi yatırılan parayı güncel fiyattan miktara çevirir',
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

    InvestmentEntity? saved;
    await tester.pumpWidget(
      buildTestableWidget(
        ContributeSheet(
          investment: goldInvestment,
          walletCurrency: 'TRY',
          onSave: (inv, _) => saved = inv,
        ),
      ),
    );

    await tester.tap(find.text('Tutar ile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '5.000');
    await tester.tap(find.text('Güncel Fiyatı Getir'));
    await tester.pumpAndSettle();

    // 5.000 / 2.500 = 2 gram eklenecek.
    expect(find.text('≈ 2 Gram Altın eklenecek'), findsOneWidget);

    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.quantity, 4.0); // 2 + 2
    expect(saved!.amount, 9000.0); // 4000 + 5000
    expect(saved!.currentValue, 10000.0); // 4 × 2500
  });

  testWidgets('miktar kipinde ödenen boşsa hediye uyarısı görünür',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestableWidget(
        ContributeSheet(
          investment: goldInvestment,
          walletCurrency: 'TRY',
          onSave: (_, __) {},
        ),
      ),
    );

    expect(find.textContaining('bedelsiz (hediye) sayılacak'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '1');
    await tester.pumpAndSettle();

    expect(find.textContaining('bedelsiz (hediye) sayılacak'), findsOneWidget);
  });

  testWidgets('fiyat miktardan ÖNCE çekilse de ödenen tutar önerilir',
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

    InvestmentEntity? saved;
    await tester.pumpWidget(
      buildTestableWidget(
        ContributeSheet(
          investment: goldInvestment,
          walletCurrency: 'TRY',
          onSave: (inv, _) => saved = inv,
        ),
      ),
    );

    // Kullanıcının doğal sırası: önce fiyata bak, sonra miktarı yaz.
    await tester.tap(find.text('Güncel Fiyatı Getir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '2');
    await tester.pumpAndSettle();

    // Ödenen alanı kendiliğinden dolar; alım sessizce hediyeye dönmez.
    expect(find.textContaining('bedelsiz (hediye) sayılacak'), findsNothing);

    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.quantity, 4.0);
    expect(saved!.amount, 9000.0, reason: '2 × 2.500 maliyete eklenmeli');
  });

  // Faz 2 (23 Eyl 2026): katkının ödemesi ekstreden defterde zaten
  // duruyorsa o satır seçilir; tutar ondan gelir, yeni gider yazılmaz.
  testWidgets('katkı: "ödemesi defterde var" → satır seçilir, tutar kilitlenir',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final row = TransactionEntity(
      id: 'row-7',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'BES KATKI PAYI',
      tag: 'cat-yatirim',
      amount: 750,
      date: DateTime(2026, 9, 3),
      type: TransactionTypeModel.expense,
    );
    final repo = _MockTransactionsRepository();
    when(() => repo.getTransactions(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async => Right([row]));
    getIt.registerSingleton<TransactionsRepository>(repo);

    InvestmentEntity? saved;
    CashSource? source;
    await tester.pumpWidget(buildTestableWidget(ContributeSheet(
      investment: cashInvestment,
      walletCurrency: 'TRY',
      onSave: (inv, cash) {
        saved = inv;
        source = cash;
      },
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ödemesi defterde zaten var — satırı seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BES KATKI PAYI'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.readOnly, isTrue);
    expect(field.controller!.text, contains('750'));

    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    expect(saved!.amount, 1750, reason: '1.000 + 750');
    expect(source, isA<AdoptedCashMovement>());
    expect((source! as AdoptedCashMovement).transaction.id, 'row-7');
  });

  testWidgets(
      '"Bağla…" akışından: satır önceden seçili, tutar ondan ve kilitli',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final row = TransactionEntity(
      id: 'row-8',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'BES KATKI PAYI',
      tag: 'cat-yatirim',
      amount: 750,
      date: DateTime(2026, 9, 3),
      type: TransactionTypeModel.expense,
    );

    InvestmentEntity? saved;
    CashSource? source;
    await tester.pumpWidget(buildTestableWidget(ContributeSheet(
      investment: cashInvestment,
      walletCurrency: 'TRY',
      initialLedgerTransaction: row,
      onSave: (inv, cash) {
        saved = inv;
        source = cash;
      },
    )));
    await tester.pumpAndSettle();

    // Seçici açılmadan satır hazır: kullanıcı satırdan geldi.
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.readOnly, isTrue);
    expect(field.controller!.text, contains('750'));
    expect(find.textContaining('BES KATKI PAYI'), findsOneWidget);

    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    expect(saved!.amount, 1750);
    expect(source, isA<AdoptedCashMovement>());
    expect((source! as AdoptedCashMovement).transaction.id, 'row-8');
  });

  group('birim alış fiyatı (miktar kipi)', () {
    final unitField = find.byKey(const ValueKey('contribute-unit-price'));
    TextField paidField(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField).last);

    Future<void> pumpSheet(
        WidgetTester tester, void Function(InvestmentEntity) onSave) async {
      await tester.pumpWidget(buildTestableWidget(ContributeSheet(
        investment: assetInvestment,
        walletCurrency: 'TRY',
        onSave: (inv, _) => onSave(inv),
      )));
      await tester.pump();
    }

    testWidgets('miktar × birim fiyat ödenen tutarı doldurur ve maliyete girer',
        (tester) async {
      InvestmentEntity? saved;
      await pumpSheet(tester, (inv) => saved = inv);

      await tester.enterText(find.byType(TextField).first, '2');
      await tester.enterText(unitField, '1.750,5');
      await tester.pump();
      expect(paidField(tester).controller!.text, '3.501');

      // Miktar değişince tutar birim fiyattan yeniden çarpılır.
      await tester.enterText(find.byType(TextField).first, '3');
      await tester.pump();
      expect(paidField(tester).controller!.text, '5.251,5');

      await tester.tap(find.text('Ekle'));
      await tester.pumpAndSettle();
      expect(saved!.quantity, 4.5);
      expect(saved!.amount, 2500 + 5251.5);
    });

    testWidgets('ödenen elle yazılınca birim fiyat ondan türer',
        (tester) async {
      await pumpSheet(tester, (_) {});

      await tester.enterText(find.byType(TextField).first, '4');
      await tester.enterText(find.byType(TextField).last, '1000');
      await tester.pump();

      expect(tester.widget<TextField>(unitField).controller!.text, '250');
    });
  });
}
