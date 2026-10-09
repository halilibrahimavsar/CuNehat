import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_and_receivable_page.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
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
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/amount_visibility.dart';

class _MockDebtBloc extends MockBloc<DebtEvent, DebtState>
    implements DebtBloc {}

class _MockReceivableBloc extends MockBloc<ReceivableEvent, ReceivableState>
    implements ReceivableBloc {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockOnboarding extends Mock implements OnboardingCoordinator {}

class _Visible extends Cubit<bool> implements AmountVisibilityCubit {
  _Visible() : super(true);
  @override
  Future<void> setVisibility(bool isVisible) async => emit(isVisible);
  @override
  Future<void> toggleVisibility() async => emit(!state);
}

WalletEntity _wallet(String id,
        {double balance = 0, CreditCardInfo? card, String name = 'Banka'}) =>
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
      createdAt: DateTime(2026, 1, 1),
      openingBalance: balance,
      creditCard: card,
    );

/// Borç iki yerde tutuluyor — borç modülü ve kartın defteri — ve Borç
/// sekmesi yalnız ilkini gösteriyordu: kart borcu olan kullanıcı "Henüz borç
/// kaydı yok" görüyordu.
void main() {
  late _MockDebtBloc debtBloc;
  late _MockReceivableBloc receivableBloc;
  late _MockWalletBloc walletBloc;

  final bank = _wallet('bank', balance: 8000);
  final bonus = _wallet('bonus',
      name: 'Bonus',
      balance: -1200,
      card: const CreditCardInfo(
          closingDay: 15, dueDay: 25, last4: '5690', paymentWalletId: 'bank'));

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.shell);
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    debtBloc = _MockDebtBloc();
    receivableBloc = _MockReceivableBloc();
    walletBloc = _MockWalletBloc();
    final onboarding = _MockOnboarding();
    when(() => onboarding.isSeen(any())).thenReturn(true);
    getIt.registerSingleton<OnboardingCoordinator>(onboarding);
    final repo = _MockTxRepo();
    when(() => repo.getTransactions(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async => const Right(<TransactionEntity>[]));
    getIt.registerSingleton<TransactionsRepository>(repo);
    when(() => receivableBloc.state).thenReturn(const ReceivableLoaded([]));
  });

  tearDown(getIt.reset);

  Widget host(Widget child) => MultiBlocProvider(
        providers: [
          BlocProvider<DebtBloc>.value(value: debtBloc),
          BlocProvider<ReceivableBloc>.value(value: receivableBloc),
          BlocProvider<WalletBloc>.value(value: walletBloc),
          BlocProvider<AmountVisibilityCubit>(create: (_) => _Visible()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: child,
        ),
      );

  Widget page() => host(const DebtAndReceivablePage(
        userId: 'u',
        walletId: 'bank',
        walletCurrency: 'TRY',
      ));

  testWidgets(
      'REGRESYON: kart borcu varken "Henüz borç kaydı yok" DEMEZ; kart '
      'özeti ve kompakt boş satır çizilir', (tester) async {
    when(() => debtBloc.state).thenReturn(const DebtLoaded([]));
    when(() => walletBloc.state)
        .thenReturn(WalletLoadedSt([bank, bonus], bank));
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(find.text('Henüz borç kaydı yok.'), findsNothing);
    expect(find.text('Kredi kartları'), findsOneWidget);
    expect(find.text('Bonus ••5690'), findsOneWidget);
    expect(find.text('1.200,00 ₺'), findsOneWidget);
    expect(find.text('Kayıtlı kredi ya da kişisel borç yok.'), findsOneWidget);
    expect(find.byKey(const ValueKey('debt-card-pay-bonus')), findsOneWidget);
  });

  testWidgets('kart yoksa eski boş durum aynen kalır', (tester) async {
    when(() => debtBloc.state).thenReturn(const DebtLoaded([]));
    when(() => walletBloc.state).thenReturn(WalletLoadedSt([bank], bank));
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(find.text('Henüz borç kaydı yok.'), findsOneWidget);
    expect(find.text('Kredi kartları'), findsNothing);
  });

  testWidgets('kartlar ve krediler birlikte: iki bölüm, kredi listede',
      (tester) async {
    final loan = DebtEntity(
      calcMode: DebtCalcMode.none,
      expectedTotalAmount: 12000,
      id: 'd1',
      userId: 'u',
      walletId: 'bank',
      title: 'İhtiyaç kredisi',
      counterparty: 'Ziraat',
      type: DebtType.bankLoan,
      principalAmount: 12000,
      interestRate: 0,
      termMonths: 12,
      startDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 12, 1),
    );
    when(() => debtBloc.state).thenReturn(DebtLoaded([loan]));
    when(() => walletBloc.state)
        .thenReturn(WalletLoadedSt([bank, bonus], bank));
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(find.text('Kredi kartları'), findsOneWidget);
    expect(find.text('Krediler ve kişisel borçlar'), findsOneWidget);
    expect(find.text('İhtiyaç kredisi'), findsOneWidget);
  });

  group('taksitli borç + kart: çift kayıt uyarısı', () {
    Future<WalletEntity?> pumpForm(WidgetTester tester,
        {required List<WalletEntity> wallets}) async {
      // Geniş yüzey: bu test düzeni değil davranışı ölçer; test fontu
      // (~1,5× geniş) 360dp'de form satırlarında yanlış taşma üretir.
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      when(() => debtBloc.state).thenReturn(DebtInitial());
      when(() => walletBloc.state)
          .thenReturn(WalletLoadedSt(wallets, wallets.first));
      WalletEntity? chosen;
      await tester.pumpWidget(host(Scaffold(
        body: AddEntrySheet(
          walletId: 'bank',
          userId: 'u',
          currency: 'TRY',
          onEnterAsCardExpense: (card) => chosen = card,
        ),
      )));
      await tester.pumpAndSettle();
      final chip = find.text('Taksitli');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      final notice = find.byKey(const ValueKey('debt-card-installment-notice'));
      if (notice.evaluate().isEmpty) return null;
      await tester.ensureVisible(notice);
      await tester.tap(find.text('Kart harcaması olarak gir'));
      await tester.pumpAndSettle();
      return chosen;
    }

    testWidgets('hesabın kartı varsa uyarı çıkar, eylem kartı verir',
        (tester) async {
      final chosen = await pumpForm(tester, wallets: [bank, bonus]);
      expect(chosen?.id, 'bonus');
    });

    testWidgets('kart yoksa uyarı YOK', (tester) async {
      final chosen = await pumpForm(tester, wallets: [bank]);
      expect(chosen, isNull);
      expect(find.byKey(const ValueKey('debt-card-installment-notice')),
          findsNothing);
    });
  });
}
