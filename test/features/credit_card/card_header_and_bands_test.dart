import 'package:cunehat/features/main_feature/utils/app_bar_style_helper.dart';
import 'package:cunehat/features/credit_card/presentation/card_switcher_button.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'package:cunehat/features/credit_card/presentation/card_pay_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/mini_credit_card.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/main_feature/widgets/app_bar_content.dart';
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

WalletEntity _bank({double balance = 10000}) => WalletEntity(
      id: 'bank',
      userId: 'u',
      name: 'Banka',
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF2196F3',
      iconName: 'wallet',
      createdAt: DateTime(2025, 1, 1),
      openingBalance: balance,
    );

/// Kesimi 5 gün önce, son ödemesi [dueInDays] gün sonra olan, beyanlı
/// (1.000 ₺ dönem borcu) kart — "bugün"e göre kurulur ki test ay sonunda da
/// aynı sonucu versin.
WalletEntity _card({int dueInDays = 2, double balance = -3700}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final info = CreditCardInfo(
    closingDay: today.subtract(const Duration(days: 5)).day,
    dueDay: today.add(Duration(days: dueInDays)).day,
    last4: '5690',
    limit: 40000,
    paymentWalletId: 'bank',
  );
  final cycle = CardCycle(info);
  final closing = cycle.lastClosing(today);
  return WalletEntity(
    id: 'card',
    userId: 'u',
    name: 'Bonus',
    balance: balance,
    debt: 0,
    credit: 0,
    investment: 0,
    colorHex: '0xFF37474F',
    iconName: 'credit_card',
    createdAt: DateTime(2025, 1, 1),
    openingBalance: balance,
    creditCard: info.copyWith(
      lastStatement: CardStatement(
        closingDate: closing,
        dueDate: cycle.dueFor(closing),
        statementBalance: 1000,
        recordedAt: today,
      ),
    ),
  );
}

