import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/receivable_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/goal_repository.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---- In-memory fakes (mockito/mocktail bağımlılığı eklemeden) ----

class FakeWalletRepository implements WalletRepository {
  final Map<String, WalletEntity> store = {};

  @override
  Future<Either<Failure, WalletEntity?>> getWalletById(String walletId) async =>
      Right(store[walletId]);

  @override
  Future<Either<Failure, void>> updateWallet(WalletEntity wallet) async {
    store[wallet.id!] = wallet;
    return const Right(null);
  }

  @override
  Future<Either<Failure, String>> createWallet(WalletEntity wallet) async {
    store[wallet.id!] = wallet;
    return Right(wallet.id!);
  }

  @override
  Future<Either<Failure, void>> deleteWallet(String walletId) async {
    store.remove(walletId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<WalletEntity>>> getWallets(String userId) async =>
      Right(store.values.where((w) => w.userId == userId).toList());

  @override
  Future<Either<Failure, WalletEntity?>> getActiveWallet(String userId) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> setActiveWallet(
          {required String userId, required String newActiveWalletId}) async =>
      const Right(null);

  @override
  Stream<Either<Failure, List<WalletEntity>>> watchWallets(String userId) =>
      const Stream.empty();
}

class FakeTransactionsRepository implements TransactionsRepository {
  final List<TransactionEntity> store = [];

  @override
  Future<Either<Failure, int>> countByTags(Set<String> tags) async =>
      Right(store.where((t) => tags.contains(t.tag)).length);

  @override
  Future<Either<Failure, int>> retagTransactions(
      Set<String> from, String to) async {
    var changed = 0;
    for (var i = 0; i < store.length; i++) {
      if (!from.contains(store[i].tag)) continue;
      store[i] = store[i].copyWith(tag: to);
      changed++;
    }
    return Right(changed);
  }

  @override
  Future<Either<Failure, String>> addTransaction(TransactionEntity t) async {
    store.add(t);
    return Right(t.id!);
  }

  @override
  Future<Either<Failure, void>> addTransactions(
      List<TransactionEntity> transactions) async {
    store.addAll(transactions);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
  }) async =>
      Right(store
          .where((t) => t.userId == userId && t.walletId == walletId)
          .toList());

  @override
  Future<Either<Failure, void>> deleteTransaction(
    String id, {
    bool keepReceiptFile = false,
  }) async {
    store.removeWhere((t) => t.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionById(
          String id) async =>
      Right(store.firstWhere((t) => t.id == id));

  @override
  Future<Either<Failure, void>> updateTransaction(TransactionEntity t) async {
    final i = store.indexWhere((e) => e.id == t.id);
    if (i >= 0) store[i] = t;
    return const Right(null);
  }

  @override
  Future<Either<Failure, Map<DateTime, List<TransactionEntity>>>>
      getTransactionsGroupedByDate({
    required String userId,
    required String walletId,
    TransactionTypeModel? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async =>
          const Right({});
}

class FakeDebtRepository implements DebtRepository {
  final List<DebtEntity> store = [];

  @override
  Future<Either<Failure, void>> addDebt(DebtEntity debt) async {
    store.add(debt);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<DebtEntity>>> getAllDebts() async =>
      Right(List<DebtEntity>.of(store));

  @override
  Future<Either<Failure, void>> updateDebt(DebtEntity debt) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> deleteDebt(String id) async {
    store.removeWhere((d) => d.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<DebtEntity>>> getDebtsByWalletId(
          String walletId) async =>
      Right(store.where((d) => d.walletId == walletId).toList());
}

class FakeReceivableRepository implements ReceivableRepository {
  final List<ReceivableEntity> store = [];

  @override
  Future<Either<Failure, void>> addReceivable(ReceivableEntity r) async {
    store.add(r);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateReceivable(ReceivableEntity r) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> deleteReceivable(String id) async {
    store.removeWhere((r) => r.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<ReceivableEntity>>> getReceivablesByWalletId(
          String walletId) async =>
      Right(store.where((r) => r.walletId == walletId).toList());
}

class FakeGoalRepository implements GoalRepository {
  final List<GoalEntity> store = [];

  @override
  Future<Either<Failure, List<GoalEntity>>> getGoals({
    required String userId,
    required String walletId,
  }) async =>
      Right(store
          .where((g) => g.userId == userId && g.walletId == walletId)
          .toList());

  @override
  Future<Either<Failure, void>> saveGoal(GoalEntity goal) async {
    final idx = store.indexWhere((g) => g.id == goal.id);
    idx >= 0 ? store[idx] = goal : store.add(goal);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteGoal(String id) async {
    store.removeWhere((g) => g.id == id);
    return const Right(null);
  }
}

class FakeInvestmentRepository implements InvestmentRepository {
  final List<InvestmentEntity> store = [];

  @override
  Future<Either<Failure, void>> addInvestment(
      InvestmentEntity investment) async {
    store.add(investment);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteInvestment(String id) async {
    store.removeWhere((i) => i.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<InvestmentEntity>>> getInvestments({
    required String userId,
    required String walletId,
  }) async =>
      Right(store
          .where((i) => i.userId == userId && i.walletId == walletId)
          .toList());

  @override
  Future<Either<Failure, void>> updateInvestment(
      InvestmentEntity investment) async {
    final idx = store.indexWhere((i) => i.id == investment.id);
    if (idx >= 0) store[idx] = investment;
    return const Right(null);
  }

  @override
  Future<Either<Failure, LivePriceQuote>> getLiveQuote({
    required String symbol,
    required InvestmentType type,
    required String targetCurrency,
  }) async =>
      const Right<Failure, LivePriceQuote>(LivePriceQuote(
          price: 0, currency: 'TRY', convertedPrice: 0, targetCurrency: 'TRY'));
}

/// Yazmayı her zaman başarısız kılan varyant (hata yolu testi).
class FailingTransactionsRepository extends FakeTransactionsRepository {
  @override
  Future<Either<Failure, String>> addTransaction(TransactionEntity t) async =>
      const Left(CacheFailure('yazılamadı'));

  @override
  Future<Either<Failure, void>> addTransactions(
          List<TransactionEntity> transactions) async =>
      const Left(CacheFailure('yazılamadı'));

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
  }) async =>
      const Left(CacheFailure('işlemler okunamadı'));
}

class FailingWalletRepository extends FakeWalletRepository {
  @override
  Future<Either<Failure, WalletEntity?>> getWalletById(String walletId) async =>
      const Left(CacheFailure('okunamadı'));
}

class ThrowingWalletRepository extends FakeWalletRepository {
  @override
  Future<Either<Failure, WalletEntity?>> getWalletById(String walletId) async {
    throw Exception('Database crash');
  }
}

class ToggleFailingWalletRepository extends FakeWalletRepository {
  int calls = 0;
  @override
  Future<Either<Failure, WalletEntity?>> getWalletById(String walletId) async {
    calls++;
    if (calls == 1) {
      return Right(store[walletId]);
    } else {
      return const Left(CacheFailure('Taze okunamadı'));
    }
  }
}

/// İlk okumada cüzdanı döndürüp sonraki okumalarda null dönen varyant:
/// cüzdanın iki okuma arasında silinmesini simüle eder (bayat kopyayla
/// dirilme regresyon testleri için). Store boş başlar; updateWallet çağrısı
/// store'a yazacağından dirilme `store.isEmpty` ile yakalanır.
class DisappearingWalletRepository extends FakeWalletRepository {
  DisappearingWalletRepository(this._first);
  final WalletEntity _first;
  int _calls = 0;

  @override
  Future<Either<Failure, WalletEntity?>> getWalletById(String walletId) async {
    _calls++;
    return Right(_calls == 1 ? _first : null);
  }
}

class FailingUpdateWalletRepository extends FakeWalletRepository {
  @override
  Future<Either<Failure, void>> updateWallet(WalletEntity wallet) async =>
      const Left(CacheFailure('güncellenemedi'));
}

class FailingDebtRepository extends FakeDebtRepository {
  @override
  Future<Either<Failure, List<DebtEntity>>> getDebtsByWalletId(
          String walletId) async =>
      const Left(CacheFailure('borçlar okunamadı'));
}

class FailingReceivableRepository extends FakeReceivableRepository {
  @override
  Future<Either<Failure, List<ReceivableEntity>>> getReceivablesByWalletId(
          String walletId) async =>
      const Left(CacheFailure('alacaklar okunamadı'));
}

class FailingInvestmentRepository extends FakeInvestmentRepository {
  @override
  Future<Either<Failure, List<InvestmentEntity>>> getInvestments({
    required String userId,
    required String walletId,
  }) async =>
      const Left(CacheFailure('yatırımlar okunamadı'));
}

/// Her okuma/yazmada event loop'a dönen varyant: eşzamanlı akışların
/// araya girme pencerelerini büyütür (yarış testleri için).
class YieldingWalletRepository extends FakeWalletRepository {
  @override
  Future<Either<Failure, WalletEntity?>> getWalletById(String walletId) async {
    await Future<void>.delayed(Duration.zero);
    return super.getWalletById(walletId);
  }

  @override
  Future<Either<Failure, void>> updateWallet(WalletEntity wallet) async {
    await Future<void>.delayed(Duration.zero);
    return super.updateWallet(wallet);
  }
}

// ---- Test helpers ----

WalletEntity _wallet({
  required String id,
  double balance = 0,
  double debt = 0,
  double? openingBalance,
  String userId = 'u',
}) =>
    WalletEntity(
      id: id,
      userId: userId,
      name: 'W',
      balance: balance,
      debt: debt,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'account_balance_wallet',
      createdAt: DateTime(2026, 1, 1),
      // Oluşturma semantiğiyle aynı: opening verilmezse balance.
      openingBalance: openingBalance ?? balance,
    );

TransactionEntity _income(String walletId, double amount) => TransactionEntity(
      id: 'tx-$amount-${DateTime.now().microsecondsSinceEpoch}',
      userId: 'u',
      walletId: walletId,
      title: 't',
      tag: 'g',
      amount: amount,
      date: DateTime(2026, 1, 1),
      type: TransactionTypeModel.income,
    );

DebtEntity _debt(
  String walletId, {
  required double principal,
  required double paid,
  required bool isPaid,
}) =>
    DebtEntity(
      calcMode: DebtCalcMode.none,
      // Faizsiz kişisel borç: toplam geri ödeme ana paranın kendisi.
      expectedTotalAmount: principal,
      id: 'd-$principal',
      userId: 'u',
      walletId: walletId,
      title: 't',
      counterparty: 'c',
      type: DebtType.personalDebt,
      principalAmount: principal,
      interestRate: 0,
      termMonths: 12,
      startDate: DateTime(2026, 1, 1),
      payments: paid > 0
          ? [Payment(id: 'p1', date: DateTime(2026, 1, 2), amount: paid)]
          : const [],
      isPaid: isPaid,
    );

void main() {
  late FakeWalletRepository wallets;
  late FakeTransactionsRepository txs;
  late FakeDebtRepository debts;
  late WalletMetricsService service;

  setUp(() {
    wallets = FakeWalletRepository();
    txs = FakeTransactionsRepository();
    debts = FakeDebtRepository();
    service = WalletMetricsService(
      walletRepository: wallets,
      debtRepository: debts,
      receivableRepository: FakeReceivableRepository(),
      investmentRepository: FakeInvestmentRepository(),
      goalRepository: FakeGoalRepository(),
      transactionsRepository: txs,
      transactionsChangedNotifier: TransactionsChangedNotifier(),
    );
  });

  group('recordCashMovement', () {
    test('gelir: sistem işlemi ekler ve bakiyeyi artırır', () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 100);

      await service.recordCashMovement(
        walletId: 'w',
        userId: 'u',
        amount: 50,
        isIncome: true,
        title: 'Borç',
        tag: 'Borç',
      );

      expect(txs.store.length, 1);
      expect(txs.store.single.isSystem, true);
      expect(txs.store.single.type, TransactionTypeModel.income);
      expect(txs.store.single.amount, 50);
      expect(wallets.store['w']!.balance, 150);
    });

    test('gider: bakiyeyi azaltır', () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 100);

      await service.recordCashMovement(
        walletId: 'w',
        userId: 'u',
        amount: 30,
        isIncome: false,
        title: 'x',
        tag: 'y',
      );

      expect(wallets.store['w']!.balance, 70);
      expect(txs.store.single.type, TransactionTypeModel.expense);
    });

    test('başarıda true döner', () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 100, openingBalance: 100);

      final ok = await service.recordCashMovement(
        walletId: 'w',
        userId: 'u',
        amount: 10,
        isIncome: true,
        title: 'x',
        tag: 'y',
      );

      expect(ok, true);
    });

    test('işlem yazılamazsa false döner ve bakiye değişmez', () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 100, openingBalance: 100);
      final failingService = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: FailingTransactionsRepository(),
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      final ok = await failingService.recordCashMovement(
        walletId: 'w',
        userId: 'u',
        amount: 50,
        isIncome: true,
        title: 'x',
        tag: 'y',
      );

      expect(ok, false);
      expect(wallets.store['w']!.balance, 100);
    });

    test('ardışık ekle/sil dizisi sonrası bakiye = opening + Σ signed',
        () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 100, openingBalance: 100);

      await service.recordCashMovement(
          walletId: 'w',
          userId: 'u',
          amount: 40,
          isIncome: true,
          title: 'a',
          tag: 't');
      await service.recordCashMovement(
          walletId: 'w',
          userId: 'u',
          amount: 15,
          isIncome: false,
          title: 'b',
          tag: 't');

      expect(wallets.store['w']!.balance, 125); // 100 + 40 - 15
      // İşlem silinince yeniden hesap silmeyi de yansıtır.
      txs.store.removeWhere((t) => t.amount == 40);
      await service.syncBalance('w');
      expect(wallets.store['w']!.balance, 85); // 100 - 15
    });
  });

  group('syncBalance', () {
    test('sapan bakiyeyi onarır', () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 999, openingBalance: 100);
      txs.store.add(_income('w', 20));

      await service.syncBalance('w');

      expect(wallets.store['w']!.balance, 120); // 100 + 20
    });

    test('tutarlıyken yazma yapmaz ve true döner', () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 120, openingBalance: 100);
      txs.store.add(_income('w', 20));
      final before = wallets.store['w'];

      final ok = await service.syncBalance('w');

      expect(ok, true);
      expect(identical(wallets.store['w'], before), true);
    });

    test('cüzdan yoksa false döner', () async {
      expect(await service.syncBalance('yok'), false);
    });

    test('cüzdan iki okuma arasında silinirse false döner ve diriltmez',
        () async {
      final vanishing =
          DisappearingWalletRepository(_wallet(id: 'w', balance: 100));
      final svc = WalletMetricsService(
        walletRepository: vanishing,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );
      // Bakiye sapması yarat ki yazma yoluna girilsin (100 + 50 ≠ 100).
      txs.store.add(_income('w', 50));

      final ok = await svc.syncBalance('w');

      expect(ok, false);
      // updateWallet hiç çağrılmadı → silinmiş cüzdan geri yazılmadı.
      expect(vanishing.store, isEmpty);
    });

    test('manuel bakiye düzenleme sonrası idempotent (opening ayarlanmışsa)',
        () async {
      // Repository impl manuel düzenlemede opening'i balance−Σtx koruyacak
      // şekilde ayarlar; sync bu durumda hiçbir şeyi değiştirmemeli.
      txs.store.add(_income('w', 20));
      wallets.store['w'] = _wallet(id: 'w', balance: 500, openingBalance: 480);

      final ok = await service.syncBalance('w');

      expect(ok, true);
      expect(wallets.store['w']!.balance, 500);
      expect(wallets.store['w']!.openingBalance, 480);
    });
  });

  group('syncDebt', () {
    test('isPaid borçları hariç tutar', () async {
      wallets.store['w'] = _wallet(id: 'w', debt: 0);
      debts.store.add(_debt('w', principal: 1000, paid: 0, isPaid: false));
      debts.store.add(_debt('w', principal: 500, paid: 500, isPaid: true));

      await service.syncDebt('w');

      expect(wallets.store['w']!.debt, 1000);
    });
  });

  group('syncCredit', () {
    test('isPaid alacakları hariç tutar ve cüzdanı günceller', () async {
      final receivables = FakeReceivableRepository();
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: receivables,
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      wallets.store['w'] = _wallet(id: 'w', balance: 100);
      receivables.store.add(ReceivableEntity(
        id: 'r1',
        userId: 'u',
        walletId: 'w',
        debtorName: 'C1',
        amount: 200,
        dueDate: DateTime.now(),
        isPaid: false,
        createdAt: DateTime(2026, 1, 1),
      ));
      receivables.store.add(ReceivableEntity(
        id: 'r2',
        userId: 'u',
        walletId: 'w',
        debtorName: 'C2',
        amount: 300,
        dueDate: DateTime.now(),
        isPaid: true,
        createdAt: DateTime(2026, 1, 1),
      ));

      await svc.syncCredit('w');

      expect(wallets.store['w']!.credit, 200);
    });

    test('hata aldığında (Left(Failure)) cüzdanı güncellemez', () async {
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: FailingReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      wallets.store['w'] = _wallet(id: 'w', balance: 100);

      await svc.syncCredit('w');

      expect(wallets.store['w']!.credit, 0);
    });
  });

  group('syncInvestment', () {
    test('yatırım tutarlarını toplayıp cüzdanın investment alanını günceller',
        () async {
      final investments = FakeInvestmentRepository();
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: investments,
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      wallets.store['w'] = _wallet(id: 'w', balance: 100);
      investments.store.add(InvestmentEntity(
        id: 'i1',
        userId: 'u',
        walletId: 'w',
        name: 'BTC',
        amount: 100,
        currentValue: 120,
        type: InvestmentType.stock,
        color: const Color(0xFF000000),
        dateAdded: DateTime.now(),
      ));
      investments.store.add(InvestmentEntity(
        id: 'i2',
        userId: 'u',
        walletId: 'w',
        name: 'Gold',
        amount: 200,
        currentValue: 210,
        type: InvestmentType.gold,
        color: const Color(0xFF000000),
        dateAdded: DateTime.now(),
      ));

      await svc.syncInvestment('w');

      expect(wallets.store['w']!.investment, 330);
    });

    test('cüzdan iki okuma arasında silinirse bayat kopya yazılmaz', () async {
      final vanishing = DisappearingWalletRepository(_wallet(id: 'w'));
      final investments = FakeInvestmentRepository();
      final svc = WalletMetricsService(
        walletRepository: vanishing,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: investments,
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );
      // investment 0 → 120 sapması yarat ki yazma yoluna girilsin.
      investments.store.add(InvestmentEntity(
        id: 'i1',
        userId: 'u',
        walletId: 'w',
        name: 'BTC',
        amount: 100,
        currentValue: 120,
        type: InvestmentType.stock,
        color: const Color(0xFF000000),
        dateAdded: DateTime.now(),
      ));

      await svc.syncInvestment('w');

      expect(vanishing.store, isEmpty);
    });

    test('hata aldığında cüzdanı güncellemez', () async {
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FailingInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      wallets.store['w'] = _wallet(id: 'w', balance: 100);

      await svc.syncInvestment('w');

      expect(wallets.store['w']!.investment, 0);
    });
  });

  group('purgeWalletData', () {
    test('cüzdana ait tüm alt kayıtları siler', () async {
      final receivables = FakeReceivableRepository();
      final investments = FakeInvestmentRepository();
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: receivables,
        investmentRepository: investments,
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      wallets.store['w'] = _wallet(id: 'w');

      txs.store.add(TransactionEntity(
          id: 't1',
          userId: 'u',
          walletId: 'w',
          title: 'T1',
          tag: 'tag',
          amount: 10,
          date: DateTime.now(),
          type: TransactionTypeModel.income));
      txs.store.add(TransactionEntity(
          id: 't_other',
          userId: 'u',
          walletId: 'other',
          title: 'T_other',
          tag: 'tag',
          amount: 10,
          date: DateTime.now(),
          type: TransactionTypeModel.income));

      debts.store.add(DebtEntity(
          calcMode: DebtCalcMode.none,
          expectedTotalAmount: 10,
          id: 'd1',
          userId: 'u',
          walletId: 'w',
          title: 'D1',
          counterparty: 'c',
          principalAmount: 10,
          interestRate: 0,
          termMonths: 1,
          startDate: DateTime.now(),
          type: DebtType.personalDebt));

      receivables.store.add(ReceivableEntity(
        id: 'r1',
        userId: 'u',
        walletId: 'w',
        debtorName: 'c',
        amount: 10,
        dueDate: DateTime.now(),
        createdAt: DateTime(2026, 1, 1),
      ));

      investments.store.add(InvestmentEntity(
          id: 'i1',
          userId: 'u',
          walletId: 'w',
          name: 'i1',
          amount: 10,
          currentValue: 10,
          type: InvestmentType.stock,
          color: const Color(0xff000000),
          dateAdded: DateTime.now()));

      await svc.purgeWalletData('w', 'u');

      expect(txs.store.where((t) => t.walletId == 'w'), isEmpty);
      expect(txs.store.where((t) => t.walletId == 'other').length, 1);
      expect(debts.store.where((d) => d.walletId == 'w'), isEmpty);
      expect(receivables.store.where((r) => r.walletId == 'w'), isEmpty);
      expect(investments.store.where((i) => i.walletId == 'w'), isEmpty);
    });
  });

  group('WalletMetricsService failure handling', () {
    test('syncBalance returns false when transaction fetch fails', () async {
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: FailingTransactionsRepository(),
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      wallets.store['w'] = _wallet(id: 'w');

      final result = await svc.syncBalance('w');
      expect(result, false);
    });

    test('syncBalance returns false when wallet get fails', () async {
      final svc = WalletMetricsService(
        walletRepository: FailingWalletRepository(),
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      final result = await svc.syncBalance('w');
      expect(result, false);
    });

    test('syncDebt logs error but doesn\'t throw when debt fetch fails',
        () async {
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: FailingDebtRepository(),
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      wallets.store['w'] = _wallet(id: 'w');

      expect(() => svc.syncDebt('w'), returnsNormally);
    });

    test('recordCashMovement returns false when db throws exception', () async {
      final svc = WalletMetricsService(
        walletRepository: ThrowingWalletRepository(),
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      final result = await svc.recordCashMovement(
        walletId: 'w',
        userId: 'u',
        amount: 10,
        isIncome: true,
        title: 't',
        tag: 'g',
      );
      expect(result, false);
    });

    test('syncBalance returns false when fresh wallet get fails', () async {
      final togglingWallets = ToggleFailingWalletRepository();
      togglingWallets.store['w'] =
          _wallet(id: 'w', balance: 100, openingBalance: 100);
      txs.store.add(_income('w', 20));

      final svc = WalletMetricsService(
        walletRepository: togglingWallets,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      final result = await svc.syncBalance('w');
      expect(result, false);
    });

    test('syncBalance returns false when updateWallet fails', () async {
      final failingUpdateWallets = FailingUpdateWalletRepository();
      failingUpdateWallets.store['w'] =
          _wallet(id: 'w', balance: 100, openingBalance: 100);
      txs.store.add(_income('w', 20));

      final svc = WalletMetricsService(
        walletRepository: failingUpdateWallets,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      final result = await svc.syncBalance('w');
      expect(result, false);
    });

    test('syncDebt logs error but doesn\'t throw when wallet get fails',
        () async {
      final svc = WalletMetricsService(
        walletRepository: FailingWalletRepository(),
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      expect(() => svc.syncDebt('w'), returnsNormally);
    });

    test('syncCredit logs error but doesn\'t throw when wallet get fails',
        () async {
      final svc = WalletMetricsService(
        walletRepository: FailingWalletRepository(),
        debtRepository: debts,
        receivableRepository: FailingReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      expect(() => svc.syncCredit('w'), returnsNormally);
    });

    test('syncInvestment logs error but doesn\'t throw when wallet get fails',
        () async {
      final svc = WalletMetricsService(
        walletRepository: FailingWalletRepository(),
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      expect(() => svc.syncInvestment('w'), returnsNormally);
    });

    test(
        'syncInvestment logs error but doesn\'t throw when fresh wallet get fails',
        () async {
      final togglingWallets = ToggleFailingWalletRepository();
      togglingWallets.store['w'] = _wallet(id: 'w');

      final investments = FakeInvestmentRepository();
      investments.store.add(InvestmentEntity(
          id: 'i1',
          userId: 'u',
          walletId: 'w',
          name: 'BTC',
          amount: 100,
          currentValue: 120,
          type: InvestmentType.stock,
          color: const Color(0xff000000),
          dateAdded: DateTime.now()));

      final svc = WalletMetricsService(
        walletRepository: togglingWallets,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: investments,
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      expect(() => svc.syncInvestment('w'), returnsNormally);
    });

    test('purgeWalletData does not throw when transactions fetch fails',
        () async {
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: FailingTransactionsRepository(),
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      expect(() => svc.purgeWalletData('w', 'u'), returnsNormally);
    });

    test('purgeWalletData does not throw when debts fetch fails', () async {
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: FailingDebtRepository(),
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      expect(() => svc.purgeWalletData('w', 'u'), returnsNormally);
    });

    test('purgeWalletData does not throw when receivables fetch fails',
        () async {
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: FailingReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      expect(() => svc.purgeWalletData('w', 'u'), returnsNormally);
    });

    test('purgeWalletData does not throw when investments fetch fails',
        () async {
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FailingInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      expect(() => svc.purgeWalletData('w', 'u'), returnsNormally);
    });
  });

  group('eşzamanlılık (cüzdan başına yazma kuyruğu)', () {
    test('paralel syncBalance + syncDebt kayıp güncelleme üretmez', () async {
      final yielding = YieldingWalletRepository();
      final svc = WalletMetricsService(
        walletRepository: yielding,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );
      // Bakiye sapmış (999) → syncBalance 120'ye onaracak; aynı anda
      // syncDebt debt=1000 yazacak. Kuyruk yoksa biri diğerinin yazımını
      // bayat kopyayla ezebilir.
      yielding.store['w'] = _wallet(id: 'w', balance: 999, openingBalance: 100);
      txs.store.add(_income('w', 20));
      debts.store.add(_debt('w', principal: 1000, paid: 0, isPaid: false));

      await Future.wait([
        svc.syncBalance('w'),
        svc.syncDebt('w'),
      ]);

      final w = yielding.store['w']!;
      expect(w.balance, 120, reason: 'syncDebt bayat balance yazmamalı');
      expect(w.debt, 1000, reason: 'syncBalance debt güncellemesini ezmemeli');
    });

    test('paralel recordCashMovement çiftinde defter ve bakiye tutarlı',
        () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 100, openingBalance: 100);

      await Future.wait([
        service.recordCashMovement(
            walletId: 'w',
            userId: 'u',
            amount: 40,
            isIncome: true,
            title: 'a',
            tag: 't'),
        service.recordCashMovement(
            walletId: 'w',
            userId: 'u',
            amount: 15,
            isIncome: false,
            title: 'b',
            tag: 't'),
      ]);

      expect(txs.store.length, 2);
      expect(wallets.store['w']!.balance, 125); // 100 + 40 - 15
    });

    test('farklı cüzdanlar birbirini bloklamaz', () async {
      wallets.store['a'] = _wallet(id: 'a', balance: 10, openingBalance: 10);
      wallets.store['b'] = _wallet(id: 'b', balance: 20, openingBalance: 20);

      final results = await Future.wait([
        service.syncBalance('a'),
        service.syncBalance('b'),
      ]);

      expect(results, [true, true]);
    });
  });

  group('kayan-nokta / çoklu para birimi sağlamlığı', () {
    test('ondalık nakit hareketleri sonrası bakiye 2-hane gösterimde doğru',
        () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 0, openingBalance: 0);

      for (var i = 0; i < 10; i++) {
        await service.recordCashMovement(
          walletId: 'w',
          userId: 'u',
          amount: 0.1,
          isIncome: true,
          title: 'x',
          tag: 't',
        );
      }

      final b = wallets.store['w']!.balance;
      // syncBalance kuruşa yuvarlar; 10 × 0.1 artık tam 1.0 yazılır.
      expect(b, 1.0);
      expect(b.toStringAsFixed(2), '1.00');
    });

    test('recordCashMovement tutarı ve bakiyeyi kuruş-temiz yazar', () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 0, openingBalance: 0);

      // Hesaplanmış "kirli" tutar (0.1 + 0.2 = 0.30000000000000004).
      await service.recordCashMovement(
        walletId: 'w',
        userId: 'u',
        amount: 0.1 + 0.2,
        isIncome: true,
        title: 'x',
        tag: 't',
      );

      expect(txs.store.single.amount, 0.3);
      expect(wallets.store['w']!.balance, 0.3);
    });

    test(
        'syncInvestment farklı currency etiketli yatırımları currentValue '
        '(cüzdanın birimi) üzerinden toplar', () async {
      final investments = FakeInvestmentRepository();
      final svc = WalletMetricsService(
        walletRepository: wallets,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: investments,
        goalRepository: FakeGoalRepository(),
        transactionsRepository: txs,
        transactionsChangedNotifier: TransactionsChangedNotifier(),
      );

      wallets.store['w'] = _wallet(id: 'w');
      // currency yalnız fiyat-KAYNAĞININ etiketi (AAPL → USD); değerleme
      // birimi cüzdandan gelir ve currentValue hep o birimdedir.
      investments.store.add(InvestmentEntity(
        id: 'usd',
        userId: 'u',
        walletId: 'w',
        name: 'Apple',
        amount: 1000,
        currentValue: 2500, // cüzdanın biriminde karşılığı
        type: InvestmentType.stock,
        color: const Color(0xFF000000),
        dateAdded: DateTime(2026, 1, 1),
        currency: 'USD',
      ));
      investments.store.add(InvestmentEntity(
        id: 'try',
        userId: 'u',
        walletId: 'w',
        name: 'Altın',
        amount: 5000,
        currentValue: 5200,
        type: InvestmentType.gold,
        color: const Color(0xFF000000),
        dateAdded: DateTime(2026, 1, 1),
        currency: 'TRY',
      ));

      await svc.syncInvestment('w');

      // Toplam, fiyat-kaynağı etiketinden bağımsız: 2500 + 5200 = 7700.
      expect(wallets.store['w']!.investment, 7700);
    });
  });
}
