import 'package:cunehat/features/finance_transactions/data/datasources/transaction_data_repository.dart';
import 'package:cunehat/features/wallet/data/repository/wallet_data_repository.dart';

/// ========== WALLET BALANCE SYNC USE CASE ==========
class WalletBalanceSyncUseCase {
  final WalletDataRepository walletRepository;
  final TransactionDataRepository transactionRepository;

  WalletBalanceSyncUseCase({
    required this.walletRepository,
    required this.transactionRepository,
  });

  Future<void> addBalance({
    required String userId,
    required bool isExpense,
    required double amount,
  }) async {
    double currentBalance = await _getActiveBalance(userId);
    if (isExpense) {
      currentBalance -= amount;
    } else {
      currentBalance += amount;
    }
    await walletRepository.updateBalance(userId, currentBalance);
  }

  Future<void> updateBalance({
    required String userId,
    required bool isExpense,
    required double prevAmount,
    required double newAmount,
  }) async {
    double currentBalance = await _getActiveBalance(userId);
    // in here we should also calculate the amount before update

    if (isExpense) {
      currentBalance += prevAmount;
      currentBalance -= newAmount;
    } else {
      currentBalance -= prevAmount;
      currentBalance += newAmount;
    }

    await walletRepository.updateBalance(userId, currentBalance);
  }

  Future<void> deleteBalance({
    required String userId,
    required double amount,
    required bool isExpense,
  }) async {
    double currentBalance = await _getActiveBalance(userId);

    if (isExpense) {
      currentBalance += amount;
    } else {
      currentBalance -= amount;
    }

    await walletRepository.updateBalance(userId, currentBalance);
  }

  Future<double> _getActiveBalance(String userId) async {
    final activeWallet = await walletRepository.getActiveWallet(userId);
    double currentBalance = 0.0;

    if (activeWallet == null) {
      return currentBalance;
    }
    return activeWallet.balance;
  }
}
