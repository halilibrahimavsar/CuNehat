import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'package:cunehat/features/credit_card/presentation/card_pay_sheet.dart';
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

      expect(find.textContaining('BONUS • BORÇ'), findsOneWidget);
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

    testWidgets('son ödeme uzaksa bant YOK', (tester) async {
      final bank = _bank();
      when(() => bloc.state)
          .thenReturn(WalletLoadedSt([bank, _card(dueInDays: 12)], bank));
      await tester.pumpWidget(app(const CardContextRail()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ctx-due-card')), findsNothing);
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
}
