import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
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
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:intl/intl.dart';

class MockInvestmentBloc extends MockBloc<InvestmentEvent, InvestmentState>
    implements InvestmentBloc {}

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

  late MockInvestmentBloc mockInvestmentBloc;
  late MockGetLiveQuoteUseCase mockGetLiveQuoteUseCase;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    // Showcase widget'ı kayıtlı bir scope yoksa initState'te fırlatır.
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
    getIt.allowReassignment = true;
    registerFallbackValue(
      GetInvestmentsEvent(userId: 'user_123', walletId: 'wallet_123'),
    );
    registerFallbackValue(
      RefreshPricesEvent(
          userId: 'user_123', walletId: 'wallet_123', walletCurrency: 'TRY'),
    );
    registerFallbackValue(
      DeleteInvestmentEvent(
        id: 'inv_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        currentValue: 1250.0,
        recordSale: true,
        dateAdded: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    // tearDown'daki getIt.reset() kayıtları sildiğinden test başına yapılır.
    final onboardingCoordinator = _MockOnboardingCoordinator();
    when(() => onboardingCoordinator.isSeen(any())).thenReturn(true);
    getIt.registerSingleton<OnboardingCoordinator>(onboardingCoordinator);
    mockInvestmentBloc = MockInvestmentBloc();
    mockGetLiveQuoteUseCase = MockGetLiveQuoteUseCase();
    getIt.registerSingleton<GetLiveQuoteUseCase>(mockGetLiveQuoteUseCase);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      // Mesajlar [AppMessenger] üzerinden gösterilir; anahtar üretimde
      // olduğu gibi burada da bağlanmalı, yoksa snackbar hiç doğmaz.
      scaffoldMessengerKey: appMessengerKey,
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

  testWidgets('boş portföyde sıfır kartı değil yönlendirme gösterilir',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state)
        .thenReturn(const InvestmentLoaded([], totalAmount: 0.0));

    await tester.pumpWidget(
      buildTestableWidget(InvestmentMoneyPage(activeWallet: testWallet)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Henüz birikimin yok'), findsOneWidget);
    // Sıfırlarla dolu özet kartı ve bölüm başlıkları gösterilmez.
    expect(find.text('Hedeflerim'), findsNothing);
    expect(find.text('Bağsız varlıklar'), findsNothing);
    // İki yol da ekranda: hedefle başla ya da doğrudan varlık ekle.
    expect(find.text('Yeni hedef oluştur'), findsOneWidget);
    expect(find.text('Varlık Ekle'), findsOneWidget);
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
    expect(find.text('3.250,00 ₺'),
        findsOneWidget); // totalCurrentValue = 1250 + 2000 = 3250
    expect(find.text('3.000,00 ₺'), findsOneWidget); // totalInvestment = 3000

    // Hedefsiz kayıtlar "Bağsız varlıklar" başlığı altında listelenir.
    expect(find.text('Bağsız varlıklar'), findsOneWidget);
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

    // Satış sayfası açılır (onay diyaloğu değil): ne kadarını sattığın ve
    // eline ne geçtiği burada onaylanır.
    expect(find.text('Gram Altın · Sat'), findsOneWidget);

    // Varsayılan tam satış; Sat düğmesine dokun.
    final satButtonFinder = find.descendant(
      of: find.byType(FilledButton),
      matching: find.text('Sat'),
    );
    expect(satButtonFinder, findsOneWidget);
    await tester.tap(satButtonFinder);
    await tester.pumpAndSettle();

    // Verify event dispatched — cüzdana giren tutar onaylanan tutardır.
    verify(() => mockInvestmentBloc.add(any(
          that: isA<DeleteInvestmentEvent>()
              .having((e) => e.recordSale, 'recordSale', true)
              .having((e) => e.id, 'id', 'inv_1')
              .having((e) => e.currentValue, 'proceeds', 1250.0),
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

    // Emit success state — bloc metin değil TİP yayınlar; cümle sayfada
    // çevrilir.
    controller.add(const InvestmentActionSuccess(InvestmentAddedNotice()));
    await tester.pumpAndSettle();

    // Verify snackbar/success text is shown
    expect(find.text('Yatırım başarıyla eklendi'), findsOneWidget);
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
    controller.add(const InvestmentError(RawFailureNotice('Bir hata oluştu')));
    await tester.pumpAndSettle();

    expect(find.text('Bir hata oluştu'), findsOneWidget);
  });

  testWidgets('nakit hareketi yazılamazsa mesaja bakiye uyarısı eklenir',
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

    controller.add(
        const InvestmentActionSuccess(InvestmentSoldNotice(), cashOk: false));
    await tester.pumpAndSettle();

    expect(
      find.text('Yatırım satıldı (Uyarı: bakiye güncellenemedi, '
          'cüzdanı yenileyin.)'),
      findsOneWidget,
    );
  });

  testWidgets('kısmi satış kaydı silmez, PartialSellInvestmentEvent atar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded([testInvestment1], totalAmount: 1000.0),
    );

    await tester.pumpWidget(
      buildTestableWidget(InvestmentMoneyPage(activeWallet: testWallet)),
    );
    await tester.pumpAndSettle();

    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Gram Altın'),
        )
        .first;
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sat'));
    await tester.pumpAndSettle();

    // 1 adetin 0,25'i satılıyor.
    await tester.enterText(find.byType(TextField).first, '0,25');
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
      of: find.byType(FilledButton),
      matching: find.text('Sat'),
    ));
    await tester.pumpAndSettle();

    verifyNever(
        () => mockInvestmentBloc.add(any(that: isA<DeleteInvestmentEvent>())));
    verify(() => mockInvestmentBloc.add(any(
          that: isA<PartialSellInvestmentEvent>()
              // Kalan: 0,75 adet, maliyet 750, değer 937,50.
              .having((e) => e.remaining.quantity, 'kalan miktar', 0.75)
              .having((e) => e.remaining.amount, 'kalan maliyet', 750.0)
              .having((e) => e.remaining.currentValue, 'kalan değer', 937.5)
              // Eline geçen: 0,25 × 1.250 = 312,50.
              .having((e) => e.proceeds, 'eline geçen', 312.5),
        ))).called(1);
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

    // Verify sell sheet title
    expect(find.text('Gram Altın · Sat'), findsOneWidget);

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

  // ------------------------------------------------------- Çoklu para birimi
  // Portföy her cüzdanda açılır; değerleme cüzdanın kendi birimindedir.

  final usdWallet = WalletEntity(
    id: 'wallet_usd',
    userId: 'user_123',
    name: 'Dolar Cüzdanı',
    balance: 500.0,
    debt: 0.0,
    credit: 0.0,
    investment: 1250.0,
    colorHex: '#123456',
    iconName: 'wallet',
    createdAt: DateTime(2026, 1, 1),
    openingBalance: 500.0,
    currency: 'USD',
  );

  testWidgets('döviz cüzdanda portföy açılır ve tutarlar o birimde yazar',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded([testInvestment1], totalAmount: 1000.0),
    );

    await tester.pumpWidget(
      buildTestableWidget(InvestmentMoneyPage(activeWallet: usdWallet)),
    );
    await tester.pumpAndSettle();

    // Eskiden burada "yalnız TL cüzdan" bilgilendirmesi vardı; liste hiç
    // kurulmuyordu.
    expect(find.byType(InvestmentCard), findsOneWidget);
    expect(find.textContaining('1.250,00 \$'), findsWidgets);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('fiyat yenileme olayına cüzdanın birimi geçirilir',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded([testInvestment1], totalAmount: 1000.0),
    );

    await tester.pumpWidget(
      buildTestableWidget(InvestmentMoneyPage(activeWallet: usdWallet)),
    );
    await tester.pumpAndSettle();

    final refreshButton = find.byIcon(Icons.refresh_rounded);
    await tester.ensureVisible(refreshButton);
    await tester.tap(refreshButton);
    await tester.pumpAndSettle();

    verify(() => mockInvestmentBloc.add(any(
          that: isA<RefreshPricesEvent>()
              .having((e) => e.walletCurrency, 'walletCurrency', 'USD'),
        ))).called(1);
  });

  testWidgets('"zaten bende" kaydın maliyeti düzenlenince cüzdana yazılmaz',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Uygulamadan önce alınmış kayıt: maliyetin tamamı işlenmemiş.
    final alreadyOwned = testInvestment2.copyWith(unbookedCost: 2000.0);
    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded([alreadyOwned], totalAmount: 2000.0),
    );

    await tester.pumpWidget(
      buildTestableWidget(InvestmentMoneyPage(activeWallet: testWallet)),
    );
    await tester.pumpAndSettle();

    final cardFinder = find
        .descendant(
          of: find.byType(InvestmentCard),
          matching: find.text('Bireysel Emeklilik'),
        )
        .first;
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();

    // Maliyeti 2.000 → 1.500 düşür.
    final costField = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)');
    await tester.ensureVisible(costField);
    await tester.enterText(costField, '1.500');
    await tester.pumpAndSettle();

    final saveButton = find.text('Güncelle');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Deftere hiç girmemiş paranın azalması cüzdana GELİR yazılamaz:
    // işlenmiş maliyet iki tarafta da sıfır.
    verify(() => mockInvestmentBloc.add(any(
          that: isA<UpdateInvestmentEvent>()
              .having((e) => e.prevAmount, 'önceki işlenmiş maliyet', 0.0)
              .having((e) => e.newAmount, 'yeni işlenmiş maliyet', 0.0)
              .having((e) => e.investment.unbookedCost, 'işlenmemiş maliyet',
                  1500.0),
        ))).called(1);
  });

  testWidgets(
      'hedef kartı KARIŞIK portföyün toplamını gösterir, üyeleri '
      'bağsız listede tekrar etmez', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final goal = GoalEntity(
      id: 'goal_1',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Ev peşinatı',
      targetAmount: 10000.0,
      category: 'ev',
      color: Colors.teal,
      createdAt: DateTime(2026, 1, 1),
    );
    final gram = testInvestment1.copyWith(goalId: 'goal_1');
    final ceyrek = InvestmentEntity(
      id: 'inv_3',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Çeyrek Birikimi',
      amount: 1000.0,
      currentValue: 1750.0,
      type: InvestmentType.gold,
      color: Colors.amber,
      dateAdded: DateTime(2026, 1, 1),
      symbol: 'ceyrek-altin',
      quantity: 1.0,
      goalId: 'goal_1',
    );

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [gram, ceyrek, testInvestment2],
        goals: [goal],
        totalAmount: 4000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(InvestmentMoneyPage(activeWallet: testWallet)),
    );
    await tester.pumpAndSettle();

    // Birikmiş = 1.250 + 1.750 = 3.000 (iki farklı altın türü TEK hedefte).
    expect(find.text('Ev peşinatı'), findsOneWidget);
    expect(find.text('3.000,00 ₺ / 10.000,00 ₺'), findsOneWidget);
    expect(find.text('%30'), findsOneWidget);
    expect(find.text('2 varlık'), findsOneWidget);

    // Kapalıyken üyeler çizilmez; bağsız kayıt listede durur.
    // (Ad, grafik göstergesinde de geçiyor — yalnız kartlara bakılır.)
    Finder inCard(String name) => find.descendant(
          of: find.byType(InvestmentCard),
          matching: find.text(name),
        );
    expect(find.text('Bağsız varlıklar'), findsOneWidget);
    expect(inCard('Bireysel Emeklilik'), findsOneWidget);
    expect(inCard('Çeyrek Birikimi'), findsNothing);

    // Başlığa dokun → üyeler açılır.
    await tester.tap(find.text('Ev peşinatı'));
    await tester.pumpAndSettle();
    expect(inCard('Çeyrek Birikimi'), findsOneWidget);
    expect(find.text('Bu hedefe varlık ekle'), findsOneWidget);
  });

  testWidgets('hedef silme onayı üye sayısını söyler ve DeleteGoalEvent atar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final goal = GoalEntity(
      id: 'goal_1',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Ev peşinatı',
      targetAmount: 10000.0,
      category: 'ev',
      color: Colors.teal,
      createdAt: DateTime(2026, 1, 1),
    );

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1.copyWith(goalId: 'goal_1')],
        goals: [goal],
        totalAmount: 1000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(InvestmentMoneyPage(activeWallet: testWallet)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hedefi sil'));
    await tester.pumpAndSettle();

    // Kullanıcı varlıklarının silinmeyeceğini onay ekranında görür.
    expect(find.text('Ev peşinatı hedefi silinsin mi?'), findsOneWidget);
    expect(
      find.textContaining('İçindeki 1 varlık SİLİNMEZ'),
      findsOneWidget,
    );

    await tester.tap(find.descendant(
      of: find.byType(FilledButton),
      matching: find.text('Hedefi sil'),
    ));
    await tester.pumpAndSettle();

    verify(() => mockInvestmentBloc.add(any(
          that: isA<DeleteGoalEvent>()
              .having((e) => e.goal.id, 'goal id', 'goal_1'),
        ))).called(1);
  });
  testWidgets('gerçek telefon genişliğinde (360dp) hiçbir satır taşmaz',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final goal = GoalEntity(
      id: 'goal_1',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Kızımın düğünü için altın birikimi',
      targetAmount: 1250000.0,
      category: 'dugun',
      color: Colors.teal,
      createdAt: DateTime(2026, 1, 1),
    );
    final big = InvestmentEntity(
      id: 'big',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Düğün Altınları',
      amount: 900000.0,
      currentValue: 987654.32,
      type: InvestmentType.gold,
      color: Colors.amber,
      dateAdded: DateTime(2026, 1, 1),
      symbol: 'gram-altin',
      quantity: 224.5,
      goalId: 'goal_1',
    );

    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded([big, testInvestment2],
          goals: [goal], totalAmount: 902000.0),
    );

    await tester.pumpWidget(
      buildTestableWidget(InvestmentMoneyPage(activeWallet: testWallet)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Kızımın düğünü için altın birikimi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
