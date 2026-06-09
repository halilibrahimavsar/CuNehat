import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

class TransactionWithBalance {
  final TransactionEntity transaction;
  final double balanceAfter;

  TransactionWithBalance({
    required this.transaction,
    required this.balanceAfter,
  });
}

/// Cüzdanın TAM işlem geçmişinden defter görünümü üretir.
///
/// Sıra: tam listeyi sırala (tarih desc, eş tarihte UUIDv7 id desc) →
/// [currentBalance] çapasıyla running balance hesapla → gün hassasiyetli,
/// uçları dahil [start]..[end] penceresini uygula. Çapa tam geçmiş üzerinde
/// kurulduğu için `balanceAfter` her tarih aralığında doğru kalır.
List<TransactionWithBalance> buildLedgerView({
  required List<TransactionEntity> allTransactions,
  required double currentBalance,
  DateTime? start,
  DateTime? end,
}) {
  DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  final sorted = List<TransactionEntity>.from(allTransactions)
    ..sort((a, b) {
      final c = b.date.compareTo(a.date);
      if (c != 0) return c;
      return (b.id ?? '').compareTo(a.id ?? '');
    });

  final withBalance = calculateRunningBalance(sorted, currentBalance);

  return withBalance.where((e) {
    final day = dayOf(e.transaction.date);
    if (start != null && day.isBefore(dayOf(start))) return false;
    if (end != null && day.isAfter(dayOf(end))) return false;
    return true;
  }).toList();
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
