import 'dart:ui';

import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/goal_usecases.dart';
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Get extends Mock implements GetInvestmentsUseCase {}

class _Add extends Mock implements AddInvestmentUseCase {}

class _Update extends Mock implements UpdateInvestmentUseCase {}

class _Delete extends Mock implements DeleteInvestmentUseCase {}

class _Quote extends Mock implements GetLiveQuoteUseCase {}

class _Metrics extends Mock implements WalletMetricsService {}

class _GetGoals extends Mock implements GetGoalsUseCase {}

class _SaveGoal extends Mock implements SaveGoalUseCase {}

class _DeleteGoal extends Mock implements DeleteGoalUseCase {}

/// Kasa akışları: cüzdana/deftere DOKUNMADAN para kasa ↔ varlık arasında
/// yer değiştirir. Depo bir haritayla taklit edilir; böylece testler bloc'un
/// sonunda diskte NE kaldığını ölçer (ara çağrıları değil).
void main() {
  late Map<String, InvestmentEntity> store;
  late _Update update;
  late _Metrics metrics;
  late InvestmentBloc bloc;
  var failPotWrite = false;

  InvestmentEntity pot({double balance = 1000}) => InvestmentEntity(
        id: 'pot',
        userId: 'u',
        walletId: 'w',
        name: 'Acil durum',
        amount: balance,
        currentValue: balance,
        type: InvestmentType.cash,
        color: const Color(0xFF26A69A),
        dateAdded: DateTime(2026, 9, 1),
      );

  InvestmentEntity gold({double cost = 400, double value = 400}) =>
      InvestmentEntity(
        id: 'gold',
        userId: 'u',
        walletId: 'w',
        name: 'Gram altın',
        amount: cost,
        currentValue: value,
        type: InvestmentType.gold,
        color: const Color(0xFFFFC107),
        dateAdded: DateTime(2026, 9, 1),
      );

  setUpAll(() => registerFallbackValue(pot()));

  setUp(() {
    store = {};
    failPotWrite = false;
    final get = _Get();
    final add = _Add();
    update = _Update();
    final delete = _Delete();
    metrics = _Metrics();
    final getGoals = _GetGoals();
    when(() => get.call(
            userId: any(named: 'userId'), walletId: any(named: 'walletId')))
        .thenAnswer((_) async => Right(store.values.toList()));
    when(() => add.call(any())).thenAnswer((inv) async {
      final i = inv.positionalArguments.first as InvestmentEntity;
      store[i.id!] = i;
      return const Right(null);
    });
    when(() => update.call(any())).thenAnswer((inv) async {
      final i = inv.positionalArguments.first as InvestmentEntity;
      if (failPotWrite && i.type == InvestmentType.cash) {
        return const Left(CacheFailure('disk dolu'));
      }
      store[i.id!] = i;
      return const Right(null);
    });
    when(() => delete.call(any())).thenAnswer((inv) async {
      store.remove(inv.positionalArguments.first as String);
      return const Right(null);
    });
    when(() => metrics.syncInvestment(any())).thenAnswer((_) async {});
    when(() => metrics.releaseAdoptedMovements(
          walletId: any(named: 'walletId'),
          linkedRecordIds: any(named: 'linkedRecordIds'),
        )).thenAnswer((_) async => const []);
    when(() => getGoals(
            userId: any(named: 'userId'), walletId: any(named: 'walletId')))
        .thenAnswer((_) async => const Right([]));
    bloc = InvestmentBloc(
      getInvestmentsUseCase: get,
      addInvestmentUseCase: add,
      updateInvestmentUseCase: update,
      deleteInvestmentUseCase: delete,
      getLiveQuoteUseCase: _Quote(),
      getGoalsUseCase: getGoals,
      saveGoalUseCase: _SaveGoal(),
      deleteGoalUseCase: _DeleteGoal(),
      walletMetricsService: metrics,
      transactionsChangedNotifier: TransactionsChangedNotifier(),
    );
  });

  tearDown(() => bloc.close());

  Future<List<InvestmentState>> run(InvestmentEvent event) async {
    final states = <InvestmentState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(event);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    return states;
  }

  void expectLedgerUntouched() {
    verifyNever(() => metrics.recordCashMovement(
          walletId: any(named: 'walletId'),
          userId: any(named: 'userId'),
          amount: any(named: 'amount'),
          isIncome: any(named: 'isIncome'),
          title: any(named: 'title'),
          tag: any(named: 'tag'),
          date: any(named: 'date'),
          linkedRecordId: any(named: 'linkedRecordId'),
        ));
    verifyNever(() => metrics.recordCashMovements(
          walletId: any(named: 'walletId'),
          entries: any(named: 'entries'),
        ));
  }

  test('kasadan alım: kasa düşer, varlık yazılır, defter değişmez', () async {
    store['pot'] = pot();
    final states = await run(CreateInvestmentEvent(
      investment: gold(),
      userId: 'u',
      walletId: 'w',
      cashSource: const FromSavingsPot('pot'),
    ));
    expect(states.whereType<InvestmentActionSuccess>(), isNotEmpty);
    expect(store['pot']!.amount, 600);
    expect(store['pot']!.bookedCost, 600);
    expect(store['gold']!.bookedCost, 400,
        reason: 'hatalı giriş silmesi kasadan gelen parayı iade edebilmeli');
    expectLedgerUntouched();
  });

  test('kasa yetmiyorsa hiçbir şey yazılmaz', () async {
    store['pot'] = pot(balance: 100);
    final states = await run(CreateInvestmentEvent(
      investment: gold(),
      userId: 'u',
      walletId: 'w',
      cashSource: const FromSavingsPot('pot'),
    ));
    expect(states.whereType<InvestmentError>().single.notice,
        isA<PotUnavailableNotice>());
    expect(store.keys, ['pot']);
    expect(store['pot']!.amount, 100);
  });

  test('kasa yazılamazsa yeni varlık geri silinir (yarım işlem yok)', () async {
    store['pot'] = pot();
    failPotWrite = true;
    await run(CreateInvestmentEvent(
      investment: gold(),
      userId: 'u',
      walletId: 'w',
      cashSource: const FromSavingsPot('pot'),
    ));
    expect(store.keys, ['pot']);
    expect(store['pot']!.amount, 1000);
  });

  test('kasadan katkı: maliyet artışı kasadan düşer', () async {
    store['pot'] = pot();
    store['gold'] = gold();
    await run(UpdateInvestmentEvent(
      investment: gold(cost: 650, value: 650),
      userId: 'u',
      walletId: 'w',
      prevAmount: 400,
      newAmount: 650,
      bookingDate: DateTime(2026, 9, 25),
      cashSource: const FromSavingsPot('pot'),
    ));
    expect(store['pot']!.amount, 750);
    expect(store['gold']!.amount, 650);
    expect(store['gold']!.bookedCost, 650);
    expectLedgerUntouched();
  });

  test('kasaya satış: bedel kasaya girer, geri alma kasayı da döndürür',
      () async {
    store['pot'] = pot(balance: 200);
    store['gold'] = gold(cost: 400, value: 500);
    final states = await run(DeleteInvestmentEvent(
      id: 'gold',
      userId: 'u',
      walletId: 'w',
      amount: 400,
      currentValue: 500,
      dateAdded: DateTime(2026, 9, 1),
      recordSale: true,
      targetPot: store['pot'],
    ));
    expect(store.containsKey('gold'), isFalse);
    expect(store['pot']!.amount, 700);
    expect(store['pot']!.bookedCost, 600, reason: '200 + satılanın 400\'ü');
    expect(store['pot']!.unbookedCost, 100, reason: 'kâr defterde yok');
    expectLedgerUntouched();

    final undo = states.whereType<InvestmentActionSuccess>().single.undo
        as InvestmentDeletionUndo;
    expect(undo.alsoRestore.single.amount, 200);
    expect(undo.investment.id, 'gold');
  });

  test('kasadan kasaya aktarım kısmi satış yolundan geçer', () async {
    store['pot'] = pot();
    store['tatil'] = pot(balance: 0).copyWith(id: 'tatil', name: 'Tatil');
    await run(PartialSellInvestmentEvent(
      previous: store['pot']!,
      remaining: store['pot']!.copyWith(amount: 700, currentValue: 700),
      proceeds: 300,
      userId: 'u',
      walletId: 'w',
      targetPot: store['tatil'],
    ));
    expect(store['pot']!.amount, 700);
    expect(store['tatil']!.amount, 300);
    expect(store['pot']!.bookedCost + store['tatil']!.bookedCost, 1000);
    expectLedgerUntouched();
  });

  test('kasa kendisine satılamaz', () async {
    store['pot'] = pot();
    final states = await run(PartialSellInvestmentEvent(
      previous: store['pot']!,
      remaining: store['pot']!.copyWith(amount: 700, currentValue: 700),
      proceeds: 300,
      userId: 'u',
      walletId: 'w',
      targetPot: store['pot'],
    ));
    expect(states.whereType<InvestmentError>(), isNotEmpty);
    expect(store['pot']!.amount, 1000);
  });

  test('cüzdandan kasaya para: "Birikime Aktarım" etiketiyle yazılır',
      () async {
    store['pot'] = pot();
    when(() => metrics.recordCashMovement(
          walletId: any(named: 'walletId'),
          userId: any(named: 'userId'),
          amount: any(named: 'amount'),
          isIncome: any(named: 'isIncome'),
          title: any(named: 'title'),
          tag: any(named: 'tag'),
          date: any(named: 'date'),
          linkedRecordId: any(named: 'linkedRecordId'),
        )).thenAnswer((_) async => true);
    await run(UpdateInvestmentEvent(
      investment: pot(balance: 1250),
      userId: 'u',
      walletId: 'w',
      prevAmount: 1000,
      newAmount: 1250,
      bookingDate: DateTime(2026, 9, 25),
      cashSource: const NewCashMovement(),
    ));
    verify(() => metrics.recordCashMovement(
          walletId: 'w',
          userId: 'u',
          amount: 250,
          isIncome: false,
          title: 'Acil durum',
          tag: CashMovementTags.savingsDeposit,
          date: any(named: 'date'),
          linkedRecordId: 'pot',
        )).called(1);
  });

  test(
      'defterdeki satır kasaya bağlanınca "Birikime Aktarım" olur, ikinci '
      'hareket yazılmaz', () async {
    final line = TransactionEntity(
      id: 'row',
      userId: 'u',
      walletId: 'w',
      title: 'HAVALE',
      tag: 'cat-diger',
      amount: 300,
      date: DateTime(2026, 9, 20),
      type: TransactionTypeModel.expense,
    );
    when(() => metrics.adoptCashMovement(
          walletId: any(named: 'walletId'),
          transactionId: any(named: 'transactionId'),
          tag: any(named: 'tag'),
          linkedRecordId: any(named: 'linkedRecordId'),
          expectIncome: any(named: 'expectIncome'),
          expectAmount: any(named: 'expectAmount'),
        )).thenAnswer((_) async => line);
    await run(CreateInvestmentEvent(
      investment: pot(balance: 300).copyWith(id: 'yeni'),
      userId: 'u',
      walletId: 'w',
      cashSource: AdoptedCashMovement(line),
    ));
    verify(() => metrics.adoptCashMovement(
          walletId: 'w',
          transactionId: 'row',
          tag: CashMovementTags.savingsDeposit,
          linkedRecordId: 'yeni',
          expectIncome: false,
          expectAmount: 300,
        )).called(1);
    expect(store['yeni']!.bookedCost, 300);
    expectLedgerUntouched();
  });

  group('ana kasa işareti (SetPrimaryPotEvent)', () {
    InvestmentEntity named(String id,
            {bool primary = false, double balance = 500}) =>
        pot(balance: balance).copyWith(id: id, name: id, isPrimary: primary);

    test('işaretler; ÖNCEKİ ana kasanın işareti düşer (en çok bir tane)',
        () async {
      store['eski'] = named('eski', primary: true);
      store['yeni'] = named('yeni');
      store['gold'] = gold();

      final states =
          await run(SetPrimaryPotEvent(pot: store['yeni']!, primary: true));

      final success = states.whereType<InvestmentActionSuccess>().single;
      expect(success.notice,
          const PrimaryPotChangedNotice(potName: 'yeni', isPrimary: true));
      expect(store['yeni']!.isPrimary, isTrue);
      expect(store['eski']!.isPrimary, isFalse);
      expect(store.values.where((i) => i.isPrimary), hasLength(1));
      expectLedgerUntouched();
    });

    test('işaret kaldırılabilir: hiçbir kasa ana kalmaz', () async {
      store['ana'] = named('ana', primary: true);

      await run(SetPrimaryPotEvent(pot: store['ana']!, primary: false));

      expect(store['ana']!.isPrimary, isFalse);
      expectLedgerUntouched();
    });

    test('bayat kopya güncel bakiyeyi EZMEZ', () async {
      // Sayfadaki kopya 500 gösterirken depoda bakiye 800 olmuş.
      final stale = named('kasa', balance: 500);
      store['kasa'] = named('kasa', balance: 800);

      await run(SetPrimaryPotEvent(pot: stale, primary: true));

      expect(store['kasa']!.isPrimary, isTrue);
      expect(store['kasa']!.amount, 800);
    });

    test('kasa olmayan kayıt ya da silinmiş kasa: hiçbir şey yazılmaz',
        () async {
      store['eski'] = named('eski', primary: true);
      store['gold'] = gold();

      final onAsset =
          await run(SetPrimaryPotEvent(pot: store['gold']!, primary: true));
      final onMissing =
          await run(SetPrimaryPotEvent(pot: named('yok'), primary: true));

      expect(onAsset.whereType<InvestmentError>(), isNotEmpty);
      expect(onMissing.whereType<InvestmentError>(), isNotEmpty);
      expect(store['eski']!.isPrimary, isTrue);
      expect(store['gold']!.isPrimary, isFalse);
    });

    test('yazım hatasında başarı bildirilmez', () async {
      store['kasa'] = named('kasa');
      failPotWrite = true;

      final states =
          await run(SetPrimaryPotEvent(pot: store['kasa']!, primary: true));

      expect(states.whereType<InvestmentActionSuccess>(), isEmpty);
      expect(states.whereType<InvestmentError>(), isNotEmpty);
      expect(store['kasa']!.isPrimary, isFalse);
    });
  });
}
