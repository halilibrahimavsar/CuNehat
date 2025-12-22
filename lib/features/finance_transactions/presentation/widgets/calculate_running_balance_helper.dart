import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

class TransactionWithBalance {
  final TransactionEntity transaction;
  final double balanceAfter;

  TransactionWithBalance({
    required this.transaction,
    required this.balanceAfter,
  });
}

List<TransactionWithBalance> calculateRunningBalance(
  List<TransactionEntity> transactions,
  double finalBalance,
) {
  final result = <TransactionWithBalance>[];
  double runningBalance = finalBalance;

  // ✅ Work backwards from final balance
  for (var i = 0; i < transactions.length; i++) {
    final transaction = transactions[i];

    result.add(TransactionWithBalance(
      transaction: transaction,
      balanceAfter: runningBalance,
    ));

    // Calculate balance BEFORE this transaction
    if (transaction.isIncome) {
      runningBalance -= transaction.amount;
    } else {
      runningBalance += transaction.amount;
    }
  }

  return result;
}
