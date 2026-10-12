import '../../support/wallet_category_stub.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/core/services/transfer_service.dart';
import 'package:cunehat/core/services/recent_categories_service.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'dart:async';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/coupling/presentation/link_transaction_flow.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_action_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletRepo extends Mock implements WalletRepository {}

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockInvestmentRepo extends Mock implements InvestmentRepository {}

class _MockInvestmentBloc extends MockBloc<InvestmentEvent, InvestmentState>
    implements InvestmentBloc {}

TransactionEntity _tx(
  String id, {
  String walletId = 'w',
  double amount = 5000,
  bool income = false,
  DateTime? date,
  bool isSystem = false,
  String tag = 'cat-diger',
  String? linkedRecordId,
  String? adoptedFromTag,
}) =>
    TransactionEntity(
      id: id,
      userId: 'u',
      walletId: walletId,
      title: 'SATIR $id',
      tag: tag,
      amount: amount,
      date: date ?? DateTime(2026, 9, 10, 12),
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      isSystem: isSystem,
      linkedRecordId: linkedRecordId,
      adoptedFromTag: adoptedFromTag,
    );

void main() {
  setUp(() => Intl.defaultLocale = 'tr_TR');

  group('hedefler', () {
    test('gider: alım/ödeme hedefleri; gelir: borç girişi ve transfer', () {
      expect(linkTargetsFor(_tx('g')), [
        LinkTarget.newInvestment,
        LinkTarget.investmentContribution,
        LinkTarget.cashPot,
        LinkTarget.debtPayment,
        LinkTarget.transfer,
      ]);
      expect(linkTargetsFor(_tx('i', income: true)), [
        LinkTarget.debtPrincipal,
        LinkTarget.transfer,
      ]);
    });

    test('sistem satırı ve kaydedilmemiş satır bağlanamaz', () {
      expect(canLinkTransaction(_tx('a')), isTrue);
      expect(canLinkTransaction(_tx('a', isSystem: true)), isFalse);
      expect(
        canLinkTransaction(TransactionEntity(
          id: null,
          userId: 'u',
          walletId: 'w',
          title: 't',
          tag: 't',
          amount: 1,
          date: DateTime(2026),
          type: TransactionTypeModel.expense,
        )),
        isFalse,
      );
    });
  });

  group('transferCounterpartCandidates', () {
    final leg = _tx('leg', amount: 5000, date: DateTime(2026, 9, 10, 14));

    test(
        'aynı birim: ters yön + kuruşu kuruşuna aynı tutar + ±3 gün; '
        'sistem satırı ve aynı yön elenir', () {
      final pool = [
        _tx('far', walletId: 'k', income: true, date: DateTime(2026, 9, 14)),
        _tx('next', walletId: 'k', income: true, date: DateTime(2026, 9, 11)),
        _tx('same', walletId: 'k', income: true, date: DateTime(2026, 9, 10)),
        _tx('diffAmount',
            walletId: 'k',
            income: true,
            amount: 4999.99,
            date: DateTime(2026, 9, 10)),
        _tx('sameDir', walletId: 'k', date: DateTime(2026, 9, 10)),
        _tx('sys',
            walletId: 'k',
            income: true,
            isSystem: true,
            date: DateTime(2026, 9, 10)),
      ];

      final ids = [
        for (final t in transferCounterpartCandidates(
          pool,
          leg: leg,
          sameCurrency: true,
        ))
          t.id,
      ];

      // En yakın gün önce; 4 gün uzak, tutarı farklı, yönü aynı ya da
      // sistem satırı olan aday DEĞİL.
      expect(ids, ['same', 'next']);
    });

    test('farklı birimde tutar karşılaştırılmaz (o günün kuru bilinmiyor)', () {
      final pool = [
        _tx('usd', walletId: 'k', income: true, amount: 120.5),
      ];
      expect(
        transferCounterpartCandidates(pool, leg: leg, sameCurrency: false),
        hasLength(1),
      );
      expect(
        transferCounterpartCandidates(pool, leg: leg, sameCurrency: true),
        isEmpty,
      );
    });

    test('gelir bacağının karşılığı GİDER satırıdır', () {
      final incomeLeg = _tx('in', income: true, amount: 300);
      final pool = [
        _tx('out', walletId: 'b', amount: 300),
        _tx('in2', walletId: 'b', amount: 300, income: true),
      ];
      expect(
        [
          for (final t in transferCounterpartCandidates(pool,
              leg: incomeLeg, sameCurrency: true))
            t.id
        ],
        ['out'],
      );
    });
  });

  group('OutcomeWatch', () {
    test('koşulu sağlayan İLK durumu verir, öncekileri atlar', () async {
      final controller = StreamController<int>.broadcast();
      final watch = OutcomeWatch<int>(controller.stream, (s) => s.isEven);
      controller
        ..add(1)
        ..add(4)
        ..add(6);
      expect(await watch.result, 4);
      await controller.close();
    });

    test('vazgeçilince null — sonradan gelen sonuç yakalanmaz', () async {
      final controller = StreamController<int>.broadcast();
      final watch = OutcomeWatch<int>(controller.stream, (s) => s.isEven);
      watch.cancel();
      controller.add(2);
      expect(await watch.result, isNull);
      expect(controller.hasListener, isFalse, reason: 'dinleme bırakıldı');
      await controller.close();
    });

    test('süre dolarsa null', () async {
      final controller = StreamController<int>.broadcast();
      final watch = OutcomeWatch<int>(
        controller.stream,
        (s) => s.isEven,
        timeout: const Duration(milliseconds: 5),
      );
      expect(await watch.result, isNull);
      expect(controller.hasListener, isFalse);
      await controller.close();
    });
  });

  Widget app(Widget home) => MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      );

  group('LinkTargetSheet', () {
    Future<LinkChoice?> open(
      WidgetTester tester,
      TransactionEntity t, {
      required Future<void> Function() interact,
    }) async {
      LinkChoice? result;
      await tester.pumpWidget(app(Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await showModalBottomSheet<LinkChoice>(
              context: context,
              isScrollControlled: true,
              builder: (_) => LinkTargetSheet(transaction: t, currency: 'TRY'),
            );
          },
          child: const Text('Aç'),
        ),
      )));
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await interact();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('gider: yeni birikim → tür sorulur, seçilen türle döner',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final choice = await open(tester, _tx('g'), interact: () async {
        expect(find.text(l10n.baglaYeniBirikim), findsOneWidget);
        expect(find.text(l10n.baglaBirikimeKatki), findsOneWidget);
        expect(find.text(l10n.baglaBorcOdemesi), findsOneWidget);
        expect(find.text(l10n.baglaTransferCikis), findsOneWidget);
        expect(find.text(l10n.baglaBorcAnaparasi), findsNothing);

        await tester.tap(find.text(l10n.baglaYeniBirikim));
        await tester.pumpAndSettle();
        expect(find.text(l10n.baglaBirikimTuruSec), findsOneWidget);
        await tester.tap(find.text(l10n.altinYatirimi));
      });

      expect(choice?.target, LinkTarget.newInvestment);
      expect(choice?.investmentType, InvestmentType.gold);
    });

    testWidgets('gelir: yalnız borç girişi ve transfer', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final choice =
          await open(tester, _tx('i', income: true), interact: () async {
        expect(find.text(l10n.baglaYeniBirikim), findsNothing);
        expect(find.text(l10n.baglaBorcOdemesi), findsNothing);
        expect(find.text(l10n.baglaTransferGiris), findsOneWidget);
        await tester.tap(find.text(l10n.baglaBorcAnaparasi));
      });

      expect(choice?.target, LinkTarget.debtPrincipal);
    });

    testWidgets('360dp genişlikte taşma yok', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await open(tester, _tx('g'), interact: () async {});
      expect(tester.takeException(), isNull);
    });
  });

  group('TransactionActionSheet', () {
    Future<TransactionAction?> open(
      WidgetTester tester,
      TransactionEntity t, {
      Future<void> Function()? interact,
    }) async {
      TransactionAction? result;
      await tester.pumpWidget(app(Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await TransactionActionSheet.show(
              context,
              transaction: t,
              accent: Colors.red,
            );
          },
          child: const Text('Aç'),
        ),
      )));
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      if (interact != null) await interact();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('düz satırda "Bağla…" eylemi var', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final action = await open(tester, _tx('a'), interact: () async {
        await tester.tap(find.text(l10n.baglaEylemi));
      });
      expect(action, TransactionAction.link);
    });

    testWidgets(
        'çift kimlikli transfer bacağında "Transferi kaldır"; eski transferde '
        'YOK', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final action = await open(
        tester,
        _tx('leg',
            isSystem: true,
            tag: CashMovementTags.transfer,
            linkedRecordId: 'p1'),
        interact: () async {
          expect(find.text(l10n.bagliTransferNotu), findsOneWidget);
          expect(find.text(l10n.baglaEylemi), findsNothing);
          await tester.tap(find.text(l10n.transferiKaldir));
        },
      );
      expect(action, TransactionAction.removeTransfer);

      await open(
        tester,
        _tx('old', isSystem: true, tag: CashMovementTags.transfer),
        interact: () async {
          expect(find.text(l10n.transferiKaldir), findsNothing);
        },
      );
    });

    testWidgets('bağlanmış satırın notu "otomatik oluşturuldu" DEMEZ',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await open(
        tester,
        _tx('adopted',
            isSystem: true,
            tag: CashMovementTags.investmentBuy,
            linkedRecordId: 'inv-1',
            adoptedFromTag: 'cat-yatirim'),
        interact: () async {
          expect(find.text(l10n.bagliSatirKisaNotu), findsOneWidget);
          expect(find.text(l10n.buIslemOtomatikOlusturuldu), findsNothing);
        },
      );
    });
  });

  group('startLinkTransactionFlow — ön seçim', () {
    WalletEntity wallet(String id, {CreditCardInfo? card}) => WalletEntity(
          id: id,
          userId: 'u',
          name: id == 'card' ? 'Bonus' : 'Banka',
          balance: 0,
          debt: 0,
          credit: 0,
          investment: 0,
          colorHex: '0xFF2196F3',
          iconName: 'wallet',
          createdAt: DateTime(2026, 1, 1),
          openingBalance: 0,
          creditCard: card,
        );

    tearDown(() async => getIt.reset());

    testWidgets(
        'kart ödemesi önerisi: hedef ve kart sorulmaz, doğrudan karşı satır '
        'sorusu açılır', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final walletRepo = _MockWalletRepo();
      final txRepo = _MockTxRepo();
      getIt
        ..registerSingleton<WalletRepository>(walletRepo)
        ..registerSingleton<TransactionsRepository>(txRepo);
      when(() => walletRepo.getWallets('u')).thenAnswer((_) async => Right([
            wallet('w'),
            wallet('card',
                card: const CreditCardInfo(
                    closingDay: 15, dueDay: 25, last4: '5690')),
          ]));
      when(() => txRepo.getTransactions(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
          )).thenAnswer((_) async => const Right(<TransactionEntity>[]));

      await tester.pumpWidget(app(Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => startLinkTransactionFlow(
            context,
            transaction: _tx('pay', walletId: 'w', amount: 5000),
            currency: 'TRY',
            target: LinkTarget.transfer,
            counterpartWalletId: 'card',
          ),
          child: const Text('Aç'),
        ),
      )));
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.baglaBaslik), findsNothing);
      expect(find.text(l10n.baglaCuzdanSec), findsNothing);
      expect(find.text(l10n.baglaKarsiSatirBaslik), findsOneWidget);
      verify(() => txRepo.getTransactions(userId: 'u', walletId: 'card'))
          .called(1);
    });
  });

  group('kasaya bağlama', () {
    final pot = InvestmentEntity(
      id: 'pot',
      userId: 'u',
      walletId: 'w',
      name: 'Acil durum',
      amount: 1000,
      currentValue: 1000,
      type: InvestmentType.cash,
      color: Colors.teal,
      dateAdded: DateTime(2026, 9, 1),
    );

    setUpAll(() =>
        registerFallbackValue(GetInvestmentsEvent(userId: 'u', walletId: 'w')));
    tearDown(() async => getIt.reset());

    Future<_MockInvestmentBloc> start(
        WidgetTester tester, List<InvestmentEntity> investments) async {
      final repo = _MockInvestmentRepo();
      getIt.registerSingleton<InvestmentRepository>(repo);
      when(() => repo.getInvestments(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
          )).thenAnswer((_) async => Right(investments));
      final bloc = _MockInvestmentBloc();
      when(() => bloc.state).thenReturn(InvestmentInitial());
      await tester.pumpWidget(app(BlocProvider<InvestmentBloc>.value(
        value: bloc,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => startLinkTransactionFlow(
              context,
              transaction: _tx('g', amount: 250),
              currency: 'TRY',
              target: LinkTarget.cashPot,
            ),
            child: const Text('Aç'),
          ),
        ),
      )));
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      return bloc;
    }

    testWidgets('var olan kasaya: satır benimsenir, bakiye satır kadar artar',
        (tester) async {
      final bloc = await start(tester, [pot]);
      await tester.tap(find.text('Acil durum'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(any(
            that: isA<UpdateInvestmentEvent>()
                .having((e) => e.investment.currentValue, 'bakiye', 1250.0)
                .having((e) => e.newAmount - e.prevAmount, 'fark', 250.0)
                .having(
                    (e) => e.cashSource, 'kaynak', isA<AdoptedCashMovement>()),
          ))).called(1); // Sonuç bekçisinin zaman aşımı sayacı kapanmalı.
      await tester.pump(const Duration(minutes: 2));
    });

    testWidgets('kasa yoksa satırın tutarıyla yeni kasa açılır',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final bloc = await start(tester, const []);
      expect(find.text(l10n.yeniKasa), findsOneWidget);
      expect(find.byKey(const ValueKey('cash-pot-initial')), findsNothing,
          reason: 'tutar satırdan gelir, sorulmaz');
      await tester.enterText(
          find.byKey(const ValueKey('cash-pot-name')), 'Tatil');
      await tester.tap(find.byKey(const ValueKey('cash-pot-save')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(any(
            that: isA<CreateInvestmentEvent>()
                .having((e) => e.investment.type, 'tür', InvestmentType.cash)
                .having((e) => e.investment.amount, 'tutar', 250.0)
                .having((e) => e.investment.name, 'ad', 'Tatil')
                .having(
                    (e) => e.cashSource, 'kaynak', isA<AdoptedCashMovement>()),
          ))).called(1); // Sonuç bekçisinin zaman aşımı sayacı kapanmalı.
      await tester.pump(const Duration(minutes: 2));
    });
  });

  // Dünkü plan B5: bağı kaldırılan satır kategorisiz kalmasın.
  group('transfer bağını kaldır → kategorisiz kalan satıra kategori sorulur',
      () {
    late _MockTransferService transfers;
    late _MockMetrics metrics;
    late _MockTransactionBloc bloc;
    late _MockCategoryRepo categories;

    // Ekstreden gelip "karta ödeme" diye bağlanmış satır: benimsenmiş,
    // özgün kategorisi YOK (incelemede hiç kategori seçilmedi).
    final adoptedNoCategory = _tx(
      'leg-bank',
      isSystem: true,
      tag: CashMovementTags.transfer,
      linkedRecordId: 'pair-1',
      adoptedFromTag: '',
    );
    final writtenLeg = _tx(
      'leg-card',
      walletId: 'card',
      income: true,
      isSystem: true,
      tag: CashMovementTags.transfer,
      linkedRecordId: 'pair-1',
    );

    setUpAll(() {
      registerFallbackValue(const ChangeTransactionsCategoryEvent(
          transactions: [], categoryId: 'x'));
    });

    setUp(() async {
      getIt.allowReassignment = true;
      transfers = _MockTransferService();
      metrics = _MockMetrics();
      bloc = _MockTransactionBloc();
      // Akış, kapanmış bir bloc'a olay göndermemek için bunu sorar.
      when(() => bloc.isClosed).thenReturn(false);
      categories = _MockCategoryRepo();
      when(() => transfers.unlinkTransfer(any())).thenAnswer((_) async => true);
      when(() => categories.getCategories(any()))
          .thenAnswer((_) async => const [
                CategoryEntity(
                    id: 'cat-market',
                    name: 'Market',
                    iconName: 'category',
                    isExpense: true),
              ]);
      getIt.registerSingleton<TransferService>(transfers);
      getIt.registerSingleton<WalletMetricsService>(metrics);
      getIt.registerSingleton<CategoryRepository>(categories);
      registerUncuratedWalletCategories(categories);
      SharedPreferences.setMockInitialValues({});
      getIt.registerSingleton<RecentCategoriesService>(
          RecentCategoriesService(await SharedPreferences.getInstance()));
    });

    tearDown(() async => getIt.reset());

    void legs(List<TransactionEntity> rows) =>
        when(() => metrics.linkedMovements(recordIds: {'pair-1'}))
            .thenAnswer((_) async => rows);

    Future<void> removeLink(WidgetTester tester, TransactionEntity leg) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlocProvider<TransactionBloc>.value(
        value: bloc,
        child: MaterialApp(
          scaffoldMessengerKey: appMessengerKey,
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => confirmAndRemoveTransfer(context, leg),
                child: const Text('kaldır'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('kaldır'));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.tap(find.widgetWithText(FilledButton, l10n.transferiKaldir));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'kategorisi olmayan benimsenmiş bacak: seçici açılır, seçim '
        'serbest bırakılmış satıra yazılır', (tester) async {
      legs([adoptedNoCategory, writtenLeg]);
      await removeLink(tester, adoptedNoCategory);

      verify(() => transfers.unlinkTransfer('pair-1')).called(1);
      expect(find.byType(CategoryPickerSheet), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('category-pick-cat-market')));
      await tester.pumpAndSettle();

      final event = verify(() => bloc.add(captureAny()))
          .captured
          .whereType<ChangeTransactionsCategoryEvent>()
          .single;
      expect(event.categoryId, 'cat-market');
      final row = event.transactions.single;
      expect(row.id, 'leg-bank');
      // Serbest bırakılmış hâli: artık sistem satırı değil, bağı ve
      // benimseme izi yok — toplu kategori yolu onu ATLAMAZ.
      expect(row.isSystem, isFalse);
      expect(row.isAdopted, isFalse);
      expect(row.linkedRecordId, isNull);
      expect(row.tag, isEmpty);
    });

    testWidgets('seçiciden vazgeçilirse satırın kategorisiz kaldığı söylenir',
        (tester) async {
      legs([adoptedNoCategory, writtenLeg]);
      await removeLink(tester, adoptedNoCategory);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryPickerSheet), findsNothing);
      expect(find.text(l10n.transferKaldirildiKategorisiz), findsOneWidget);
      verifyNever(
          () => bloc.add(any(that: isA<ChangeTransactionsCategoryEvent>())));
    });

    testWidgets(
        'özgün kategorisi OLAN bacakta seçici açılmaz (kategori geri '
        'gelir)', (tester) async {
      legs([
        _tx('leg-bank',
            isSystem: true,
            tag: CashMovementTags.transfer,
            linkedRecordId: 'pair-1',
            adoptedFromTag: 'cat-market'),
        writtenLeg,
      ]);
      await removeLink(tester, adoptedNoCategory);

      verify(() => transfers.unlinkTransfer('pair-1')).called(1);
      expect(find.byType(CategoryPickerSheet), findsNothing);
    });

    testWidgets('kaldırma başarısızsa kategori sorulmaz', (tester) async {
      legs([adoptedNoCategory, writtenLeg]);
      when(() => transfers.unlinkTransfer(any()))
          .thenAnswer((_) async => false);
      await removeLink(tester, adoptedNoCategory);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

      expect(find.byType(CategoryPickerSheet), findsNothing);
      expect(find.text(l10n.transferKaldirilamadi), findsOneWidget);
    });
  });
}

class _MockTransferService extends Mock implements TransferService {}

class _MockMetrics extends Mock implements WalletMetricsService {}

class _MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}
