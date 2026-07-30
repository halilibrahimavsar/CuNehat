import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAddTransactionUseCase extends Mock implements AddTransactionUseCase {}

class MockAddDebtUseCase extends Mock implements AddDebtUseCase {}

class MockAddReceivableUseCase extends Mock implements AddReceivableUseCase {}

class MockAddInvestmentUseCase extends Mock implements AddInvestmentUseCase {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

class MockReceiptStorageService extends Mock implements ReceiptStorageService {}

void main() {
  late MockAddTransactionUseCase addTransaction;
  late MockAddDebtUseCase addDebt;
  late MockAddReceivableUseCase addReceivable;
  late MockAddInvestmentUseCase addInvestment;
  late MockTransactionsRepository transactionsRepository;
  late MockWalletMetricsService metrics;
  late TransactionsChangedNotifier notifier;
  late MockReceiptStorageService receipts;
  late DeletionUndoService service;

  final transaction = TransactionEntity(
    id: 'tx_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    title: 'Market',
    tag: 'Food',
    amount: 150,
    date: DateTime(2026, 3, 4),
    type: TransactionTypeModel.expense,
  );

  final debt = DebtEntity(
    id: 'debt_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    title: 'Kredi',
    counterparty: 'Banka',
    type: DebtType.bankLoan,
    principalAmount: 10000,
    interestRate: 1.5,
    termMonths: 12,
    startDate: DateTime(2026, 1, 10),
    payments: [Payment(date: DateTime(2026, 2, 10), amount: 900)],
  );

  final receivable = ReceivableEntity(
    id: 'rec_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    debtorName: 'Ahmet',
    amount: 500,
    dueDate: DateTime(2026, 5, 1),
    createdAt: DateTime(2026, 4, 1),
  );

  final investment = InvestmentEntity(
    id: 'inv_1',
    userId: 'user_1',
    walletId: 'wallet_1',
    name: 'Gram Altın',
    amount: 3000,
    currentValue: 3400,
    type: InvestmentType.gold,
    color: Colors.amber,
    dateAdded: DateTime(2026, 2, 2),
    quantity: 1,
  );

  setUpAll(() {
    registerFallbackValue(transaction);
    registerFallbackValue(debt);
    registerFallbackValue(receivable);
    registerFallbackValue(investment);
  });

  setUp(() {
    addTransaction = MockAddTransactionUseCase();
    addDebt = MockAddDebtUseCase();
    addReceivable = MockAddReceivableUseCase();
    addInvestment = MockAddInvestmentUseCase();
    transactionsRepository = MockTransactionsRepository();
    metrics = MockWalletMetricsService();
    notifier = TransactionsChangedNotifier();
    receipts = MockReceiptStorageService();

    service = DeletionUndoService(
      addTransaction,
      addDebt,
      addReceivable,
      addInvestment,
      transactionsRepository,
      metrics,
      notifier,
      receipts,
    );

    when(() => metrics.syncBalance(any())).thenAnswer((_) async => true);
    when(() => metrics.syncDebt(any())).thenAnswer((_) async {});
    when(() => metrics.syncCredit(any())).thenAnswer((_) async {});
    when(() => metrics.syncInvestment(any())).thenAnswer((_) async {});
    when(() => transactionsRepository.deleteTransaction(any(),
        keepReceiptFile: any(named: 'keepReceiptFile'))).thenAnswer(
      (_) async => const Right(null),
    );
  });

  tearDown(() => notifier.dispose());

  group('restore — işlem', () {
    test('kaydı AYNI kimlikle geri yazar ve bakiyeyi senkronlar', () async {
      when(() => addTransaction(any()))
          .thenAnswer((_) async => const Right('tx_1'));

      final ok = await service.restore(TransactionDeletionUndo(
        transaction: transaction,
        userId: 'user_1',
        walletId: 'wallet_1',
      ));

      expect(ok, isTrue);
      // Kimlik korunmalı: yeni id ile yazım "geri alma" değil, yeni kayıt olur.
      final restored = verify(() => addTransaction(captureAny()))
          .captured
          .single as TransactionEntity;
      expect(restored.id, 'tx_1');
      expect(restored, transaction);
      verify(() => metrics.syncBalance('wallet_1')).called(1);
    });

    test('geri yazım başarısızsa false döner', () async {
      when(() => addTransaction(any()))
          .thenAnswer((_) async => const Left(CacheFailure('yazılamadı')));

      final ok = await service.restore(TransactionDeletionUndo(
        transaction: transaction,
        userId: 'user_1',
        walletId: 'wallet_1',
      ));

      expect(ok, isFalse);
    });

    test('dinleyicileri uyarır (listeler tazelenir)', () async {
      when(() => addTransaction(any()))
          .thenAnswer((_) async => const Right('tx_1'));

      final changes = <TransactionsChange>[];
      final sub = notifier.stream.listen(changes.add);

      await service.restore(TransactionDeletionUndo(
        transaction: transaction,
        userId: 'user_1',
        walletId: 'wallet_1',
      ));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(changes, hasLength(1));
      expect(changes.single.walletId, 'wallet_1');
      expect(changes.single.userId, 'user_1');
    });

    test('işlem geri almada kayda özgü metrik senkronu YOK', () async {
      when(() => addTransaction(any()))
          .thenAnswer((_) async => const Right('tx_1'));

      await service.restore(TransactionDeletionUndo(
        transaction: transaction,
        userId: 'user_1',
        walletId: 'wallet_1',
      ));

      verifyNever(() => metrics.syncDebt(any()));
      verifyNever(() => metrics.syncCredit(any()));
      verifyNever(() => metrics.syncInvestment(any()));
    });
  });

  group('restore — ters kayıtlar', () {
    test('borçta ters kayıtların TAMAMI silinir, sonra borç geri yazılır',
        () async {
      when(() => addDebt(any())).thenAnswer((_) async => const Right(null));

      final ok = await service.restore(DebtDeletionUndo(
        debt: debt,
        userId: 'user_1',
        walletId: 'wallet_1',
        reversalTransactionIds: const ['rev_1', 'rev_2'],
      ));

      expect(ok, isTrue);
      // Ters kayıt kalırsa nakit etkisi iki kez sayılır.
      verify(() => transactionsRepository.deleteTransaction('rev_1')).called(1);
      verify(() => transactionsRepository.deleteTransaction('rev_2')).called(1);
      final restored =
          verify(() => addDebt(captureAny())).captured.single as DebtEntity;
      expect(restored.id, 'debt_1');
      // Ödeme geçmişi de geri gelmeli.
      expect(restored.payments, hasLength(1));
      expect(restored.payments.single.amount, 900);
      verify(() => metrics.syncDebt('wallet_1')).called(1);
    });

    test('ters kayıt silinemezse false döner ama kayıt yine geri yazılır',
        () async {
      when(() => addDebt(any())).thenAnswer((_) async => const Right(null));
      when(() => transactionsRepository.deleteTransaction('rev_1'))
          .thenAnswer((_) async => const Left(CacheFailure('silinemedi')));

      final ok = await service.restore(DebtDeletionUndo(
        debt: debt,
        userId: 'user_1',
        walletId: 'wallet_1',
        reversalTransactionIds: const ['rev_1'],
      ));

      // Kısmi başarı sessiz kalmamalı; kayıt geri gelir, çağıran uyarır.
      expect(ok, isFalse);
      verify(() => addDebt(any())).called(1);
    });

    test('alacak geri alınır ve credit metriği senkronlanır', () async {
      when(() => addReceivable(any()))
          .thenAnswer((_) async => const Right(null));

      final ok = await service.restore(ReceivableDeletionUndo(
        receivable: receivable,
        userId: 'user_1',
        walletId: 'wallet_1',
        reversalTransactionIds: const ['rev_9'],
      ));

      expect(ok, isTrue);
      verify(() => transactionsRepository.deleteTransaction('rev_9')).called(1);
      final restored = verify(() => addReceivable(captureAny())).captured.single
          as ReceivableEntity;
      expect(restored, receivable);
      verify(() => metrics.syncCredit('wallet_1')).called(1);
    });

    test('yatırım geri alınır ve investment metriği senkronlanır', () async {
      when(() => addInvestment(any()))
          .thenAnswer((_) async => const Right(null));

      final ok = await service.restore(InvestmentDeletionUndo(
        investment: investment,
        userId: 'user_1',
        walletId: 'wallet_1',
        reversalTransactionIds: const ['rev_5'],
      ));

      expect(ok, isTrue);
      verify(() => transactionsRepository.deleteTransaction('rev_5')).called(1);
      final restored = verify(() => addInvestment(captureAny())).captured.single
          as InvestmentEntity;
      expect(restored, investment);
      verify(() => metrics.syncInvestment('wallet_1')).called(1);
    });

    test('metrik senkronu fırlatsa bile restore çökmez', () async {
      when(() => addInvestment(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => metrics.syncInvestment(any()))
          .thenThrow(Exception('metrik patladı'));

      final ok = await service.restore(InvestmentDeletionUndo(
        investment: investment,
        userId: 'user_1',
        walletId: 'wallet_1',
        reversalTransactionIds: const [],
      ));

      // Kayıt geri geldi; metrik bir sonraki senkronda düzelir.
      expect(ok, isTrue);
    });
  });

  group('commit — geri alınamaz yan etkiler', () {
    test('fiş dosyası pencere kapanınca silinir', () async {
      when(() => receipts.delete(any())).thenAnswer((_) async {});

      await service.commit(TransactionDeletionUndo(
        transaction: transaction.copyWith(receiptFileName: 'fis_1.jpg'),
        userId: 'user_1',
        walletId: 'wallet_1',
      ));

      verify(() => receipts.delete('fis_1.jpg')).called(1);
    });

    test('fişi olmayan işlemde dosya silme denenmez', () async {
      await service.commit(TransactionDeletionUndo(
        transaction: transaction,
        userId: 'user_1',
        walletId: 'wallet_1',
      ));

      verifyNever(() => receipts.delete(any()));
    });

    test('geri alınırsa fiş dosyasına DOKUNULMAZ', () async {
      when(() => addTransaction(any()))
          .thenAnswer((_) async => const Right('tx_1'));

      // Geri alma yolunda commit hiç çağrılmaz; asıl güvence budur.
      await service.restore(TransactionDeletionUndo(
        transaction: transaction.copyWith(receiptFileName: 'fis_1.jpg'),
        userId: 'user_1',
        walletId: 'wallet_1',
      ));

      verifyNever(() => receipts.delete(any()));
    });

    test('dosya silme hatası fırlatmaz', () async {
      when(() => receipts.delete(any())).thenThrow(Exception('disk hatası'));

      await expectLater(
        service.commit(TransactionDeletionUndo(
          transaction: transaction.copyWith(receiptFileName: 'fis_1.jpg'),
          userId: 'user_1',
          walletId: 'wallet_1',
        )),
        completes,
      );
    });

    test('işlem dışı kayıtlarda commit no-op', () async {
      await service.commit(DebtDeletionUndo(
        debt: debt,
        userId: 'user_1',
        walletId: 'wallet_1',
        reversalTransactionIds: const ['rev_1'],
      ));

      verifyNever(() => receipts.delete(any()));
      // Ters kayıtlar silme sırasında YAZILDI; commit onlara dokunmamalı.
      verifyNever(() => transactionsRepository.deleteTransaction(any()));
    });
  });
}