void main() {
  late _MockWalletBloc bloc;

  setUpAll(() => ShowcaseView.register(onFinish: () {}, onDismiss: (_) {}));

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    SharedPreferences.setMockInitialValues({});
    bloc = _MockWalletBloc();
    final repo = _MockTxRepo();
    getIt.registerSingleton<TransactionsRepository>(repo);
    when(() => repo.getTransactions(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async => const Right(<TransactionEntity>[]));
  });

  tearDown(() async => getIt.reset());

  Widget app(Widget child) => MultiBlocProvider(
        providers: [
          BlocProvider<WalletBloc>.value(value: bloc),
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

  Widget header() => SizedBox(
        height: 70,
        child: AppBarContent(
          currentState: SliderState.transactions,
          scaleAnimation: const AlwaysStoppedAnimation(1),
          fadeAnimation: const AlwaysStoppedAnimation(1),
        ),
      );

  group('üst başlık', () {
    testWidgets('kart bağlamı: eksi bakiye değil BORÇ + kullanılabilir limit',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final card = _card();
      when(() => bloc.state).thenReturn(WalletLoadedSt([_bank(), card], card));
      await tester.pumpWidget(app(header()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bonus • Borç'), findsOneWidget);
      expect(find.textContaining('-3.700'), findsNothing);
      expect(find.textContaining('3.700'), findsOneWidget);
      expect(find.text(l10n.kkKullanilabilirLimitSatiri('36.300,00 ₺')),
          findsOneWidget);
    });

    testWidgets(
        'hesap bağlamı: "kart ödemeleri düşülünce" = bakiye − kalan dönem '
        'borcu (gelecek ekstreye girecekler DÜŞÜLMEZ)', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final bank = _bank();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, _card()], bank));
      await tester.pumpWidget(app(header()));
      await tester.pumpAndSettle();

      // Kart borcu 3.700 ama kesilmiş ekstre 1.000 → 10.000 − 1.000.
      expect(find.text(l10n.kkKartlarDusulunce('9.000,00 ₺')), findsOneWidget);
    });

    group('REGRESYON: tutarlar gizliyken başlığın İKİNCİL satırı da gizlenir',
        () {
      Future<void> hide(WidgetTester tester) async {
        await tester
            .element(find.byType(AppBarContent))
            .read<AmountVisibilityCubit>()
            .setVisibility(false);
        await tester.pumpAndSettle();
      }

      testWidgets('kart bağlamı: kullanılabilir limit', (tester) async {
        // Göz başlığı gizlerken hemen altındaki limit açıkta kalıyordu
        // (cihazda görüldü).
        final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
        final card = _card();
        when(() => bloc.state)
            .thenReturn(WalletLoadedSt([_bank(), card], card));
        await tester.pumpWidget(app(header()));
        await tester.pumpAndSettle();
        expect(find.textContaining('36.300'), findsOneWidget);

        await hide(tester);
        expect(find.textContaining('36.300'), findsNothing);
        expect(find.text(l10n.kkKullanilabilirLimitSatiri('**** ₺')),
            findsOneWidget);
      });

      testWidgets('hesap bağlamı: kart ödemeleri düşülünce', (tester) async {
        final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
        final bank = _bank();
        when(() => bloc.state)
            .thenReturn(WalletLoadedSt([bank, _card()], bank));
        await tester.pumpWidget(app(header()));
        await tester.pumpAndSettle();
        expect(find.textContaining('9.000'), findsOneWidget);

        await hide(tester);
        expect(find.textContaining('9.000'), findsNothing);
        expect(find.text(l10n.kkKartlarDusulunce('**** ₺')), findsOneWidget);
      });
    });

    testWidgets('kartın borcu yoksa satır çıkmaz', (tester) async {
      final bank = _bank();
      final paid = _card(balance: 0);
      final info = paid.creditCard!;
      final noStatement =
          paid.copyWith(creditCard: info.copyWith(clearLastStatement: true));
      when(() => bloc.state)
          .thenReturn(WalletLoadedSt([bank, noStatement], bank));
      await tester.pumpWidget(app(header()));
      await tester.pumpAndSettle();
      expect(find.textContaining('düşülünce'), findsNothing);
    });
  });

  group('yaklaşan ödeme bandı (hesap bağlamı)', () {
    testWidgets('son ödemeye 2 gün: bant + "Öde" kart ödeme sayfasını açar',
        (tester) async {
      final bank = _bank();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, _card()], bank));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ctx-due-card')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ctx-due-pay-card')));
      await tester.pumpAndSettle();
      expect(find.byType(CardPaySheet), findsOneWidget);
    });

    testWidgets('pillsOnly (İçgörü/Rapor): hap satırı var, bant ve şerit YOK',
        (tester) async {
      final bank = _bank();
      final card = _card();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], bank));
      await tester.pumpWidget(app(const CardContextRail(pillsOnly: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('ctx-${card.id}')), findsOneWidget);
      expect(find.byKey(const ValueKey('ctx-due-card')), findsNothing);

      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], card));
      await tester.pumpWidget(app(const CardContextRail(pillsOnly: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ctx-card-pay')), findsNothing);
    });

    testWidgets('son ödeme uzaksa bant YOK', (tester) async {
      final bank = _bank();
      when(() => bloc.state)
          .thenReturn(WalletLoadedSt([bank, _card(dueInDays: 12)], bank));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ctx-due-card')), findsNothing);
    });

    testWidgets(
        'REGRESYON: tutarlar gizliyken bant ve şerit tutarı da gizlenir',
        (tester) async {
      final bank = _bank();
      final card = _card();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], bank));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();
      expect(find.textContaining('1.000,00'), findsWidgets);

      await tester
          .element(find.byType(CardContextRail))
          .read<AmountVisibilityCubit>()
          .setVisibility(false);
      await tester.pumpAndSettle();
      // `formatMoney` doğrudan çağrıldığı için göz düğmesi bu tutarı
      // gizlemiyordu.
      expect(find.textContaining('1.000,00'), findsNothing);
      expect(find.textContaining('****'), findsWidgets);

      // Kart bağlamındaki şerit de aynı kurala uyar.
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], card));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();
      await tester
          .element(find.byType(CardContextRail))
          .read<AmountVisibilityCubit>()
          .setVisibility(false);
      await tester.pumpAndSettle();
      expect(find.textContaining('1.000,00'), findsNothing);
    });

    group('asgarisi ödenmiş, son ödemesi geçmiş ekstre', () {
      // Son ödeme 2 gün önce; dönem borcu 1.000, asgari 300.
      WalletEntity pastDue() {
        final card = _card(dueInDays: -2);
        final info = card.creditCard!;
        final st = info.lastStatement!;
        return card.copyWith(
          creditCard: info.copyWith(
            lastStatement: CardStatement(
              closingDate: st.closingDate,
              dueDate: st.dueDate,
              statementBalance: st.statementBalance,
              minimumPayment: 300,
              recordedAt: st.recordedAt,
            ),
          ),
        );
      }

      void stubPayment(WalletEntity card, double amount) {
        final closing = card.creditCard!.lastStatement!.closingDate;
        when(() => getIt<TransactionsRepository>().getTransactions(
              userId: any(named: 'userId'),
              walletId: any(named: 'walletId'),
            )).thenAnswer((_) async => Right(<TransactionEntity>[
              TransactionEntity(
                id: 'pay',
                userId: 'u',
                walletId: 'card',
                title: 'Ödeme',
                tag: CashMovementTags.transfer,
                amount: amount,
                date: closing.add(const Duration(days: 1)),
                type: TransactionTypeModel.income,
                isSystem: true,
              ),
            ]));
      }

      testWidgets(
          'asgari ödendi: hesap ekranında ödeme bandı YOK; kart şeridinde '
          '"gecikti" değil "Asgari ödendi"', (tester) async {
        final bank = _bank();
        final card = pastDue();
        stubPayment(card, 300);

        when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], bank));
        await tester.pumpWidget(app(const CardContextRail()));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ctx-due-card')), findsNothing);

        when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], card));
        await tester.pumpWidget(app(const CardContextRail()));
        await tester.pumpAndSettle();
        expect(find.text('Asgari ödendi'), findsOneWidget);
        expect(find.textContaining('gecikti'), findsNothing);
        // Kalan tutar yine yazılır: kapatmak faizi önler.
        expect(find.textContaining('700,00'), findsOneWidget);
      });

      testWidgets('asgarinin altında ödeme: bant ve "gecikti" çipi SÜRER',
          (tester) async {
        final bank = _bank();
        final card = pastDue();
        stubPayment(card, 100);

        when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], bank));
        await tester.pumpWidget(app(const CardContextRail()));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ctx-due-card')), findsOneWidget);
        expect(find.text('2 gün gecikti'), findsOneWidget);
      });
    });

    testWidgets(
        'ödenmiş dönemde çip sonraki kesimi AY ADIYLA yazar ("15 Eki"), '
        'sayısal tarihle değil', (tester) async {
      final bank = _bank();
      final card = _card();
      final closing = card.creditCard!.lastStatement!.closingDate;
      when(() => getIt<TransactionsRepository>().getTransactions(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
          )).thenAnswer((_) async => Right(<TransactionEntity>[
            TransactionEntity(
              id: 'pay',
              userId: 'u',
              walletId: 'card',
              title: 'Ödeme',
              tag: CashMovementTags.transfer,
              amount: 1000,
              date: closing.add(const Duration(days: 1)),
              type: TransactionTypeModel.income,
              isSystem: true,
            ),
          ]));
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], card));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();

      final next = CardCycle(card.creditCard!).nextClosing(DateTime.now());
      expect(
        find.text('Sonraki kesim: '
            '${DateFormat.MMMd('tr_TR').format(next).replaceAll(' ', '\u00A0')}'),
        findsOneWidget,
      );
      expect(find.textContaining(RegExp(r'\d{2}\.\d{2}\.\d{2}')), findsNothing);
    });

    testWidgets('kart bağlamında bant yerine kartın şeridi', (tester) async {
      final card = _card();
      when(() => bloc.state).thenReturn(WalletLoadedSt([_bank(), card], card));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ctx-due-card')), findsNothing);
      expect(find.byKey(const ValueKey('ctx-card-pay')), findsOneWidget);
    });
  });

  group('üst çubukta kart düğmesi', () {
    final switcher = find.byKey(const ValueKey('card-switcher'));
    final activeBadge = find.byKey(const ValueKey('card-switcher-active'));

    WalletEntity second() => _card().copyWith(id: 'card2', name: 'Axess');

    List<SetActiveWalletEvent> selections() =>
        verify(() => bloc.add(captureAny()))
            .captured
            .whereType<SetActiveWalletEvent>()
            .toList();

    setUp(() => registerFallbackValue(
        const SetActiveWalletEvent(userId: 'u', walletId: 'x')));

    testWidgets('kartı olmayan hesapta düğme YOK; başlık ortada kalır',
        (tester) async {
      final bank = _bank();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank], bank));
      await tester.pumpWidget(app(header()));
      await tester.pumpAndSettle();

      expect(switcher, findsNothing);
      // Göz artık sağ köşede değil, tutarın yanında.
      expect(find.byKey(const ValueKey('amount-eye')), findsOneWidget);
      final content = tester.getRect(find.byType(AppBarContent));
      final carousel =
          tester.getRect(find.byKey(const ValueKey('wallet-carousel')));
      expect(carousel.center.dx, closeTo(content.center.dx, 0.5),
          reason: 'sağ yuva boşken başlık kaymamalı');
    });

    testWidgets('TEK kart: dokunmak hesaptan karta geçirir (sessiz)',
        (tester) async {
      final bank = _bank();
      final card = _card();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], bank));
      await tester.pumpWidget(app(header()));
      await tester.pumpAndSettle();

      expect(switcher, findsOneWidget);
      expect(activeBadge, findsNothing);
      expect(find.byTooltip('Karta geç: Bonus'), findsOneWidget);

      await tester.tap(switcher);
      await tester.pumpAndSettle();

      final event = selections().single;
      expect(event.walletId, 'card');
      expect(event.announce, isFalse);
      // Tek kartta seçim sayfası açılmaz.
      expect(find.byType(CardSwitchSheet), findsNothing);
    });

    testWidgets(
        'kart seçiliyken düğme DOLU + onay rozetli; dokunmak hesaba '
        'döndürür', (tester) async {
      final bank = _bank();
      final card = _card();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], card));
      await tester.pumpWidget(app(header()));
      await tester.pumpAndSettle();

      expect(activeBadge, findsOneWidget);
      expect(find.byTooltip('Hesaba dön: Banka'), findsOneWidget);

      await tester.tap(switcher);
      await tester.pumpAndSettle();
      expect(selections().single.walletId, 'bank');
    });

    testWidgets(
        'BİRDEN ÇOK kart: dokunmak seçim sayfasını açar; karta '
        'dokunmak seçer ve kapatır', (tester) async {
      tester.view.physicalSize = const Size(411, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final bank = _bank();
      final card = _card();
      final other = second();
      when(() => bloc.state)
          .thenReturn(WalletLoadedSt([bank, card, other], bank));
      await tester.pumpWidget(app(header()));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Kart seç (2)'), findsOneWidget);

      await tester.tap(switcher);
      await tester.pumpAndSettle();

      expect(find.byType(CardSwitchSheet), findsOneWidget);
      // Hesap + iki kart; etkin olan (hesap) işaretli.
      expect(find.byKey(const ValueKey('card-switch-bank')), findsOneWidget);
      expect(find.byKey(const ValueKey('card-switch-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('card-switch-card2')), findsOneWidget);
      verifyNever(() => bloc.add(any(that: isA<SetActiveWalletEvent>())));

      await tester.tap(find.byKey(const ValueKey('card-switch-card2')));
      await tester.pumpAndSettle();

      expect(find.byType(CardSwitchSheet), findsNothing);
      expect(selections().single.walletId, 'card2');
    });

    testWidgets('tek kartta uzun basmak da seçim sayfasını açar',
        (tester) async {
      tester.view.physicalSize = const Size(411, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final bank = _bank();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, _card()], bank));
      await tester.pumpWidget(app(header()));
      await tester.pumpAndSettle();

      await tester.longPress(switcher);
      await tester.pumpAndSettle();

      expect(find.byType(CardSwitchSheet), findsOneWidget);
      // Etkin bağlama dokunmak seçim yazmaz, yalnız kapatır.
      await tester.tap(find.byKey(const ValueKey('card-switch-bank')));
      await tester.pumpAndSettle();
      expect(find.byType(CardSwitchSheet), findsNothing);
      verifyNever(() => bloc.add(any(that: isA<SetActiveWalletEvent>())));
    });

    testWidgets('Birikim / Borç durumunda düğme YOK (orada hesabın verisi var)',
        (tester) async {
      final bank = _bank();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, _card()], bank));
      for (final st in [SliderState.savedMoney, SliderState.debt]) {
        await tester.pumpWidget(app(SizedBox(
          height: 70,
          child: AppBarContent(
            currentState: st,
            scaleAnimation: const AlwaysStoppedAnimation(1),
            fadeAnimation: const AlwaysStoppedAnimation(1),
          ),
        )));
        await tester.pumpAndSettle();
        expect(switcher, findsNothing, reason: '$st');
      }
    });

    testWidgets('360dp: düğme + başlık + menü taşmadan sığar', (tester) async {
      tester.view.physicalSize = const Size(360, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final card = _card();
      when(() => bloc.state)
          .thenReturn(WalletLoadedSt([_bank(), card, second()], card));
      await tester.pumpWidget(app(header()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(switcher), const Size(48, 48));
    });
  });

  group('üst çubuk zemini kart rengine bürünür', () {
    const card = [Color(0xFF102030), Color(0xFF000810)];

    LinearGradient gradientOf(double value,
            {List<Color>? cardColors, double factor = 0}) =>
        AppBarStyleHelper.getAppbarDecoration(value,
                cardColors: cardColors, cardFactor: factor)
            .gradient! as LinearGradient;

    test('İşlemler durumunda (0,5) ve tam geçişte zemin kartın renkleri', () {
      final g = gradientOf(0.5, cardColors: card, factor: 1);
      expect(g.colors.first, card.first);
      expect(g.colors.last, card.last);
    });

    test('Birikim (0) ve Borç (1) durumunda kart rengi YOK', () {
      for (final value in [0.0, 1.0]) {
        expect(gradientOf(value, cardColors: card, factor: 1).colors,
            gradientOf(value).colors);
      }
    });

    test('kart yokken ya da geçiş 0 iken zemin değişmez', () {
      expect(gradientOf(0.5, cardColors: card).colors, gradientOf(0.5).colors);
      expect(gradientOf(0.5, factor: 1).colors, gradientOf(0.5).colors);
    });

    test('yakınlık: 0,5\'te 1, uçlarda 0, arada doğrusal', () {
      expect(AppBarStyleHelper.transactionsProximity(0.5), 1);
      expect(AppBarStyleHelper.transactionsProximity(0), 0);
      expect(AppBarStyleHelper.transactionsProximity(1), 0);
      expect(AppBarStyleHelper.transactionsProximity(0.25), closeTo(0.5, 1e-9));
    });
  });

  group('kart şeridi: hap satırı', () {
    testWidgets(
        'İşlemler kipi (showPills: false): hap YOK, borç/öde şeridi VAR',
        (tester) async {
      final bank = _bank();
      final card = _card();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], card));
      await tester.pumpWidget(app(const CardContextRail(showPills: false)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ctx-bank')), findsNothing);
      expect(find.byKey(const ValueKey('ctx-card')), findsNothing);
      expect(find.byKey(const ValueKey('ctx-card-pay')), findsOneWidget);
    });

    testWidgets('İşlemler kipi, hesap bağlamı: yaklaşan ödeme bandı kalır',
        (tester) async {
      final bank = _bank();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, _card()], bank));
      await tester.pumpWidget(app(const CardContextRail(showPills: false)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ctx-bank')), findsNothing);
      expect(find.byKey(const ValueKey('ctx-due-card')), findsOneWidget);
    });

    testWidgets('gösterilecek bir şey yokken hapsız şerit HİÇ yer kaplamaz',
        (tester) async {
      final bank = _bank();
      final paid = _card(balance: 0);
      final quiet = paid.copyWith(
          creditCard: paid.creditCard!.copyWith(clearLastStatement: true));
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, quiet], bank));
      await tester.pumpWidget(app(const Column(
        mainAxisSize: MainAxisSize.min,
        children: [CardContextRail(showPills: false)],
      )));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(CardContextRail)).height, 0);
    });

    testWidgets('haplı kipte (İçgörü/Rapor) seçili hap ONAY işaretlidir',
        (tester) async {
      final bank = _bank();
      final card = _card();
      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], bank));
      await tester.pumpWidget(app(const CardContextRail(pillsOnly: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ctx-selected-bank')), findsOneWidget);
      expect(find.byKey(const ValueKey('ctx-selected-card')), findsNothing);

      when(() => bloc.state).thenReturn(WalletLoadedSt([bank, card], card));
      await tester.pumpWidget(app(const CardContextRail(pillsOnly: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ctx-selected-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('ctx-selected-bank')), findsNothing);
    });
  });

  testWidgets(
      'REGRESYON: mini kartın gölgesi Material\'in DIŞINDA çizilir (içeride '
      'kalınca köşelerin dışı gri dikdörtgen oluyordu)', (tester) async {
    await tester.pumpWidget(app(MiniCreditCard(card: _card(), onTap: () {})));
    await tester.pumpAndSettle();

    final ink = tester.widget<Ink>(find.byType(Ink));
    expect((ink.decoration! as BoxDecoration).boxShadow, isNull,
        reason: 'Ink süslemesi Material dikdörtgenine kırpılır');
    final outer = tester.widget<DecoratedBox>(find
        .ancestor(of: find.byType(Ink), matching: find.byType(DecoratedBox))
        .first);
    final decoration = outer.decoration as BoxDecoration;
    expect(decoration.boxShadow, isNotEmpty);
    expect(decoration.borderRadius, BorderRadius.circular(14));
  });
}
