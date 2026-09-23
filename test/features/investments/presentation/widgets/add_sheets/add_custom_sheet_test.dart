import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_custom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/ledger_transaction_picker.dart';

/// Showcase turları getIt üzerinden koordinatörü çeker; widget testlerinde
/// gerçek koordinatör kayıtlı olmadığından mock'lanır.
class _MockOnboardingCoordinator extends Mock
    implements OnboardingCoordinator {}

class _MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
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
          walletCurrency: 'TRY',
          onSave: (inv, _) => savedInvestment = inv,
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
          walletCurrency: 'TRY',
          onSave: (_, __) {},
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

    // Hedef tutar alanı formdan kalktı (hedef artık ayrı kayıt). Yerine
    // ortak kural: maliyet ve değer birlikte sıfır olamaz.
    await tester.enterText(amountFinder, '0');
    await tester.enterText(currentValueFinder, '0');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Maliyet ya da mevcut değerden en az biri sıfırdan büyük olmalı'),
        findsOneWidget);
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
          walletCurrency: 'TRY',
          investmentToEdit: testInvestment,
          onSave: (inv, _) => updatedInvestment = inv,
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
    expect(updatedInvestment!.color, Colors.teal);
  });

  // Tur adımları kapanı: OnboardingTour TÜM hedefleri render edilmiş
  // bulamazsa tur sessizce hiç oynamaz. Özel yatırımda miktar alanı yok, bu
  // yüzden adım listesi iki adımdır.
  testWidgets('turun iki adımı ağaçta, miktar adımı yok', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      AddCustomSheet(
        walletId: 'wallet_123',
        userId: 'user_123',
        walletCurrency: 'TRY',
        onSave: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();

    final showcase = ShowcaseView.get();
    expect(showcase.isTargetRendered(OnboardingKeys.investmentAddForm), isTrue);
    expect(showcase.isTargetRendered(OnboardingKeys.investmentAddCost), isTrue);
    expect(showcase.isTargetRendered(OnboardingKeys.investmentAddQuantity),
        isFalse);
  });

  // Faz 2 (23 Eyl 2026): ekstreden gelen "MIDAS MENKUL DEGERLER −5.000"
  // defterde dururken kullanıcı aynı alımı Birikim'e girince para iki kez
  // düşüyordu. Artık "Ödemesi defterde zaten var" → satır seçilir; maliyet ve
  // tarih o satırdan gelir, kayıt benimseme kaynağıyla kaydedilir.
  testWidgets('"ödemesi defterde var": satır seçilir, maliyet/tarih kilitlenir',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bankRow = TransactionEntity(
      id: 'row-1',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'MIDAS MENKUL DEGERLER',
      tag: 'cat-yatirim',
      amount: 5000,
      date: DateTime(2026, 9, 5, 14),
      type: TransactionTypeModel.expense,
      reference: 'DK-1',
      origin: TransactionOrigin.bankImport,
    );
    final repo = _MockTransactionsRepository();
    when(() => repo.getTransactions(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async => Right([
          bankRow,
          // Sistem hareketi seçilemez (zaten bir kaydın malı).
          bankRow.copyWith(id: 'sys', title: 'Borç Ödemesi', isSystem: true),
        ]));
    getIt.registerSingleton<TransactionsRepository>(repo);

    InvestmentEntity? saved;
    CashSource? source;
    await tester.pumpWidget(
      buildTestableWidget(
        AddCustomSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
          onSave: (inv, cash) {
            saved = inv;
            source = cash;
          },
        ),
      ),
    );

    await tester.enterText(
        find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == '0'),
        '5.200');

    final ledgerOption = find.text('Ödemesi defterde zaten var');
    await tester.ensureVisible(ledgerOption);
    await tester.tap(ledgerOption);
    await tester.pumpAndSettle();

    // Seçici kendiliğinden açıldı; sistem hareketi listede yok.
    expect(find.text('Ödemenin satırını seç'), findsOneWidget);
    expect(find.text('Borç Ödemesi'), findsNothing);
    expect(find.text('Ekstreden'), findsOneWidget);
    await tester.tap(find.text('MIDAS MENKUL DEGERLER'));
    await tester.pumpAndSettle();

    // Maliyet satırdan geldi ve kilitli.
    final cost = tester.widget<TextField>(find.byWidgetPredicate((w) =>
        w is TextField &&
        w.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)'));
    expect(cost.readOnly, isTrue);
    expect(cost.controller!.text, contains('5.000'));
    expect(find.textContaining('yeni gider yazılmaz'), findsOneWidget);

    final saveButton = find.text('Kaydet');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.amount, 5000);
    expect(saved!.dateAdded, DateTime(2026, 9, 5));
    expect(saved!.unbookedCost, 0,
        reason: 'maliyet deftere işlenmiş sayılır — benimsenen satırla');
    expect(source, isA<AdoptedCashMovement>());
    expect((source! as AdoptedCashMovement).transaction.id, 'row-1');
  });

  testWidgets('"ödemesi defterde var" seçilip satır seçilmezse kaydedilmez',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repo = _MockTransactionsRepository();
    when(() => repo.getTransactions(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async => const Right(<TransactionEntity>[]));
    getIt.registerSingleton<TransactionsRepository>(repo);

    var saveCalled = false;
    await tester.pumpWidget(
      buildTestableWidget(
        AddCustomSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
          onSave: (_, __) => saveCalled = true,
        ),
      ),
    );
    await tester.enterText(
        find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == '0'),
        '100');
    await tester.enterText(
        find.byWidgetPredicate((w) =>
            w is TextField &&
            w.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)'),
        '100');

    final ledgerOption = find.text('Ödemesi defterde zaten var');
    await tester.ensureVisible(ledgerOption);
    await tester.tap(ledgerOption);
    await tester.pumpAndSettle();
    // Uygun satır yok: seçici boş durumunu söyler, kullanıcı kapatır.
    expect(find.textContaining('Uygun işlem yok'), findsOneWidget);
    // Sayfanın kendi kapatma düğmesi de aynı simgeyi taşır; seçicininki.
    await tester.tap(find.descendant(
      of: find.byType(LedgerTransactionPicker),
      matching: find.byIcon(Icons.close_rounded),
    ));
    await tester.pumpAndSettle();

    final saveButton = find.text('Kaydet');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(saveCalled, isFalse);
    expect(find.text('Önce ödemenin defterdeki satırını seç.'), findsWidgets);
  });

  testWidgets('"Bağla…" akışından: satır önceden seçili, maliyet/tarih ondan',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bankRow = TransactionEntity(
      id: 'row-9',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'MIDAS MENKUL DEGERLER',
      tag: 'cat-yatirim',
      amount: 5000,
      date: DateTime(2026, 9, 5, 14),
      type: TransactionTypeModel.expense,
      origin: TransactionOrigin.bankImport,
    );

    InvestmentEntity? saved;
    CashSource? source;
    await tester.pumpWidget(
      buildTestableWidget(
        AddCustomSheet(
          walletId: 'wallet_123',
          userId: 'user_123',
          walletCurrency: 'TRY',
          initialLedgerTransaction: bankRow,
          onSave: (inv, cash) {
            saved = inv;
            source = cash;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cost = tester.widget<TextField>(find.byWidgetPredicate((w) =>
        w is TextField &&
        w.decoration?.hintText == 'Maliyet (Yatırılan Ana Para)'));
    expect(cost.readOnly, isTrue);
    expect(cost.controller!.text, contains('5.000'));
    expect(find.textContaining('yeni gider yazılmaz'), findsOneWidget);

    await tester.enterText(
        find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == '0'),
        '5.200');
    final saveButton = find.text('Kaydet');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(saved!.amount, 5000);
    expect(saved!.dateAdded, DateTime(2026, 9, 5));
    expect(source, isA<AdoptedCashMovement>());
    expect((source! as AdoptedCashMovement).transaction.id, 'row-9');
  });
}
