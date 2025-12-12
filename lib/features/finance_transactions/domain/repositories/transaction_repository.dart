// lib/features/transaction/data/datasources/transaction_datasource.dart
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Base interface for transaction data sources
abstract class TransactionsRepository {
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
  });

  Future<Map<DateTime, List<TransactionEntity>>> getTransactionsGroupedByDate({
    required String userId,
    required String walletId,
    TransactionTypeModel? type,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<TransactionEntity> getTransactionById(String id);
  Future<String> addTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
}
