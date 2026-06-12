import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/receivable_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';
import 'package:dartz/dartz.dart';
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
  Future<Either<Failure, String>> addTransaction(TransactionEntity t) async {
    store.add(t);
    return Right(t.id!);
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
  Future<Either<Failure, void>> deleteTransaction(String id) async {
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
  Future<Either<Failure, void>> deleteReceivable(String id) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<ReceivableEntity>>> getReceivablesByWalletId(
          String walletId) async =>
      Right(store.where((r) => r.walletId == walletId).toList());
}

class FakeInvestmentRepository implements InvestmentRepository {
  @override
  Future<Either<Failure, void>> addInvestment(
          InvestmentEntity investment) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> deleteInvestment(String id) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, List<InvestmentEntity>>> getInvestments({
    required String userId,
    required String walletId,
  }) async =>
      Right<Failure, List<InvestmentEntity>>(const []);

  @override
  Future<Either<Failure, void>> updateInvestment(
          InvestmentEntity investment) async =>
      Right<Failure, void>(null);

  @override
  Future<Either<Failure, LivePriceQuote>> getLiveQuote({
    required String symbol,
    required InvestmentType type,
  }) async =>
      const Right<Failure, LivePriceQuote>(
          LivePriceQuote(price: 0, currency: 'TRY', priceTl: 0));
}

/// addTransaction'ı her zaman başarısız kılan varyant (hata yolu testi).
class FailingTransactionsRepository extends FakeTransactionsRepository {
  @override
  Future<Either<Failure, String>> addTransaction(TransactionEntity t) async =>
      const Left(CacheFailure('yazılamadı'));
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
      iconName: 'wallet',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: openingBalance,
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
          ? [Payment(date: DateTime(2026, 1, 2), amount: paid)]
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
      transactionsRepository: txs,
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
        transactionsRepository: FailingTransactionsRepository(),
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
    test('eski cüzdanda openingBalance geri doldurulur, bakiye korunur',
        () async {
      wallets.store['w'] = _wallet(id: 'w', balance: 120, openingBalance: null);
      txs.store.add(_income('w', 20));

      await service.syncBalance('w');

      final w = wallets.store['w']!;
      expect(w.openingBalance, 100); // 120 - 20
      expect(w.balance, 120); // opening + sum
    });

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

  group('eşzamanlılık (cüzdan başına yazma kuyruğu)', () {
    test('paralel syncBalance + syncDebt kayıp güncelleme üretmez', () async {
      final yielding = YieldingWalletRepository();
      final svc = WalletMetricsService(
        walletRepository: yielding,
        debtRepository: debts,
        receivableRepository: FakeReceivableRepository(),
        investmentRepository: FakeInvestmentRepository(),
        transactionsRepository: txs,
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
}
