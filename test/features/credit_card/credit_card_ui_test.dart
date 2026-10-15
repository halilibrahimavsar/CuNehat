import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/credit_card/presentation/card_statement_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_setup_sheet.dart';
import 'package:cunehat/core/services/transfer_service.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'package:cunehat/features/credit_card/presentation/card_pay_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_tile.dart';
import 'package:cunehat/features/credit_card/presentation/wallet_card_stack.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockTransferService extends Mock implements TransferService {}

WalletEntity _wallet(
  String id, {
  String name = 'Banka',
  double balance = 10000,
  List<String>? categoryIds,
  CreditCardInfo? card,
  DateTime? createdAt,
  double? opening,
}) =>
    WalletEntity(
      id: id,
      userId: 'u',
      name: name,
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF2196F3',
      iconName: 'wallet',
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      openingBalance: opening ?? balance,
      categoryIds: categoryIds,
      creditCard: card,
    );

void main() {
  late _MockWalletBloc bloc;

  // WalletEvent mühürlü: sahte alt sınıf yazılamaz, gerçek bir olay verilir.
  setUpAll(() {
    // Şeritteki tanıtım turu (Showcase) — uygulamada küresel kayıtlı.
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
    registerFallbackValue(const GetWalletsEvent('u'));
    registerFallbackValue(_wallet('fallback'));
  });

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    SharedPreferences.setMockInitialValues({});
    bloc = _MockWalletBloc();
    // Kart ayarları sayfası kartın GÜNCEL hâlini bloc'tan okur (ekstre
    // bilgisi sayfa açıkken değişebilir). Durumu ayrıca kuran testler bunu
    // ezer.
    when(() => bloc.state).thenReturn(WalletLoadingSt());
  });

  tearDown(() async => getIt.reset());

  Widget app(Widget child) => MultiBlocProvider(
        providers: [
          BlocProvider<WalletBloc>.value(value: bloc),
          // Kart görselindeki tutar (MoneyText) göz düğmesine uyar.
          BlocProvider<AmountVisibilityCubit>(
              create: (_) => AmountVisibilityCubit()),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('CreditCardSetupSheet', () {
    testWidgets(
        'yeni kart (cüzdanın kutusundan): bağlı cüzdan önceden seçili, '
        'açılış = −borç, aktif cüzdan DEĞİŞMEZ, kategoriler bağlı cüzdandan, '
        'son ekstre son kesime yazılır', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final bank = _wallet('bank', categoryIds: const ['cat-a', 'cat-b']);
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [bank],
        defaultCurrency: 'TRY',
        ownerWalletId: 'bank',
        today: DateTime(2026, 9, 20),
      )));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.kkKartAdi), 'Bonus');
      await tester.tap(find.byKey(const ValueKey('kk-more-toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.kkSon4), '5690');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.kkGuncelBorc), '2.500');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.kkDonemBorcu), '1.800');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.kkAsgariOdeme), '720');
      // Bağlı cüzdan kutudan geldi: seçmeye gerek yok.
      expect(find.text('Banka'), findsOneWidget);

      await tester.tap(find.text(l10n.kaydet));
      await tester.pumpAndSettle();

      final event = verify(() => bloc.add(captureAny())).captured.single
          as CreateWalletEvent;
      expect(event.activate, isFalse);
      final w = event.wallet;
      expect(w.name, 'Bonus');
      expect(w.openingBalance, -2500);
      expect(w.balance, -2500);
      expect(w.iconName, 'credit_card');
      expect(w.colorHex, '0xFF37474F', reason: 'ilk kart: arduvaz');
      expect(w.categoryIds, ['cat-a', 'cat-b']);
      final card = w.creditCard!;
      expect(card.closingDay, 15);
      expect(card.dueDay, 25, reason: 'varsayılan kesim + 10');
      expect(card.last4, '5690');
      expect(card.paymentWalletId, 'bank');
      expect(card.lastStatement!.closingDate, DateTime(2026, 9, 15));
      expect(card.lastStatement!.dueDate, DateTime(2026, 9, 25));
      expect(card.lastStatement!.statementBalance, 1800);
      expect(card.lastStatement!.minimumPayment, 720);
    });

    testWidgets(
        'aynı cüzdanın ikinci kartı FARKLI renk alır (deste ayırt '
        'edilsin)', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final bank = _wallet('bank');
      final first = _wallet('c1',
          card: const CreditCardInfo(
              closingDay: 15, dueDay: 25, paymentWalletId: 'bank'));
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [bank, first.copyWith(colorHex: '0xFF37474F')],
        defaultCurrency: 'TRY',
        ownerWalletId: 'bank',
      )));
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.kkKartAdi), 'World');
      await tester.tap(find.text(l10n.kaydet));
      await tester.pumpAndSettle();
      final event = verify(() => bloc.add(captureAny())).captured.single
          as CreateWalletEvent;
      expect(event.wallet.colorHex, isNot('0xFF37474F'));
    });

    testWidgets('bağlı cüzdan seçilmeden kaydedilmez', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [_wallet('bank'), _wallet('cash', name: 'Nakit')],
        defaultCurrency: 'TRY',
      )));
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.kkKartAdi), 'Bonus');
      await tester.tap(find.text(l10n.kaydet));
      await tester.pumpAndSettle();

      expect(find.text(l10n.kkBagliCuzdanGerekli), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets(
        'yeni kart formundan "var olan cüzdanı kart yap": hedef o cüzdan olur, '
        'bağlı cüzdan korunur, borç sorusu kalkar', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final bank = _wallet('bank');
      final old = _wallet('old', name: 'Eski Kart Cüzdanı', balance: -900);
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [bank, old],
        defaultCurrency: 'TRY',
        ownerWalletId: 'bank',
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('kk-convert-link')));
      await tester.pumpAndSettle();
      // Bağlı cüzdan (Banka) çevrilebilecekler arasında değil.
      expect(find.widgetWithText(ListTile, 'Banka'), findsNothing);
      await tester.tap(find.text('Eski Kart Cüzdanı'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.kkCevirBaslik), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, l10n.kkGuncelBorc), findsNothing);
      await tester.tap(find.text(l10n.kaydet));
      await tester.pumpAndSettle();

      final event = verify(() => bloc.add(captureAny())).captured.single
          as UpdateWalletEvent;
      expect(event.wallet.id, 'old');
      expect(event.wallet.balance, -900);
      expect(event.wallet.creditCard!.paymentWalletId, 'bank');
    });

    testWidgets(
        'yeni kart KISA açılır: banka/son 4/limit/son ekstre "daha fazla" '
        'altında; ayarlarda hepsi açık', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [_wallet('bank')],
        defaultCurrency: 'TRY',
        ownerWalletId: 'bank',
      )));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, l10n.kkSon4), findsNothing);
      expect(find.widgetWithText(TextFormField, l10n.kkLimit), findsNothing);
      expect(find.widgetWithText(TextFormField, l10n.kkGuncelBorc),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('kk-more-toggle')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, l10n.kkSon4), findsOneWidget);

      final card = _wallet('c',
          card: const CreditCardInfo(
              closingDay: 15, dueDay: 25, paymentWalletId: 'bank'));
      await tester.pumpWidget(app(CreditCardSetupSheet(
        key: const ValueKey('edit'),
        userId: 'u',
        wallets: [_wallet('bank'), card],
        wallet: card,
        defaultCurrency: 'TRY',
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('kk-more-toggle')), findsNothing);
      expect(find.widgetWithText(TextFormField, l10n.kkSon4), findsOneWidget);
    });

    testWidgets('ayarlarda seçilen kart rengi kaydedilir', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final card = _wallet('c',
              name: 'Bonus',
              card: const CreditCardInfo(
                  closingDay: 15, dueDay: 25, paymentWalletId: 'bank'))
          .copyWith(colorHex: '0xFF37474F');
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [_wallet('bank'), card],
        wallet: card,
        defaultCurrency: 'TRY',
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('kk-color-0xFF7B1F3A')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.kaydet));
      await tester.pumpAndSettle();
      final event = verify(() => bloc.add(captureAny())).captured.single
          as UpdateWalletEvent;
      expect(event.wallet.colorHex, '0xFF7B1F3A');
    });

    testWidgets('son 4 hane eksikse kaydedilmez', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [_wallet('bank')],
        defaultCurrency: 'TRY',
        ownerWalletId: 'bank',
      )));
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.kkKartAdi), 'Bonus');
      await tester.tap(find.byKey(const ValueKey('kk-more-toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.kkSon4), '56');
      await tester.tap(find.text(l10n.kaydet));
      await tester.pumpAndSettle();

      expect(find.text(l10n.kkSon4Hatasi), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets(
        'var olan cüzdanı çevir: bakiye/defter olduğu gibi (baseline = '
        'bakiye), borç sorusu YOK', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final manualCard = _wallet('mc', name: 'Kartım', balance: -3200);
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [_wallet('bank'), manualCard],
        wallet: manualCard,
        defaultCurrency: 'TRY',
        ownerWalletId: 'bank',
      )));
      await tester.pumpAndSettle();

      expect(
          find.widgetWithText(TextFormField, l10n.kkGuncelBorc), findsNothing);
      await tester.tap(find.text(l10n.kaydet));
      await tester.pumpAndSettle();

      final event = verify(() => bloc.add(captureAny())).captured.single
          as UpdateWalletEvent;
      expect(event.baselineBalance, -3200);
      expect(event.wallet.balance, -3200);
      expect(event.wallet.isCreditCard, isTrue);
      expect(event.wallet.iconName, 'credit_card');
    });
  });

  group('kart ayarları: tutarlar, faiz, gün farkı, ekstre (12 Eki 2026)', () {
    const info = CreditCardInfo(
      closingDay: 25,
      dueDay: 5,
      limit: 20000,
      paymentWalletId: 'bank',
    );

    Future<AppLocalizations> pumpSettings(
      WidgetTester tester,
      WalletEntity card, {
      DateTime? today,
    }) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [_wallet('bank'), card],
        wallet: card,
        defaultCurrency: 'TRY',
        today: today ?? DateTime(2026, 10, 12),
      )));
      await tester.pumpAndSettle();
      return l10n;
    }

    Future<UpdateWalletEvent> save(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('kk-save')));
      await tester.pumpAndSettle();
      return verify(() => bloc.add(captureAny())).captured.single
          as UpdateWalletEvent;
    }

    String fieldText(WidgetTester tester, String key) => tester
        .widget<TextFormField>(find.byKey(ValueKey(key)))
        .controller!
        .text;

    testWidgets('borç ve LİMİT "ayrıntı"ya inmeden görünür; borç ön dolu',
        (tester) async {
      await pumpSettings(tester, _wallet('c', balance: -3700, card: info));

      expect(find.text('Tutarlar'), findsOneWidget);
      expect(fieldText(tester, 'kk-debt'), '3.700');
      expect(fieldText(tester, 'kk-limit'), '20.000');
      // Borç, limitin ÜSTÜNDE ve ikisi de banka/son 4'ten önce.
      expect(
          tester.getTopLeft(find.byKey(const ValueKey('kk-debt'))).dy,
          lessThan(
              tester.getTopLeft(find.byKey(const ValueKey('kk-limit'))).dy));
    });

    testWidgets(
        'borç değiştirilince bakiye düzeltilir; taban açılıştaki bakiye',
        (tester) async {
      await pumpSettings(tester, _wallet('c', balance: -3700, card: info));

      await tester.enterText(find.byKey(const ValueKey('kk-debt')), '4.000');
      final event = await save(tester);

      // Fark (−300) bloc'ta açılış bakiyesine yansır; deftere işlem yazılmaz.
      expect(event.wallet.balance, -4000);
      expect(event.baselineBalance, -3700);
    });

    testWidgets('borca DOKUNULMAZSA bakiye yazılmaz', (tester) async {
      await pumpSettings(tester, _wallet('c', balance: -3700, card: info));

      await tester.enterText(find.byKey(const ValueKey('kk-limit')), '25000');
      final event = await save(tester);

      expect(event.wallet.balance, -3700);
      expect(event.baselineBalance, -3700);
      expect(event.wallet.creditCard!.limit, 25000);
    });

    testWidgets('borç alanı boşaltılırsa borç sıfırlanır', (tester) async {
      await pumpSettings(tester, _wallet('c', balance: -3700, card: info));

      await tester.enterText(find.byKey(const ValueKey('kk-debt')), '');
      final event = await save(tester);

      expect(event.wallet.balance, 0);
    });

    testWidgets(
        'alacaklı kartta (fazla ödeme) alan boş açılır; dokunmadan '
        'kaydetmek alacağı SİLMEZ', (tester) async {
      await pumpSettings(tester, _wallet('c', balance: 150, card: info));

      expect(fieldText(tester, 'kk-debt'), isEmpty);
      final event = await save(tester);

      expect(event.wallet.balance, 150);
    });

    testWidgets('faiz oranları kaydedilir; boş bırakılan null kalır',
        (tester) async {
      await pumpSettings(tester, _wallet('c', balance: -3700, card: info));

      await tester.enterText(
          find.byKey(const ValueKey('kk-monthly-rate')), '4,25');
      final event = await save(tester);

      expect(event.wallet.creditCard!.monthlyInterestRate, 4.25);
      expect(event.wallet.creditCard!.lateInterestRate, isNull);
    });

    testWidgets('kayıtlı oranlar ön dolu gelir ve silinebilir', (tester) async {
      await pumpSettings(
          tester,
          _wallet('c',
              balance: -3700,
              card: info.copyWith(
                  monthlyInterestRate: 4.25, lateInterestRate: 4.55)));

      expect(fieldText(tester, 'kk-monthly-rate'), '4,25');
      expect(fieldText(tester, 'kk-late-rate'), '4,55');

      await tester.enterText(find.byKey(const ValueKey('kk-late-rate')), '');
      final event = await save(tester);

      expect(event.wallet.creditCard!.monthlyInterestRate, 4.25);
      expect(event.wallet.creditCard!.lateInterestRate, isNull);
    });

    testWidgets('anlamsız oran (150) reddedilir, hiçbir şey yazılmaz',
        (tester) async {
      final l10n =
          await pumpSettings(tester, _wallet('c', balance: -3700, card: info));

      await tester.enterText(
          find.byKey(const ValueKey('kk-monthly-rate')), '150');
      await tester.tap(find.byKey(const ValueKey('kk-save')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.kkFaizOraniHatasi), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets(
        '"Kesimden N gün sonra" kipi gün farkını yazar; önizleme '
        'değişir', (tester) async {
      final l10n =
          await pumpSettings(tester, _wallet('c', balance: -3700, card: info));
      // Son kesim 25 Eyl 2026; sabit gün 5 → 5 Eki.
      expect(find.byKey(const ValueKey('kk-due-day')), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('kk-due-preview')))
              .data,
          '25 Eyl kesiminin son ödemesi: 5 Eki');

      await tester.tap(find.text(l10n.kkSonOdemeKipiFark));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('kk-due-offset')), findsOneWidget);
      expect(find.byKey(const ValueKey('kk-due-day')), findsNothing);

      // Varsayılan 10 gün → yine 5 Eki; 12 seçilince 7 Eki.
      await tester.tap(find.byKey(const ValueKey('kk-due-offset')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12').last);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('kk-due-preview')))
              .data,
          '25 Eyl kesiminin son ödemesi: 7 Eki');

      final event = await save(tester);
      expect(event.wallet.creditCard!.dueOffsetDays, 12);
      // Sabit gün de tutarlı yazılır (ayar bir gün kaldırılırsa anlamlı kalsın).
      expect(event.wallet.creditCard!.dueDay, 7);
    });

    testWidgets(
        'gün farkı kayıtlı kart o kipte açılır; "Ayın günü"ne '
        'dönülünce ayar kalkar', (tester) async {
      final l10n = await pumpSettings(tester,
          _wallet('c', balance: -3700, card: info.copyWith(dueOffsetDays: 12)));
      expect(find.byKey(const ValueKey('kk-due-offset')), findsOneWidget);

      await tester.tap(find.text(l10n.kkSonOdemeKipiGun));
      await tester.pumpAndSettle();
      final event = await save(tester);

      expect(event.wallet.creditCard!.dueOffsetDays, isNull);
      expect(event.wallet.creditCard!.dueDay, 5);
    });

    testWidgets(
        'ekstre satırı kartın GÜNCEL beyanını gösterir ve kaydederken '
        'onu korur', (tester) async {
      final stale = _wallet('c', balance: -3700, card: info);
      // Sayfa açıkken "Ekstre bilgisi"nden yeni beyan girildi: bloc güncel.
      final statement = CardStatement(
        closingDate: DateTime(2026, 9, 25),
        dueDate: DateTime(2026, 10, 5),
        statementBalance: 2150,
        minimumPayment: 860,
        recordedAt: DateTime(2026, 9, 26),
      );
      final fresh =
          stale.copyWith(creditCard: info.copyWith(lastStatement: statement));
      when(() => bloc.state)
          .thenReturn(WalletLoadedSt([_wallet('bank'), fresh], fresh));

      await pumpSettings(tester, stale);

      expect(find.text('Son ekstre'), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('kk-statement-summary')))
              .data,
          'Dönem borcu 2.150,00 ₺ · asgari 860,00 ₺');

      final event = await save(tester);
      // Açılıştaki (beyansız) kopyayı yazmak yeni beyanı geri alırdı.
      expect(event.wallet.creditCard!.lastStatement, statement);
    });

    testWidgets('beyan yokken ekstre satırı bunu söyler', (tester) async {
      final l10n =
          await pumpSettings(tester, _wallet('c', balance: -3700, card: info));
      expect(find.text(l10n.kkEkstreHenuzYok), findsOneWidget);
    });

    testWidgets('klavye açıkken Kaydet görünür kalır (kaydırmanın dışında)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(Align(
        alignment: Alignment.bottomCenter,
        child: CreditCardSetupSheet(
          userId: 'u',
          wallets: [_wallet('bank'), _wallet('c', balance: -3700, card: info)],
          wallet: _wallet('c', balance: -3700, card: info),
          defaultCurrency: 'TRY',
          today: DateTime(2026, 10, 12),
        ),
      )));
      await tester.pumpAndSettle();

      final save = tester.getRect(find.byKey(const ValueKey('kk-save')));
      expect(save.bottom, lessThanOrEqualTo(800 - 320));
      expect(save.top, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });

  group('faiz tahmini (kart ayrıntısı ve ödeme sayfası)', () {
    CardStatus status({
      double statementDebt = 10000,
      double? minimum = 4000,
      int daysToDue = 5,
    }) =>
        CardStatus(
          lastClosing: DateTime(2026, 9, 25),
          dueDate: DateTime(2026, 10, 5),
          nextClosing: DateTime(2026, 10, 25),
          derivedStatementDebt: statementDebt,
          derivedReliable: true,
          declared: CardStatement(
            closingDate: DateTime(2026, 9, 25),
            dueDate: DateTime(2026, 10, 5),
            statementBalance: statementDebt,
            minimumPayment: minimum,
            recordedAt: DateTime(2026, 9, 26),
          ),
          paidSinceClosing: 0,
          currentDebt: statementDebt,
          availableLimit: null,
          futureInstallments: 0,
          daysToDue: daysToDue,
        );

    Future<void> pumpPay(WidgetTester tester, CreditCardInfo card) async {
      tall(tester);
      await tester.pumpWidget(app(Align(
        alignment: Alignment.bottomCenter,
        child: CardPaySheet(
          card: _wallet('card', name: 'Bonus', balance: -10000, card: card),
          payers: [_wallet('bank', balance: 50000)],
          status: status(),
        ),
      )));
      await tester.pumpAndSettle();
    }

    const base =
        CreditCardInfo(closingDay: 25, dueDay: 5, paymentWalletId: 'bank');
    final estimate = find.byKey(const ValueKey('pay-interest-estimate'));

    testWidgets('dönem borcunun tamamı ödenirken tahmin YOK', (tester) async {
      await pumpPay(tester, base.copyWith(monthlyInterestRate: 4.25));
      expect(estimate, findsNothing);
    });

    testWidgets('asgari seçilince kalanın faizi yazılır', (tester) async {
      await pumpPay(tester, base.copyWith(monthlyInterestRate: 4.25));

      await tester.tap(find.byKey(const ValueKey('pay-option-minimum')));
      await tester.pumpAndSettle();

      // 10.000 − 4.000 = 6.000 × %4,25 = 255.
      expect(estimate, findsOneWidget);
      expect(
          find.descendant(
              of: estimate,
              matching:
                  find.textContaining('6.000,00 ₺ için bir ayda ≈ 255,00 ₺')),
          findsOneWidget);
    });

    testWidgets('oran girilmemişse hiçbir seçenekte tahmin YOK',
        (tester) async {
      await pumpPay(tester, base);

      await tester.tap(find.byKey(const ValueKey('pay-option-minimum')));
      await tester.pumpAndSettle();
      expect(estimate, findsNothing);
    });
  });

  group('CardStatementSheet', () {
    testWidgets(
        'kayıtlardan türetilen dönem borcuyla dolu açılır, beyanı yazar',
        (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final card = _wallet('card',
          name: 'Bonus',
          balance: -800,
          card: const CreditCardInfo(closingDay: 15, dueDay: 25));
      final status = computeCardStatus(
        card: card.creditCard!,
        openingBalance: -800,
        walletCreatedAt: DateTime(2026, 8, 1),
        ledger: const [],
        today: DateTime(2026, 9, 20),
      );

      await tester
          .pumpWidget(app(CardStatementSheet(card: card, status: status)));
      await tester.pumpAndSettle();

      final balanceField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, l10n.kkDonemBorcu));
      expect(balanceField.controller!.text, '800');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.kkAsgariOdeme), '320');
      await tester.tap(find.text(l10n.kaydet));
      await tester.pumpAndSettle();

      final event = verify(() => bloc.add(captureAny())).captured.single
          as UpdateWalletEvent;
      final st = event.wallet.creditCard!.lastStatement!;
      expect(st.closingDate, DateTime(2026, 9, 15));
      expect(st.dueDate, DateTime(2026, 9, 25));
      expect(st.statementBalance, 800);
      expect(st.minimumPayment, 320);
      expect(event.baselineBalance, -800);
    });
  });

  group('CreditCardTile', () {
    testWidgets(
        'kalan dönem borcu, kalan gün ve "Öde" → kart hedefli transfer + '
        'öneri çipi', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final repo = _MockTxRepo();
      getIt.registerSingleton<TransactionsRepository>(repo);
      when(() => repo.getTransactions(
            userId: any(named: 'userId'),
            walletId: 'card',
          )).thenAnswer((_) async => Right([
            TransactionEntity(
              id: 't1',
              userId: 'u',
              walletId: 'card',
              title: 'MARKET',
              tag: 'cat-a',
              amount: 800,
              date: DateTime(2026, 9, 10),
              type: TransactionTypeModel.expense,
            ),
            TransactionEntity(
              id: 't2',
              userId: 'u',
              walletId: 'card',
              title: 'Transfer ← Banka',
              tag: CashMovementTags.transfer,
              amount: 300,
              date: DateTime(2026, 9, 18),
              type: TransactionTypeModel.income,
              isSystem: true,
            ),
          ]));
      final bank = _wallet('bank');
      final card = _wallet('card',
          name: 'Bonus',
          balance: -500,
          opening: 0,
          createdAt: DateTime(2026, 8, 1),
          card: const CreditCardInfo(
            closingDay: 15,
            dueDay: 25,
            paymentWalletId: 'bank',
          ));

      await tester.pumpWidget(app(CreditCardTile(
        card: card,
        wallets: [bank, card],
        today: DateTime(2026, 9, 20),
      )));
      await tester.pumpAndSettle();

      expect(find.text(l10n.kkGunKaldi(5)), findsOneWidget);
      expect(find.text(l10n.kkEkstreGirilmedi), findsOneWidget);
      // Dönem borcu 800, kesimden sonra 300 ödendi → kalan 500.
      expect(find.textContaining('500'), findsWidgets);

      await tester.tap(find.text(l10n.kkOde));
      await tester.pumpAndSettle();

      // Özel ödeme sayfası: kaynak kartın SAHİBİ, seçili seçenek kalan dönem
      // borcu; onay transferi o tutarla karta yazar.
      final sheet = tester.widget<CardPaySheet>(find.byType(CardPaySheet));
      expect(sheet.payers.map((w) => w.id), ['bank']);
      expect(find.text(l10n.kkTutariOde('500,00 ₺')), findsOneWidget);

      final transfers = _MockTransferService();
      getIt.registerSingleton<TransferService>(transfers);
      when(() => transfers.transfer(
                from: any(named: 'from'),
                to: any(named: 'to'),
                amount: any(named: 'amount'),
              ))
          .thenAnswer((_) async =>
              const TransferOutcome.failure(TransferResult.failed));
      await tester.tap(find.byKey(const ValueKey('pay-confirm')));
      await tester.pumpAndSettle();
      final call = verify(() => transfers.transfer(
            from: captureAny(named: 'from'),
            to: captureAny(named: 'to'),
            amount: captureAny(named: 'amount'),
          )).captured;
      expect((call[0] as WalletEntity).id, 'bank');
      expect((call[1] as WalletEntity).id, 'card');
      expect(call[2], 500);
    });

    testWidgets(
        'faiz oranı girilmiş kartta "yalnız asgariyi ödersen" tahmini yazar; '
        'oran yoksa yazmaz', (tester) async {
      tall(tester);
      final repo = _MockTxRepo();
      getIt.registerSingleton<TransactionsRepository>(repo);
      when(() => repo.getTransactions(
            userId: any(named: 'userId'),
            walletId: 'card',
          )).thenAnswer((_) async => Right([
            TransactionEntity(
              id: 't1',
              userId: 'u',
              walletId: 'card',
              title: 'MARKET',
              tag: 'cat-a',
              amount: 800,
              date: DateTime(2026, 9, 10),
              type: TransactionTypeModel.expense,
            ),
          ]));
      final info = CreditCardInfo(
        closingDay: 15,
        dueDay: 25,
        paymentWalletId: 'bank',
        lastStatement: CardStatement(
          closingDate: DateTime(2026, 9, 15),
          dueDate: DateTime(2026, 9, 25),
          statementBalance: 800,
          minimumPayment: 320,
          recordedAt: DateTime(2026, 9, 16),
        ),
      );
      WalletEntity card(CreditCardInfo i) => _wallet('card',
          name: 'Bonus',
          balance: -800,
          opening: 0,
          createdAt: DateTime(2026, 8, 1),
          card: i);
      final bank = _wallet('bank');
      final estimate = find.byKey(const ValueKey('kk-interest-estimate'));

      await tester.pumpWidget(app(CreditCardTile(
        key: const ValueKey('oransiz'),
        card: card(info),
        wallets: [bank, card(info)],
        today: DateTime(2026, 9, 20),
      )));
      await tester.pumpAndSettle();
      expect(estimate, findsNothing);

      final rated = card(info.copyWith(monthlyInterestRate: 5));
      await tester.pumpWidget(app(CreditCardTile(
        key: const ValueKey('oranli'),
        card: rated,
        wallets: [bank, rated],
        today: DateTime(2026, 9, 20),
      )));
      await tester.pumpAndSettle();

      // 800 − 320 = 480 devreder × %5 = 24.
      expect(
          find.descendant(
              of: estimate,
              matching:
                  find.textContaining('480,00 ₺ için bir ayda ≈ 24,00 ₺')),
          findsOneWidget);
    });

    testWidgets(
        'ekstre ile defter farkı YÖNÜYLE söylenir; limit çubuğu etiketlidir '
        '(smoke C-40/C-41)', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final handle = tester.ensureSemantics();
      final repo = _MockTxRepo();
      getIt.registerSingleton<TransactionsRepository>(repo);
      when(() => repo.getTransactions(
            userId: any(named: 'userId'),
            walletId: 'card',
          )).thenAnswer((_) async => Right([
            TransactionEntity(
              id: 't1',
              userId: 'u',
              walletId: 'card',
              title: 'MARKET',
              tag: 'cat-a',
              amount: 800,
              date: DateTime(2026, 9, 10),
              type: TransactionTypeModel.expense,
            ),
          ]));
      CreditCardInfo info(double declared) => CreditCardInfo(
            closingDay: 15,
            dueDay: 25,
            paymentWalletId: 'bank',
            limit: 50000,
            lastStatement: CardStatement(
              closingDate: DateTime(2026, 9, 15),
              dueDate: DateTime(2026, 9, 25),
              statementBalance: declared,
              recordedAt: DateTime(2026, 9, 16),
            ),
          );
      Future<void> pumpDeclared(double declared) async {
        final card = _wallet('card',
            name: 'Bonus',
            balance: -800,
            opening: 0,
            createdAt: DateTime(2026, 8, 1),
            card: info(declared));
        await tester.pumpWidget(app(CreditCardTile(
          key: ValueKey(declared),
          card: card,
          wallets: [_wallet('bank'), card],
          today: DateTime(2026, 9, 20),
        )));
        await tester.pumpAndSettle();
      }

      // Beyan defterden büyük → kartta yazılmamış harcama aranır.
      await pumpDeclared(850);
      expect(find.text(l10n.kkFarkUyarisiEksik('50,00 ₺')), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.kkLimitKullanimi), findsOneWidget);
      final bar =
          tester.getSemantics(find.bySemanticsLabel(l10n.kkLimitKullanimi));
      expect(bar.value, contains('800,00 ₺ / 50.000,00 ₺'));

      // Beyan defterden küçük → çift ya da bu ekstreye girmeyen kayıt.
      await pumpDeclared(750);
      expect(find.text(l10n.kkFarkUyarisiFazla('50,00 ₺')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('360dp genişlikte taşma yok', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final repo = _MockTxRepo();
      getIt.registerSingleton<TransactionsRepository>(repo);
      when(() => repo.getTransactions(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
          )).thenAnswer((_) async => const Right(<TransactionEntity>[]));
      final card = _wallet('card',
          name: 'Çok uzun adlı bir kredi kartı cüzdanı',
          balance: -123456.78,
          card: const CreditCardInfo(
            bankName: 'Türkiye Garanti Bankası',
            last4: '5690',
            limit: 250000,
            closingDay: 15,
            dueDay: 25,
          ));

      await tester.pumpWidget(app(SingleChildScrollView(
        child: CreditCardTile(
          card: card,
          wallets: [card],
          today: DateTime(2026, 9, 20),
        ),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  WalletEntity bonusCard({String id = 'card', String? owner = 'bank'}) =>
      _wallet(id,
          name: id == 'card' ? 'Bonus' : 'World',
          balance: -500,
          opening: 0,
          createdAt: DateTime(2026, 8, 1),
          card: CreditCardInfo(
            closingDay: 15,
            dueDay: 25,
            last4: id == 'card' ? '5690' : '1234',
            paymentWalletId: owner,
          ));

  void emptyLedger() {
    final repo = _MockTxRepo();
    getIt.registerSingleton<TransactionsRepository>(repo);
    when(() => repo.getTransactions(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async => const Right(<TransactionEntity>[]));
  }

  group('CardContextRail', () {
    testWidgets('kartı olmayan cüzdanda hiç yer kaplamaz', (tester) async {
      when(() => bloc.state)
          .thenReturn(WalletLoadedSt([_wallet('bank')], _wallet('bank')));
      await tester.pumpWidget(app(const CardContextRail()));
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets(
        'hesap bağlamında: hesap + kartları; karta dokununca AKTİF kart olur',
        (tester) async {
      emptyLedger();
      final bank = _wallet('bank');
      final card = bonusCard();
      final other = _wallet('other', name: 'Nakit');
      when(() => bloc.state)
          .thenReturn(WalletLoadedSt([bank, card, other], bank));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();

      expect(find.text('Banka'), findsOneWidget);
      expect(find.text('Bonus ••5690'), findsOneWidget);
      expect(find.text('Nakit'), findsNothing, reason: 'başka aile değil');
      // İlk kart turunun hedefi şeritte (OnboardingFlow.cardRail).
      // (Showcase anahtarı widget anahtarı olarak değil `showcaseKey`de.)
      expect(
          find.byWidgetPredicate(
              (w) => w is Showcase && w.showcaseKey == OnboardingKeys.cardRail),
          findsOneWidget);
      expect(find.byKey(const ValueKey('ctx-card-pay')), findsNothing);

      await tester.tap(find.text('Bonus ••5690'));
      final event = verify(() => bloc.add(captureAny())).captured.single
          as SetActiveWalletEvent;
      expect(event.walletId, 'card');
      expect(event.announce, isFalse, reason: 'sekme değişimi sessiz');
    });

    testWidgets(
        'kart bağlamında: durum şeridi (kalan dönem borcu + Öde) açılır; '
        'hesaba dönüş sahibini aktif yapar', (tester) async {
      emptyLedger();
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final bank = _wallet('bank');
      final card = bonusCard();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], card));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();

      // Defter boş: kesilmiş ekstrede ödenecek bir şey yok. Şerit "Kalan
      // dönem borcu 0,00" yerine bir sonraki ekstreye girecek harcamayı ve
      // sıradaki kesimi yazar (eskiden geçmiş bir "Son ödeme" tarihi vardı).
      expect(find.text(l10n.kkBuDonemHarcanan), findsOneWidget);
      expect(find.textContaining('Sonraki kesim'), findsOneWidget);
      expect(find.byKey(const ValueKey('ctx-card-pay')), findsOneWidget);
      // Kart son kesimden ÖNCE açılmış: dönem borcu defterden güvenilir,
      // ekstre ipucu yok.
      expect(find.byKey(const ValueKey('ctx-card-statement')), findsNothing);

      await tester.tap(find.text('Banka'));
      final event = verify(() => bloc.add(captureAny())).captured.single
          as SetActiveWalletEvent;
      expect(event.walletId, 'bank');
    });

    testWidgets('ödenmemiş ekstre varken şerit KALAN DÖNEM BORCUNU yazar',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final repo = _MockTxRepo();
      getIt.registerSingleton<TransactionsRepository>(repo);
      // Son kesimden 3 gün önceki harcama: kesilmiş ekstrededir.
      final today = DateTime.now();
      final cycle = CardCycle(bonusCard().creditCard!);
      final spentOn =
          cycle.lastClosing(today).subtract(const Duration(days: 3));
      when(() => repo.getTransactions(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
          )).thenAnswer((_) async => Right([
            TransactionEntity(
              id: 't1',
              userId: 'u',
              walletId: 'card',
              title: 'MARKET',
              tag: 'cat-a',
              amount: 500,
              date: spentOn,
              type: TransactionTypeModel.expense,
            ),
          ]));
      final bank = _wallet('bank');
      final card = bonusCard();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], card));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();

      expect(find.text(l10n.kkKalanDonemBorcu), findsOneWidget);
      expect(find.text(l10n.kkBuDonemHarcanan), findsNothing);
    });

    testWidgets(
        'REGRESYON: kart son kesimden SONRA eklendi, ekstre yok: açılış '
        'borcu geçen ekstreye YAZILMAZ (gecikme yok); "Ekstreyi gir" '
        'ekstre sayfasını açar', (tester) async {
      emptyLedger();
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final bank = _wallet('bank');
      final fresh = _wallet('card',
          name: 'Bonus',
          balance: -2500,
          opening: -2500,
          createdAt: DateTime.now(),
          card: const CreditCardInfo(
            closingDay: 15,
            dueDay: 25,
            last4: '5690',
            paymentWalletId: 'bank',
          ));
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, fresh], fresh));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();

      // Eskiden açılış borcunun tamamı geçen ekstreye yazılıyordu:
      // "≈ 2.500 · N gün gecikti" + kırmızı bant + günlük gecikme bildirimi.
      expect(find.textContaining('≈ '), findsNothing);
      expect(find.textContaining('gecikti'), findsNothing);
      expect(find.text(l10n.kkBuDonemHarcanan), findsOneWidget);
      await tester.tap(find.text(l10n.kkEkstreyiGir));
      await tester.pumpAndSettle();
      expect(find.byType(CardStatementSheet), findsOneWidget);
    });

    testWidgets('360dp: uzun adlar ve iki kartla taşma yok', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      emptyLedger();
      final bank = _wallet('bank', name: 'Çok uzun adlı maaş hesabı cüzdanı');
      // En kalabalık şerit: tahmin tutarı + son ödeme çipi + "Ekstreyi gir".
      final card = bonusCard().copyWith(createdAt: DateTime.now());
      when(() => bloc.state).thenReturn(
          WalletLoadedSt([bank, card, bonusCard(id: 'world')], card));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ctx-card-statement')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('WalletCardStack', () {
    Widget stack({
      required List<WalletEntity> cards,
      String? activeId,
      ValueChanged<WalletEntity>? onTap,
    }) =>
        app(Padding(
          padding: const EdgeInsets.all(16),
          child: WalletCardStack(
            cards: cards,
            activeId: activeId,
            onCardTap: onTap ?? (_) {},
            onAdd: () {},
          ),
        ));

    testWidgets(
        'iki kart kapalı deste doğar; ilk dokunuş AÇAR (karta geçmez), '
        'açıkken dokunuş karta geçer', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(stack(
        cards: [bonusCard(), bonusCard(id: 'world')],
        onTap: (c) => tapped.add(c.id!),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('card-stack-closed')), findsOneWidget);
      await tester.tap(find.text('Bonus'));
      await tester.pumpAndSettle();
      expect(tapped, isEmpty, reason: 'kapalı deste yalnız açılır');
      expect(find.byKey(const ValueKey('card-stack-closed')), findsNothing);

      await tester.tap(find.text('World'));
      expect(tapped, ['world']);
    });

    testWidgets('aktif bağlam destedeki bir kartsa deste AÇIK doğar',
        (tester) async {
      await tester.pumpWidget(stack(
        cards: [bonusCard(), bonusCard(id: 'world')],
        activeId: 'world',
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('card-stack-closed')), findsNothing);
    });

    testWidgets('tek kartta deste yok, kart doğrudan dokunulabilir',
        (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
          stack(cards: [bonusCard()], onTap: (c) => tapped.add(c.id!)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('card-stack-toggle')), findsNothing);
      await tester.tap(find.text('Bonus'));
      expect(tapped, ['card']);
    });

    testWidgets('kartsız cüzdanda yalnız "Kart ekle"', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.pumpWidget(stack(cards: const []));
      expect(find.text(l10n.kkKartEkle), findsOneWidget);
    });

    testWidgets('hareket azaltma açıkken açılış anında biter', (tester) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: stack(cards: [bonusCard(), bonusCard(id: 'world')]),
      ));
      await tester.tap(find.byKey(const ValueKey('card-stack-closed')));
      await tester.pump();
      expect(find.byKey(const ValueKey('card-stack-closed')), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
