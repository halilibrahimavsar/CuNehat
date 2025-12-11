// lib/features/wallet/domain/usecases/wallet_balance_sync_usecase.dart

import 'package:cunehat/features/finance_transections/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';

/// ========== WALLET BALANCE SYNC USE CASE ==========
///
/// ✅ FIXED: Recalculates balance from ALL transactions (not incremental)
class WalletBalanceSyncUseCase {
  final WalletRepository walletRepository;
  final TransactionsRepository transactionDataSource;

  WalletBalanceSyncUseCase({
    required this.walletRepository,
    required this.transactionDataSource,
  });

  /// ✅ MAIN METHOD: Recalculate wallet balance from scratch
  ///
  /// This method:
  /// 1. Gets ALL transactions for this wallet
  /// 2. Sorts them by date (oldest first)
  /// 3. Calculates balance step-by-step
  /// 4. Updates wallet with final balance
  Future<void> recalculateBalance({
    required String userId,
    required String walletId,
  }) async {
    try {
      // 1. Get ALL transactions for this wallet (no date filter)
      final transactions = await transactionDataSource.getTransactions(
        userId: userId,
        walletId: walletId,
      );

      // 2. Sort by date (oldest first)
      transactions.sort((a, b) => a.date.compareTo(b.date));

      // 3. Calculate balance from scratch
      double balance = 0.0;

      for (var transaction in transactions) {
        if (transaction.type == TransactionTypeModel.income) {
          balance += transaction.amount;
        } else {
          balance -= transaction.amount;
        }
      }

      // 4. Get current wallet
      final wallets = await walletRepository.getWallets(userId);
      final wallet = wallets.firstWhere((w) => w.id == walletId);

      // 5. Update wallet with new balance
      final updatedWallet = wallet.copyWith(balance: balance);
      await walletRepository.updateWallet(updatedWallet);

      print('✅ Balance recalculated for wallet $walletId: $balance₺');
    } catch (e) {
      print('❌ Error recalculating balance: $e');
      rethrow;
    }
  }

  /// ✅ SIMPLIFIED: Apply single transaction (calls recalculate)
  ///
  /// [walletId] - Wallet to update
  /// [transaction] - Transaction to apply
  /// [isReversal] - NOT USED (we recalculate everything anyway)
  Future<void> applyTransaction({
    required String walletId,
    required TransactionEntity transaction,
    bool isReversal = false, // Kept for API compatibility
  }) async {
    // Just recalculate everything - simpler and always correct
    await recalculateBalance(
      userId: transaction.userId,
      walletId: walletId,
    );
  }

  /// ✅ SIMPLIFIED: Update transaction (calls recalculate)
  ///
  /// [walletId] - Wallet to update
  /// [oldTransaction] - NOT USED (we recalculate)
  /// [newTransaction] - NOT USED (we recalculate)
  Future<void> updateTransaction({
    required String walletId,
    required TransactionEntity oldTransaction,
    required TransactionEntity newTransaction,
  }) async {
    // Just recalculate everything - simpler and always correct
    await recalculateBalance(
      userId: oldTransaction.userId,
      walletId: walletId,
    );
  }

  /// ⚠️ DEPRECATED: Use recalculateBalance instead
  ///
  /// This method is kept for backward compatibility
  // Future<void> call({
  //   required String walletId,
  //   required List<TransactionEntity> transactions,
  //   double initialBalance = 0.0,
  // }) async {
  //   if (transactions.isEmpty) return;

  //   await recalculateBalance(
  //     userId: transactions.first.userId,
  //     walletId: walletId,
  //   );
  // }
}
