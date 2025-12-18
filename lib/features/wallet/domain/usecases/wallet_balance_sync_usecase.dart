// lib/features/wallet/domain/usecases/wallet_balance_sync_usecase.dart

import 'package:cunehat/features/finance_transactions/data/datasources/transaction_data_repository.dart';
import 'package:cunehat/features/wallet/data/datasource/wallet_data_repository.dart';

/// ========== WALLET BALANCE SYNC USE CASE ==========
class WalletBalanceSyncUseCase {
  final WalletDataRepository walletRepository;
  final TransactionDataRepository transactionDataSource;

  WalletBalanceSyncUseCase({
    required this.walletRepository,
    required this.transactionDataSource,
  });

  Future<void> updateBalance(
      String userId, bool isExpense, double amount) async {
    final activeWallet = await walletRepository.getActiveWallet(userId);
    double currentBalance = 0.0;

    if (activeWallet == null) {
      return;
    } else {
      currentBalance = activeWallet.balance;
    }

    if (isExpense) {
      currentBalance -= amount;
    } else {
      currentBalance += amount;
    }
    print(currentBalance);
    await walletRepository.updateBalance(userId, currentBalance);
  }
}
