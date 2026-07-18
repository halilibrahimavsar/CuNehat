import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_money_page.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_action_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInvestmentBloc extends MockBloc<InvestmentEvent, InvestmentState>
    implements InvestmentBloc {}

class MockGetLiveQuoteUseCase extends Mock implements GetLiveQuoteUseCase {}

void main() {
  late MockInvestmentBloc mockInvestmentBloc;
  late MockGetLiveQuoteUseCase mockGetLiveQuoteUseCase;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(
      GetInvestmentsEvent(userId: 'user_123', walletId: 'wallet_123'),
    );
    registerFallbackValue(
      RefreshPricesEvent(userId: 'user_123', walletId: 'wallet_123'),
    );
    registerFallbackValue(
      DeleteInvestmentEvent(
        id: 'inv_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        currentValue: 1250.0,
        recordSale: true,
      ),
    );
  });

  setUp(() {
    mockInvestmentBloc = MockInvestmentBloc();
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
        body: BlocProvider<InvestmentBloc>.value(
          value: mockInvestmentBloc,
          child: child,
        ),
      ),
    );
  }

  final testWallet = WalletEntity(
    id: 'wallet_123',
    userId: 'user_123',
    name: 'Ana Cüzdan',
    balance: 5000.0,
    debt: 0.0,
    credit: 0.0,
    investment: 1000.0,
    colorHex: '#123456',
    iconName: 'wallet',
    createdAt: DateTime(2026, 1, 1),
    openingBalance: 5000.0,
  );

  final testInvestment1 = InvestmentEntity(
    id: 'inv_1',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Gram Altın',
    amount: 1000.0,
    currentValue: 1250.0,
    type: InvestmentType.gold,
    color: Colors.amber,
    dateAdded: DateTime(2026, 1, 1),
    symbol: 'XAU',
    quantity: 1.0,
  );

  final testInvestment2 = InvestmentEntity(
    id: 'inv_2',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Bireysel Emeklilik',
    amount: 2000.0,
    currentValue: 2000.0,
    type: InvestmentType.custom,
    color: Colors.teal,
    dateAdded: DateTime(2026, 1, 1),
  );

  testWidgets('renders loading state with CircularProgressIndicator',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(InvestmentLoading());

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders loaded state with metrics, chart and cards',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1, testInvestment2],
        totalAmount: 3000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    // Verify SummaryCard rendering
    expect(find.text('TOPLAM PORTFÖY DEĞERİ'), findsOneWidget);
    expect(find.text('₺3.250'),
        findsOneWidget); // totalCurrentValue = 1250 + 2000 = 3250
    expect(find.text('₺3.000'), findsOneWidget); // totalInvestment = 3000

    // Verify Portföyüm header
    expect(find.text('Portföyüm'), findsOneWidget);
    expect(find.text('2 yatırım'), findsOneWidget); // investments.length = 2

    // Verify investment cards render name
    expect(find.text('Gram Altın'), findsWidgets);
    expect(find.text('Bireysel Emeklilik'), findsWidgets);
  });

  testWidgets('tapping refresh button dispatches RefreshPricesEvent',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1],
        totalAmount: 1000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    // Find refresh button (by tooltip or icon)
    final refreshFinder = find.byIcon(Icons.refresh_rounded);
    expect(refreshFinder, findsOneWidget);

    await tester.ensureVisible(refreshFinder);
    await tester.tap(refreshFinder);
    await tester.pumpAndSettle();

    verify(() => mockInvestmentBloc.add(any(that: isA<RefreshPricesEvent>())))
        .called(1);
  });

  testWidgets(
      'tapping investment card and choosing contribute opens ContributeSheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1],
        totalAmount: 1000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the investment card
    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Gram Altın'),
        )
        .first;
    expect(cardFinder, findsOneWidget);
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Verify Action Sheet opened
    expect(find.byType(InvestmentActionSheet), findsOneWidget);

    // Tap on contribute option (Varlık Ekle because Gram Altın has a symbol XAU)
    final contributeTileFinder = find.text('Varlık Ekle');
    expect(contributeTileFinder, findsOneWidget);
    await tester.tap(contributeTileFinder);
    await tester.pumpAndSettle();

    // Verify Action Sheet is closed and ContributeSheet is shown
    expect(find.byType(InvestmentActionSheet), findsNothing);
    expect(find.text('Gram Altın · Varlık Ekle'), findsOneWidget);
  });

  testWidgets(
      'tapping sell option shows confirmation dialog and dispatches DeleteInvestmentEvent with recordSale: true',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1],
        totalAmount: 1000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    await tester.pumpAndSettle();

    // Tap card
    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Gram Altın'),
        )
        .first;
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Tap Sat tile in action sheet
    await tester.tap(find.text('Sat'));
    await tester.pumpAndSettle();

    // Verify dialog title
    expect(find.text('Gram Altın satılsın mı?'), findsOneWidget);

    // Tap Sat confirmation button (FilledButton with text 'Sat')
    final satButtonFinder = find.descendant(
      of: find.byType(FilledButton),
      matching: find.text('Sat'),
    );
    expect(satButtonFinder, findsOneWidget);
    await tester.tap(satButtonFinder);
    await tester.pumpAndSettle();

    // Verify event dispatched
    verify(() => mockInvestmentBloc.add(any(
          that: isA<DeleteInvestmentEvent>()
              .having((e) => e.recordSale, 'recordSale', true)
              .having((e) => e.id, 'id', 'inv_1'),
        ))).called(1);
  });

  testWidgets(
      'tapping delete option shows confirmation dialog and dispatches DeleteInvestmentEvent with recordSale: false',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1],
        totalAmount: 1000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    await tester.pumpAndSettle();

    // Tap card
    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Gram Altın'),
        )
        .first;
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Tap Kaydı Sil tile in action sheet
    await tester.tap(find.text('Kaydı Sil'));
    await tester.pumpAndSettle();

    // Verify dialog title
    expect(find.text('Gram Altın kaydı silinsin mi?'), findsOneWidget);

    // Tap Kaydi Sil confirmation button (FilledButton with text 'Kaydı Sil')
    final deleteButtonFinder = find.descendant(
      of: find.byType(FilledButton),
      matching: find.text('Kaydı Sil'),
    );
    expect(deleteButtonFinder, findsOneWidget);
    await tester.tap(deleteButtonFinder);
    await tester.pumpAndSettle();

    // Verify event dispatched with recordSale: false
    verify(() => mockInvestmentBloc.add(any(
          that: isA<DeleteInvestmentEvent>()
              .having((e) => e.recordSale, 'recordSale', false)
              .having((e) => e.id, 'id', 'inv_1'),
        ))).called(1);
  });

  testWidgets('renders success message when state is InvestmentActionSuccess',
      (WidgetTester tester) async {
    final controller = StreamController<InvestmentState>.broadcast();
    addTearDown(controller.close);

    when(() => mockInvestmentBloc.stream).thenAnswer((_) => controller.stream);
    when(() => mockInvestmentBloc.state).thenReturn(InvestmentLoading());

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    // Emit success state
    controller.add(const InvestmentActionSuccess('İşlem başarıyla tamamlandı'));
    await tester.pumpAndSettle();

    // Verify snackbar/success text is shown
    expect(find.text('İşlem başarıyla tamamlandı'), findsOneWidget);
    // Verify reload was triggered
    verify(() => mockInvestmentBloc.add(any(that: isA<GetInvestmentsEvent>())))
        .called(2);
  });

  testWidgets('renders error message when state is InvestmentError',
      (WidgetTester tester) async {
    final controller = StreamController<InvestmentState>.broadcast();
    addTearDown(controller.close);

    when(() => mockInvestmentBloc.stream).thenAnswer((_) => controller.stream);
    when(() => mockInvestmentBloc.state).thenReturn(InvestmentLoading());

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    // Emit error state
    controller.add(const InvestmentError('Bir hata oluştu'));
    await tester.pumpAndSettle();

    expect(find.text('Bir hata oluştu'), findsOneWidget);
  });

  testWidgets('tapping cancel on sell dialog does not trigger dispatch',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1],
        totalAmount: 1000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    await tester.pumpAndSettle();

    // Tap card
    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Gram Altın'),
        )
        .first;
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Tap Sat tile in action sheet
    await tester.tap(find.text('Sat'));
    await tester.pumpAndSettle();

    // Verify dialog title
    expect(find.text('Gram Altın satılsın mı?'), findsOneWidget);

    // Tap Vazgeç button
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    // Verify no delete event is dispatched
    verifyNever(
        () => mockInvestmentBloc.add(any(that: isA<DeleteInvestmentEvent>())));
  });

  testWidgets('tapping cancel on delete dialog does not trigger dispatch',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1],
        totalAmount: 1000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    await tester.pumpAndSettle();

    // Tap card
    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Gram Altın'),
        )
        .first;
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Tap Kaydı Sil tile in action sheet
    await tester.tap(find.text('Kaydı Sil'));
    await tester.pumpAndSettle();

    // Verify dialog title
    expect(find.text('Gram Altın kaydı silinsin mi?'), findsOneWidget);

    // Tap Vazgeç button
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    // Verify no delete event is dispatched
    verifyNever(
        () => mockInvestmentBloc.add(any(that: isA<DeleteInvestmentEvent>())));
  });

  testWidgets('re-loads investments when wallet changes in didUpdateWidget',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(InvestmentLoading());

    // Pump with first wallet
    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    // Verify initial load event dispatched
    verify(() => mockInvestmentBloc.add(any(that: isA<GetInvestmentsEvent>())))
        .called(1);

    // Re-pump with a different wallet
    final walletB = WalletEntity(
      id: 'wallet_456',
      userId: 'user_123',
      name: 'Yedek Cüzdan',
      balance: 1000.0,
      debt: 0.0,
      credit: 0.0,
      investment: 0.0,
      colorHex: '#654321',
      iconName: 'wallet',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 1000.0,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: walletB),
      ),
    );

    // Verify second load event dispatched with the new wallet
    verify(() => mockInvestmentBloc.add(
          GetInvestmentsEvent(userId: 'user_123', walletId: 'wallet_456'),
        )).called(1);
  });

  testWidgets('tapping edit on custom investment opens AddCustomSheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment2], // testInvestment2 has custom type
        totalAmount: 2000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on card
    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Bireysel Emeklilik'),
        )
        .first;
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Tap Düzenle tile in action sheet
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();

    // Verify AddCustomSheet is shown by checking its header text
    expect(find.text('Özel Yatırımını Düzenle'), findsOneWidget);
  });

  testWidgets('tapping edit on gold investment opens AddGoldSheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1], // testInvestment1 has gold type
        totalAmount: 1000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on card
    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Gram Altın'),
        )
        .first;
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Tap Düzenle tile in action sheet
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();

    // Verify AddGoldSheet is shown by checking its header text
    expect(find.text('Altın Yatırımını Düzenle'), findsOneWidget);
  });

  testWidgets('tapping edit on stock investment opens AddStockSheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testStock = InvestmentEntity(
      id: 'inv_stock',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Türk Hava Yolları',
      amount: 1500.0,
      currentValue: 1800.0,
      type: InvestmentType.stock,
      color: Colors.red,
      symbol: 'THYAO',
      quantity: 5.0,
      dateAdded: DateTime(2026, 1, 1),
    );

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testStock],
        totalAmount: 1500.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on card
    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Türk Hava Yolları'),
        )
        .first;
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Tap Düzenle tile in action sheet
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();

    // Verify AddStockSheet is shown by checking its header text
    expect(find.text('Hisse Yatırımını Düzenle'), findsOneWidget);
  });

  testWidgets(
      'tapping refresh price on gold investment in action sheet dispatches RefreshPricesEvent with investmentId',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1], // testInvestment1 is gold and has symbol XAU
        totalAmount: 1000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    await tester.pumpAndSettle();

    // Tap card
    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Gram Altın'),
        )
        .first;
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Tap Fiyatı Güncelle tile in action sheet
    await tester.tap(find.text('Fiyatı Güncelle'));
    await tester.pumpAndSettle();

    // Verify event dispatched
    verify(() => mockInvestmentBloc.add(any(
          that: isA<RefreshPricesEvent>()
              .having((e) => e.investmentId, 'investmentId', 'inv_1'),
        ))).called(1);
  });
}
