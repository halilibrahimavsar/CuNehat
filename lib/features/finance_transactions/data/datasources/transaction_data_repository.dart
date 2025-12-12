import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';

abstract class TransactionDataRepository {
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
  });
  Future<Map<DateTime, List<TransactionModel>>> getTransactionsGroupedByDate(
      {required String userId,
      required String walletId,
      TransactionTypeModel? type,
      DateTime? startDate,
      DateTime? endDate});

  Future<TransactionModel> getTransactionById(String id);
  Future<String> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}
