// lib/features/transaction/data/datasources/transaction_datasource.dart
import '../models/transaction_model.dart';
import '../../domain/entities/transaction_entity.dart';

/// Base interface for transaction data sources
abstract class TransactionDataSource {
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
  });

  Future<TransactionModel> getTransactionById(String id);
  Future<String> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}
