import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/credit_card/presentation/card_statement_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_setup_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_tile.dart';
import 'package:cunehat/features/credit_card/presentation/wallet_card_stack.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/widgets/transfer_sheet.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class _MockTxRepo extends Mock implements TransactionsRepository {}

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
  setUpAll(() => registerFallbackValue(const GetWalletsEvent('u')));

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    bloc = _MockWalletBloc();
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

      final sheet = tester.widget<TransferSheet>(find.byType(TransferSheet));
      expect(sheet.initialFrom.id, 'bank');
      expect(sheet.initialTo?.id, 'card');
      expect(sheet.amountSuggestions.single.amount, 500);
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

      expect(find.text(l10n.kkKalanDonemBorcu), findsOneWidget);
      expect(find.byKey(const ValueKey('ctx-card-pay')), findsOneWidget);
      // Kart son kesimden ÖNCE açılmış: dönem borcu defterden güvenilir,
      // ekstre ipucu yok.
      expect(find.byKey(const ValueKey('ctx-card-statement')), findsNothing);

      await tester.tap(find.text('Banka'));
      final event = verify(() => bloc.add(captureAny())).captured.single
          as SetActiveWalletEvent;
      expect(event.walletId, 'bank');
    });

    testWidgets(
        'kart son kesimden SONRA eklendi, ekstre yok: tutar "≈" ile, '
        '"Ekstreyi gir" ekstre sayfasını açar', (tester) async {
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

      expect(find.textContaining('≈ '), findsOneWidget);
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
