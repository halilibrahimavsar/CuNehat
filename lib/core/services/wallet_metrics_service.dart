import 'package:cunehat/features/debt_and_receivable/domain/repository/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/receivable_repository.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class WalletMetricsService {
  final WalletRepository walletRepository;
  final DebtRepository debtRepository;
  final ReceivableRepository receivableRepository;
  final SaveRepository investmentRepository;

  WalletMetricsService({
    required this.walletRepository,
    required this.debtRepository,
    required this.receivableRepository,
    required this.investmentRepository,
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

  Future<void> syncDebt(String walletId) async {
    final wallet = await walletRepository.getWalletById(walletId);
    if (wallet == null) return;

    final debts = await debtRepository.getDebtsByWalletId(walletId);
    final totalDebt =
        debts.fold<double>(0.0, (sum, debt) => sum + debt.remainingAmount);

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

    final investments = await investmentRepository.getInvestments(
      userId: wallet.userId,
      walletId: walletId,
    );
    final totalInvestment = investments.fold<double>(
      0.0,
      (sum, item) => sum + item.currentValue,
    );

    if (wallet.investment != totalInvestment) {
      await walletRepository
          .updateWallet(wallet.copyWith(investment: totalInvestment));
    }
  }
}
