import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/receivable_repository.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';
import 'package:injectable/injectable.dart';

/// Kuplaj ile otomatik oluşturulan nakit işlemlerinin sabit etiketleri (tag).
class CashMovementTags {
  static const String debt = 'Borç';
  static const String debtPayment = 'Borç Ödemesi';
  static const String receivable = 'Alacak';
  static const String receivableCollection = 'Alacak Tahsilatı';
  static const String investmentBuy = 'Yatırım Alımı';
  static const String investmentSell = 'Yatırım Satışı';
}

@lazySingleton
class WalletMetricsService {
  final WalletRepository walletRepository;
  final DebtRepository debtRepository;
  final ReceivableRepository receivableRepository;
  final InvestmentRepository investmentRepository;
  final TransactionsRepository transactionsRepository;

  WalletMetricsService({
    required this.walletRepository,
    required this.debtRepository,
    required this.receivableRepository,
    required this.investmentRepository,
    required this.transactionsRepository,
  });

  Future<void> applyBalanceDelta({
    required String walletId,
    required double delta,
  }) async {
    if (delta == 0) return;
    final wallet = await walletRepository.getWalletById(walletId);
    if (wallet == null) return;

    final updated = wallet.copyWith(balance: wallet.balance + delta);
    await walletRepository.updateWallet(updated);
  }

  /// Nakit kuplajı: gerçek bir işlem (transaction) kaydeder VE cüzdan
  /// bakiyesini günceller. Borç/yatırım/alacak operasyonları bunu çağırır ki
  /// nakit hareketleri işlem geçmişinde görünür ve `balance` ile tutarlı kalsın.
  Future<void> recordCashMovement({
    required String walletId,
    required String userId,
    required double amount,
    required bool isIncome,
    required String title,
    required String tag,
    DateTime? date,
  }) async {
    final tx = TransactionEntity(
      id: UidGenerator.generateV7(),
      userId: userId,
      walletId: walletId,
      title: title,
      tag: tag,
      amount: amount,
      date: date ?? DateTime.now(),
      type:
          isIncome ? TransactionTypeModel.income : TransactionTypeModel.expense,
    );
    await transactionsRepository.addTransaction(tx);
    await applyBalanceDelta(
      walletId: walletId,
      delta: isIncome ? amount : -amount,
    );
  }

  /// Bakiyeyi işlemlerden yeniden hesaplar (drift onarımı).
  /// `balance = openingBalance + Σ signed(tüm işlemler)`.
  /// Eski cüzdanlarda `openingBalance` null ise mevcut bakiyeyi koruyacak
  /// şekilde (balance - Σtx) geri doldurulur.
  Future<void> syncBalance(String walletId) async {
    final wallet = await walletRepository.getWalletById(walletId);
    if (wallet == null) return;

    final txs = await transactionsRepository.getTransactions(
      userId: wallet.userId,
      walletId: walletId,
    );
    final txSum = txs.fold<double>(
      0.0,
      (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
    );

    final opening = wallet.openingBalance ?? (wallet.balance - txSum);
    final newBalance = opening + txSum;

    // Tutarlıysa hiç yazma (yaygın durum; gereksiz emit/yazma döngüsünü önler).
    if (wallet.openingBalance != null && wallet.balance == newBalance) return;

    // Eşzamanlı metrik güncellemelerini (debt/credit/investment) ezmemek için
    // yazmadan hemen önce güncel cüzdanı tekrar oku ve yalnız bakiye alanlarını
    // taze kayda uygula.
    final fresh = await walletRepository.getWalletById(walletId) ?? wallet;
    await walletRepository.updateWallet(
      fresh.copyWith(openingBalance: opening, balance: newBalance),
    );
  }

  Future<void> syncDebt(String walletId) async {
    final wallet = await walletRepository.getWalletById(walletId);
    if (wallet == null) return;

    final debts = await debtRepository.getDebtsByWalletId(walletId);
    final totalDebt = debts
        .where((debt) => !debt.isPaid)
        .fold<double>(0.0, (sum, debt) => sum + debt.remainingAmount);

    if (wallet.debt != totalDebt) {
      await walletRepository.updateWallet(wallet.copyWith(debt: totalDebt));
    }
  }

  Future<void> syncCredit(String walletId) async {
    final wallet = await walletRepository.getWalletById(walletId);
    if (wallet == null) return;

    final receivables =
        await receivableRepository.getReceivablesByWalletId(walletId);
    final totalCredit = receivables
        .where((r) => !r.isPaid)
        .fold<double>(0.0, (sum, r) => sum + r.amount);

    if (wallet.credit != totalCredit) {
      await walletRepository.updateWallet(wallet.copyWith(credit: totalCredit));
    }
  }

  Future<void> syncInvestment(String walletId) async {
    final wallet = await walletRepository.getWalletById(walletId);
    if (wallet == null) return;

    final result = await investmentRepository.getInvestments(
      userId: wallet.userId,
      walletId: walletId,
    );

    final totalInvestment = result.fold(
      (failure) => 0.0,
      (investments) => investments.fold<double>(
        0.0,
        (sum, item) => sum + item.currentValue,
      ),
    );

    if (wallet.investment != totalInvestment) {
      await walletRepository
          .updateWallet(wallet.copyWith(investment: totalInvestment));
    }
  }

  /// Cüzdan silinirken o cüzdana bağlı tüm kayıtları (işlem/borç/alacak/yatırım)
  /// temizler; yetim veri kalmasını önler.
  Future<void> purgeWalletData(String walletId, String userId) async {
    final txs = await transactionsRepository.getTransactions(
      userId: userId,
      walletId: walletId,
    );
    for (final t in txs) {
      if (t.id != null) await transactionsRepository.deleteTransaction(t.id!);
    }

    final debts = await debtRepository.getDebtsByWalletId(walletId);
    for (final d in debts) {
      if (d.id != null) await debtRepository.deleteDebt(d.id!);
    }

    final receivables =
        await receivableRepository.getReceivablesByWalletId(walletId);
    for (final r in receivables) {
      if (r.id != null) await receivableRepository.deleteReceivable(r.id!);
    }

    final invResult = await investmentRepository.getInvestments(
      userId: userId,
      walletId: walletId,
    );
    await invResult.fold(
      (failure) async {},
      (investments) async {
        for (final inv in investments) {
          if (inv.id != null) {
            await investmentRepository.deleteInvestment(inv.id!);
          }
        }
      },
    );
  }
}
