import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transections/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionsRepository {
  final TransactionsRepository dataSource;

  TransactionRepositoryImpl({required this.dataSource});

  @override
  Future<String> addTransaction(TransactionEntity transaction) {
    return dataSource.addTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) {
    return dataSource.deleteTransaction(id);
  }

  @override
  Future<TransactionEntity> getTransactionById(String id) {
    return dataSource.getTransactionById(id);
  }

  @override
  Future<List<TransactionEntity>> getTransactions(
      {required String userId,
      required String walletId,
      DateTime? startDate,
      DateTime? endDate,
      TransactionTypeModel? type}) {
    return dataSource.getTransactions(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
  }

  @override
  Future<Map<DateTime, List<TransactionEntity>>> getTransactionsGroupedByDate(
      {required String userId,
      required String walletId,
      TransactionTypeModel? type,
      DateTime? startDate,
      DateTime? endDate}) {
    return dataSource.getTransactionsGroupedByDate(
      userId: userId,
      walletId: walletId,
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) {
    return dataSource.updateTransaction(transaction);
  }
}
