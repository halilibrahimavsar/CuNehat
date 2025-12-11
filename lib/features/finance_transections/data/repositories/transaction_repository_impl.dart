import 'package:cunehat/features/finance_transections/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transections/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionsRepository {
  final TransactionsRepository dataSource;

  TransactionRepositoryImpl({required this.dataSource});

  @override
  Future<String> addTransaction(TransactionEntity transaction) {
    // TODO: implement addTransaction
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTransaction(String id) {
    // TODO: implement deleteTransaction
    throw UnimplementedError();
  }

  @override
  Future<TransactionModel> getTransactionById(String id) {
    // TODO: implement getTransactionById
    throw UnimplementedError();
  }

  @override
  Future<List<TransactionModel>> getTransactions(
      {required String userId,
      required String walletId,
      DateTime? startDate,
      DateTime? endDate,
      TransactionTypeModel? type}) {
    // TODO: implement getTransactions
    throw UnimplementedError();
  }

  @override
  Future<Map<DateTime, List<TransactionEntity>>> getTransactionsGroupedByDate(
      {required String userId,
      required String walletId,
      TransactionTypeModel? type,
      DateTime? startDate,
      DateTime? endDate}) {
    // TODO: implement getTransactionsGroupedByDate
    throw UnimplementedError();
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) {
    // TODO: implement updateTransaction
    throw UnimplementedError();
  }
}
