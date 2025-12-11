// lib/features/transaction/data/datasources/transaction_datasource.dart
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';

import '../../data/models/transaction_model.dart';

/// Base interface for transaction data sources
abstract class TransactionsRepository {
  Future<List<TransactionModel>> getTransactions({
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
  Future<TransactionModel> getTransactionById(String id);
  Future<String> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}
