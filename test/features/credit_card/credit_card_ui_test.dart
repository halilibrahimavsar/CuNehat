import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/credit_card/presentation/card_statement_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_setup_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/credit_cards_tab.dart';
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

  Widget app(Widget child) => BlocProvider<WalletBloc>.value(
        value: bloc,
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
        'yeni kart: açılış = −borç, aktif cüzdan DEĞİŞMEZ, kategoriler ödeme '
        'cüzdanından, son ekstre son kesime yazılır', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final bank = _wallet('bank', categoryIds: const ['cat-a', 'cat-b']);
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [bank],
        defaultCurrency: 'TRY',
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
      // Ödeme cüzdanı: Banka.
      await tester.tap(find.text(l10n.kkSecilmedi));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Banka').last);
      await tester.pumpAndSettle();

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

    testWidgets('son 4 hane eksikse kaydedilmez', (tester) async {
      tall(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.pumpWidget(app(CreditCardSetupSheet(
        userId: 'u',
        wallets: [_wallet('bank')],
        defaultCurrency: 'TRY',
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

  group('CreditCardsTab', () {
    testWidgets('kart yoksa boş durum + "Kart ekle"', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      when(() => bloc.state)
          .thenReturn(WalletLoadedSt([_wallet('bank')], _wallet('bank')));
      await tester.pumpWidget(app(const CreditCardsTab(
        userId: 'u',
        defaultCurrency: 'TRY',
      )));
      await tester.pumpAndSettle();

      expect(find.text(l10n.kkBosBaslik), findsOneWidget);
      expect(find.text(l10n.kkKartEkle), findsOneWidget);
      // Tek düz cüzdan varsa onu karta çevirme önerilmez.
      expect(find.text(l10n.kkMevcutCevir), findsNothing);
    });
  });
}
