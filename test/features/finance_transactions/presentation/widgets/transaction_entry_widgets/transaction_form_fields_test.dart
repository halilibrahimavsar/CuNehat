import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_fields.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/wallet_category_stub.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

void main() {
  late MockCategoryRepository mockCategoryRepository;

  setUpAll(() {
    getIt.allowReassignment = true;
    ShowcaseView.register();
  });

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(mockCategoryRepository);
    registerUncuratedWalletCategories(mockCategoryRepository);
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

  testWidgets('renders TransactionFormSheet with initial fields',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => [
              ...await mockCategoryRepository.getCategories(true),
              ...await mockCategoryRepository.getCategories(false),
            ]);
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          name: 'Food',
          iconName: 'fastfood',
          isExpense: true,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        TransactionFormSheet(
          isExpense: true,
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (tx, freq) {},
          onCancel: () {},
        ),
      ),
    );

    // Form fields are rendered
    expect(
        find.byType(TextField), findsNWidgets(2)); // Title field & Amount field
    expect(find.text('Kaydet'), findsOneWidget);
  });

  testWidgets('displays validation error if save clicked with empty amount',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          name: 'Food',
          iconName: 'fastfood',
          isExpense: true,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        TransactionFormSheet(
          isExpense: true,
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (tx, freq) {},
          onCancel: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Click save when amount is empty
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    // Verify error banner is visible
    expect(find.text('Geçerli bir tutar gir'), findsOneWidget);
  });

  testWidgets(
      'kategori varsayılan seçili gelmez; seçilmeden kaydetmek engellenir',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          name: 'Food',
          iconName: 'fastfood',
          isExpense: true,
        ),
        const CategoryEntity(
          id: 'Market',
          name: 'Market',
          iconName: 'shopping_cart',
          isExpense: true,
        ),
      ],
    );

    var saveCalled = false;

    await tester.pumpWidget(
      buildTestableWidget(
        TransactionFormSheet(
          isExpense: true,
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (tx, freq) => saveCalled = true,
          onCancel: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    final amountTextField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.keyboardType.decimal == true,
    );
    await tester.enterText(amountTextField, '100');
    await tester.pumpAndSettle();

    // Tutar geçerli ama kategori seçilmedi → kayıt reddedilmeli.
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(saveCalled, isFalse);
    expect(find.text('Bir kategori seç'), findsOneWidget);

    // Kategoriye dokunmak uyarıyı kaldırır ve kayıt geçer.
    await tester.ensureVisible(find.text('Market'));
    await tester.tap(find.text('Market'));
    await tester.pumpAndSettle();
    expect(find.text('Bir kategori seç'), findsNothing);

    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(saveCalled, isTrue);
  });

  testWidgets('calls onSave callback when input is valid and saved',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          name: 'Food',
          iconName: 'fastfood',
          isExpense: true,
        ),
      ],
    );

    TransactionEntity? savedTransaction;
    var saveCalled = false;

    await tester.pumpWidget(
      buildTestableWidget(
        TransactionFormSheet(
          isExpense: true,
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (tx, freq) {
            savedTransaction = tx;
            saveCalled = true;
          },
          onCancel: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the amount input field (it usually has zero initially, or we enter 100)
    // The amount TextField does not have a label, but it is one of the TextFields.
    // In AmountHero, the TextField has keyboardType: TextInputType.numberWithOptions(decimal: true).
    final amountTextField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.keyboardType.decimal == true,
    );

    await tester.enterText(amountTextField, '100');

    // Enter note
    final noteTextField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText?.contains('Not') == true,
    );
    await tester.enterText(noteTextField, 'Lunch out');

    await tester.pumpAndSettle();

    // Kategori zorunlu ve varsayılan seçili GELMEZ — kullanıcı seçmeli.
    await tester.ensureVisible(find.text('Food'));
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Tap save button
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(saveCalled, isTrue);
    expect(savedTransaction, isNotNull);
    expect(savedTransaction!.amount, 100.0);
    expect(savedTransaction!.title, 'Lunch out');
    expect(savedTransaction!.tag, 'Food');
    // Ekstre tekrar tespiti "elle girildi"yi başlıktan tahmin etmesin (M5).
    expect(savedTransaction!.origin, TransactionOrigin.manual);
  });

  // REGRESYON (M7, 23 Eyl 2026): form düzenlemede varlığı sıfırdan kuruyordu;
  // formda OLMAYAN alanlar sessizce siliniyordu. İçe aktarılmış bir işlemin
  // yalnız kategorisini/notunu değiştirmek bankanın numarasını (`reference`)
  // kaybettiriyordu — içe aktarımlar arası tekrar tespitinin en güçlü kimliği.
  testWidgets('düzenleme formda olmayan alanları (banka numarası) korur',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          name: 'Food',
          iconName: 'fastfood',
          isExpense: true,
        ),
      ],
    );

    final imported = TransactionEntity(
      id: 'tx-1',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'BIM MAGAZALAR A.S. USKUDAR',
      tag: 'Food',
      amount: 913.15,
      date: DateTime(2026, 9, 5),
      type: TransactionTypeModel.expense,
      reference: 'DK-77',
    );
    TransactionEntity? saved;

    await tester.pumpWidget(
      buildTestableWidget(
        TransactionFormSheet(
          isExpense: true,
          walletId: 'wallet_123',
          userId: 'user_123',
          initialTransaction: imported,
          onSave: (tx, freq) => saved = tx,
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final noteTextField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText?.contains('Not') == true,
    );
    await tester.enterText(noteTextField, 'Bim');
    await tester.pumpAndSettle();

    // Düzenleme kipinde düğme "Güncelle" der.
    await tester.ensureVisible(find.text('Güncelle'));
    await tester.tap(find.text('Güncelle'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(saved, isNotNull);
    expect(saved!.id, 'tx-1');
    expect(saved!.title, 'Bim');
    expect(saved!.reference, 'DK-77',
        reason: 'formda görünmeyen banka numarası düzenlemede silinmemeli');
  });

  testWidgets('can pick date and time using date and time pickers',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          name: 'Food',
          iconName: 'fastfood',
          isExpense: true,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        TransactionFormSheet(
          isExpense: true,
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (tx, freq) {},
          onCancel: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap calendar pill to open DatePicker
    await tester.ensureVisible(find.byIcon(Icons.calendar_today_rounded));
    await tester.tap(find.byIcon(Icons.calendar_today_rounded));
    await tester.pumpAndSettle();

    // Verify DatePicker is open and tap Tamam
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    // Tap schedule pill to open TimePicker
    await tester.ensureVisible(find.byIcon(Icons.schedule_rounded));
    await tester.tap(find.byIcon(Icons.schedule_rounded));
    await tester.pumpAndSettle();

    // Verify TimePicker is open and tap Tamam
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
  });
  group('kategori: alt kategoriler şeridin altında açılır', () {
    // Ölçülen gerçek şekle yakın: çocuklu iki kök + çocuksuz bir kök.
    const fatura = CategoryEntity(
        id: 'r1', name: 'Fatura', iconName: 'receipt_long', isExpense: true);
    const elektrik = CategoryEntity(
        id: 'c1',
        name: 'Elektrik',
        iconName: 'lightbulb',
        isExpense: true,
        parentId: 'r1');
    const su = CategoryEntity(
        id: 'c2',
        name: 'Su',
        iconName: 'water_drop',
        isExpense: true,
        parentId: 'r1');
    const market = CategoryEntity(
        id: 'r2', name: 'Market', iconName: 'shopping_cart', isExpense: true);
    const manav = CategoryEntity(
        id: 'c3',
        name: 'Manav',
        iconName: 'restaurant',
        isExpense: true,
        parentId: 'r2');
    const kira = CategoryEntity(
        id: 'r3', name: 'Kira', iconName: 'home', isExpense: true);

    Future<void> pumpForm(WidgetTester tester) async {
      when(() => mockCategoryRepository.getCategories(true))
          .thenAnswer((_) async => [fatura, elektrik, su, market, manav, kira]);
      when(() => mockCategoryRepository.getCategories(false))
          .thenAnswer((_) async => []);
      when(() => mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => [fatura, elektrik, su, market, manav, kira]);

      await tester.pumpWidget(
        buildTestableWidget(
          TransactionFormSheet(
            isExpense: true,
            walletId: 'wallet_123',
            userId: 'user_123',
            onSave: (_, __) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // REGRESYON: çocuklu köke dokunmak `showCategoryPickerSheet`'i açıyordu ve
    // o sayfa ekranda ZATEN duran ana kategorileri bir kez daha listeliyordu.
    // Üstelik dokunulan kök seçiciye geçirilmediği için sayfa ilk kökle
    // (Market → Manav) açılıyordu — "Fatura"ya dokunup Manav görmek.
    testWidgets('çocuklu köke dokunmak modal AÇMAZ', (tester) async {
      await pumpForm(tester);

      await tester.ensureVisible(find.text('Fatura'));
      await tester.tap(find.text('Fatura'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryPickerSheet), findsNothing);
    });

    testWidgets('çocuklu köke dokunmak kökü seçer ve altlarını açar',
        (tester) async {
      await pumpForm(tester);

      expect(find.text('Elektrik'), findsNothing);

      await tester.ensureVisible(find.text('Fatura'));
      await tester.tap(find.text('Fatura'));
      await tester.pumpAndSettle();

      // Altlar göründü...
      expect(find.text('Elektrik'), findsOneWidget);
      expect(find.text('Su'), findsOneWidget);
      // ...ve kökün kendisi SEÇİLDİ: kategori uyarısı artık tetiklenmez.
      await tester.ensureVisible(find.text('Kaydet'));
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      expect(find.text('Bir kategori seç'), findsNothing);
    });

    testWidgets('alt kategoriye dokunmak seçimi ona taşır', (tester) async {
      await pumpForm(tester);

      await tester.ensureVisible(find.text('Fatura'));
      await tester.tap(find.text('Fatura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elektrik'));
      await tester.pumpAndSettle();

      // Şerit tile'ı seçili yaprağın adını taşır; "Fatura" yazısı yerini
      // "Elektrik"e bırakır (ikisi de görünür: biri tile, biri çip).
      expect(find.text('Elektrik'), findsNWidgets(2));
      expect(find.text('Fatura'), findsNothing);
    });

    testWidgets('başka köke dokunmak açılan alanı oraya taşır', (tester) async {
      await pumpForm(tester);

      await tester.ensureVisible(find.text('Fatura'));
      await tester.tap(find.text('Fatura'));
      await tester.pumpAndSettle();
      expect(find.text('Elektrik'), findsOneWidget);

      await tester.tap(find.text('Market'));
      await tester.pumpAndSettle();

      expect(find.text('Elektrik'), findsNothing);
      expect(find.text('Manav'), findsOneWidget);
    });

    testWidgets('çocuksuz köke dokunmak açılan alanı kapatır', (tester) async {
      await pumpForm(tester);

      await tester.ensureVisible(find.text('Fatura'));
      await tester.tap(find.text('Fatura'));
      await tester.pumpAndSettle();
      expect(find.text('Elektrik'), findsOneWidget);

      await tester.ensureVisible(find.text('Kira'));
      await tester.tap(find.text('Kira'));
      await tester.pumpAndSettle();

      expect(find.text('Elektrik'), findsNothing);
    });
  });

  group('kart cüzdanında taksit', () {
    WalletEntity wallet({CreditCardInfo? card}) => WalletEntity(
          id: 'wallet_123',
          userId: 'user_123',
          name: 'Bonus',
          balance: 0,
          debt: 0,
          credit: 0,
          investment: 0,
          colorHex: '0xFF37474F',
          iconName: 'credit_card',
          createdAt: DateTime(2026, 1, 1),
          openingBalance: 0,
          creditCard: card,
        );

    Future<void> pumpForm(
      WidgetTester tester, {
      required WalletEntity w,
      required void Function(List<TransactionEntity>) onInstallments,
    }) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
        (_) async => [
          const CategoryEntity(
            id: 'Food',
            name: 'Food',
            iconName: 'fastfood',
            isExpense: true,
          ),
        ],
      );
      final bloc = _MockWalletBloc();
      when(() => bloc.state).thenReturn(WalletLoadedSt([w], w));
      await tester.pumpWidget(BlocProvider<WalletBloc>.value(
        value: bloc,
        child: buildTestableWidget(
          TransactionFormSheet(
            isExpense: true,
            walletId: 'wallet_123',
            userId: 'user_123',
            onSave: (_, __) {},
            onSaveInstallments: onInstallments,
            onCancel: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets(
        '3 taksit seçilince aylık satırlar üretilir (son taksit kuruşu emer)',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      List<TransactionEntity>? saved;
      await pumpForm(
        tester,
        w: wallet(card: const CreditCardInfo(closingDay: 15, dueDay: 25)),
        onInstallments: (rows) => saved = rows,
      );

      await tester.enterText(
          find.byWidgetPredicate(
              (w) => w is TextField && w.keyboardType.decimal == true),
          '1000');
      await tester.ensureVisible(find.text('Food'));
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10n.tekCekim));
      await tester.tap(find.text(l10n.tekCekim));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.taksitSecenek(3)).last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Kaydet'));
      await tester.tap(find.text('Kaydet'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(saved, hasLength(3));
      expect(saved!.map((t) => t.amount), [333.33, 333.33, 333.34]);
      expect(saved!.first.title, endsWith('(1/3)'));
    });

    testWidgets('düz cüzdanda taksit seçici YOK', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await pumpForm(tester, w: wallet(), onInstallments: (_) {});
      expect(find.text(l10n.tekCekim), findsNothing);
    });
  });

  // Kart cüzdanın İÇİNDE bir ödeme yöntemidir: kullanıcı karta "geçmeden"
  // gider formunda "Nereden ödendi?" ile kartı seçer, kayıt kartın
  // defterine gider (bkz. card_family.dart).
  group('ödeme yöntemi: hesap ↔ bağlı kart', () {
    WalletEntity w(String id,
            {String name = 'Banka',
            String currency = 'TRY',
            CreditCardInfo? card}) =>
        WalletEntity(
          id: id,
          userId: 'user_123',
          name: name,
          balance: 0,
          debt: 0,
          credit: 0,
          investment: 0,
          colorHex: '0xFF37474F',
          iconName: card == null ? 'wallet' : 'credit_card',
          createdAt: DateTime(2026, 1, 1),
          openingBalance: 0,
          currency: currency,
          creditCard: card,
        );

    final bank = w('bank');
    final bonus = w('bonus',
        name: 'Bonus',
        card: const CreditCardInfo(
            closingDay: 15,
            dueDay: 25,
            last4: '5690',
            paymentWalletId: 'bank'));

    Future<void> pumpForm(
      WidgetTester tester, {
      required List<WalletEntity> wallets,
      required String walletId,
      TransactionEntity? initial,
      void Function(TransactionEntity)? onSave,
      void Function(List<TransactionEntity>)? onInstallments,
    }) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
        (_) async => [
          const CategoryEntity(
            id: 'Food',
            name: 'Food',
            iconName: 'fastfood',
            isExpense: true,
          ),
        ],
      );
      final bloc = _MockWalletBloc();
      when(() => bloc.state).thenReturn(
          WalletLoadedSt(wallets, wallets.firstWhere((x) => x.id == walletId)));
      await tester.pumpWidget(BlocProvider<WalletBloc>.value(
        value: bloc,
        child: buildTestableWidget(
          TransactionFormSheet(
            isExpense: true,
            walletId: walletId,
            userId: 'user_123',
            initialTransaction: initial,
            onSave: (t, _) => onSave?.call(t),
            onSaveInstallments: (rows) => onInstallments?.call(rows),
            onCancel: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> fillAndPickFood(WidgetTester tester) async {
      await tester.enterText(
          find.byWidgetPredicate(
              (w) => w is TextField && w.keyboardType.decimal == true),
          '900');
      await tester.ensureVisible(find.text('Food'));
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'hesaptan açılınca varsayılan hesap; karta dokununca taksit açılır ve '
        'kayıt KARTIN defterine gider', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      List<TransactionEntity>? rows;
      await pumpForm(tester,
          wallets: [bank, bonus],
          walletId: 'bank',
          onInstallments: (r) => rows = r);

      expect(find.text(l10n.kkOdemeYontemi), findsOneWidget);
      expect(find.text('Banka'), findsOneWidget);
      expect(find.text('Bonus ••5690'), findsOneWidget);
      expect(find.text(l10n.tekCekim), findsNothing,
          reason: 'hesapta taksit yok');

      await tester.tap(find.text('Bonus ••5690'));
      await tester.pumpAndSettle();
      await fillAndPickFood(tester);
      await tester.ensureVisible(find.text(l10n.tekCekim));
      await tester.tap(find.text(l10n.tekCekim));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.taksitSecenek(3)).last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Kaydet'));
      await tester.tap(find.text('Kaydet'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(rows, hasLength(3));
      expect(rows!.every((t) => t.walletId == 'bonus'), isTrue);
    });

    testWidgets(
        'karttan hesaba dönünce seçili taksit SIFIRLANIR; tek kayıt hesaba',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      TransactionEntity? saved;
      List<TransactionEntity>? rows;
      await pumpForm(tester,
          wallets: [bank, bonus],
          walletId: 'bonus',
          onSave: (t) => saved = t,
          onInstallments: (r) => rows = r);

      await fillAndPickFood(tester);
      await tester.ensureVisible(find.text(l10n.tekCekim));
      await tester.tap(find.text(l10n.tekCekim));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.taksitSecenek(3)).last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Banka'));
      await tester.tap(find.text('Banka'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.taksitSecenek(3)), findsNothing);

      await tester.ensureVisible(find.text('Kaydet'));
      await tester.tap(find.text('Kaydet'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(rows, isNull, reason: 'gizli taksit kayda sızmamalı');
      expect(saved!.walletId, 'bank');
      expect(saved!.amount, 900);
    });

    testWidgets(
        'farklı birimdeki kart önerilmez; tek seçenek kalınca seçici '
        'hiç görünmez', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final usdCard = w('usd',
          name: 'Dolar Kart',
          currency: 'USD',
          card: const CreditCardInfo(
              closingDay: 1, dueDay: 11, paymentWalletId: 'bank'));
      await pumpForm(tester, wallets: [bank, usdCard], walletId: 'bank');
      expect(find.text(l10n.kkOdemeYontemi), findsNothing);
    });

    testWidgets('düzenlemede seçici YOK (kayıt cüzdan değiştirmez)',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await pumpForm(
        tester,
        wallets: [bank, bonus],
        walletId: 'bank',
        initial: TransactionEntity(
          id: 't1',
          userId: 'user_123',
          walletId: 'bank',
          title: 'Market',
          tag: 'Food',
          amount: 10,
          date: DateTime(2026, 9, 1),
          type: TransactionTypeModel.expense,
        ),
      );
      expect(find.text(l10n.kkOdemeYontemi), findsNothing);
    });
  });
}
