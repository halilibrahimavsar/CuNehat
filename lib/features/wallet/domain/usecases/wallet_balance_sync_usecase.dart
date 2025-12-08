// lib/features/wallet/domain/usecases/wallet_balance_sync_usecase.dart

import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';

/// ========== WALLET BALANCE SYNC USE CASE ==========
///
/// Calculates wallet balance from transactions and updates wallet
class WalletBalanceSyncUseCase {
  final WalletRepository repository;

  WalletBalanceSyncUseCase(this.repository);

  /// Calculate and update wallet balance based on transactions
  ///
  /// [walletId] - Wallet to update
  /// [transactions] - All transactions for this wallet
  /// [initialBalance] - Starting balance (optional, defaults to 0)
  Future<void> call({
    required String walletId,
    required List<TransactionEntity> transactions,
    double initialBalance = 0.0,
  }) async {
    // Calculate total balance
    double balance = initialBalance;

    for (var transaction in transactions) {
      if (transaction.type == TransactionTypeModel.income) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }

    // Get current wallet
    final wallets =
        await repository.getWallets(transactions.first.userId).first;
    final wallet = wallets.firstWhere((w) => w.id == walletId);

    // Update wallet with new balance
    final updatedWallet = wallet.copyWith(balance: balance);
    await repository.updateWallet(updatedWallet);
  }

  /// Update wallet balance by adding/subtracting a single transaction
  ///
  /// [walletId] - Wallet to update
  /// [transaction] - Transaction to apply
  /// [isReversal] - If true, reverses the transaction (for deletion/update)
  Future<void> applyTransaction({
    required String walletId,
    required TransactionEntity transaction,
    bool isReversal = false,
  }) async {
    // Get current wallet
    final wallets = await repository.getWallets(transaction.userId).first;
    final wallet = wallets.firstWhere((w) => w.id == walletId);

    // Calculate new balance
    double newBalance = wallet.balance;

    if (transaction.type == TransactionTypeModel.income) {
      newBalance += isReversal ? -transaction.amount : transaction.amount;
    } else {
      newBalance -= isReversal ? -transaction.amount : transaction.amount;
    }

    // Update wallet
    final updatedWallet = wallet.copyWith(balance: newBalance);
    await repository.updateWallet(updatedWallet);
  }

  /// Update wallet when a transaction is modified
  ///
  /// [walletId] - Wallet to update
  /// [oldTransaction] - Original transaction
  /// [newTransaction] - Updated transaction
  Future<void> updateTransaction({
    required String walletId,
    required TransactionEntity oldTransaction,
    required TransactionEntity newTransaction,
  }) async {
    // Get current wallet
    final wallets = await repository.getWallets(oldTransaction.userId).first;
    final wallet = wallets.firstWhere((w) => w.id == walletId);

    // Reverse old transaction
    double balance = wallet.balance;

    if (oldTransaction.type == TransactionTypeModel.income) {
      balance -= oldTransaction.amount;
    } else {
      balance += oldTransaction.amount;
    }

    // Apply new transaction
    if (newTransaction.type == TransactionTypeModel.income) {
      balance += newTransaction.amount;
    } else {
      balance -= newTransaction.amount;
    }

    // Update wallet
    final updatedWallet = wallet.copyWith(balance: balance);
    await repository.updateWallet(updatedWallet);
  }
}
