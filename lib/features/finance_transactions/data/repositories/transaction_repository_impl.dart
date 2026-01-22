import 'package:cunehat/features/finance_transactions/data/datasources/transaction_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TransactionsRepository)
class TransactionRepositoryImpl implements TransactionsRepository {
  final TransactionHiveDataSource dataSource;

  TransactionRepositoryImpl({required this.dataSource});

  @override
  Future<String> addTransaction(TransactionEntity transaction) {
    final model = TransactionModel.fromEntity(transaction);
    return dataSource.addTransaction(model);
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) {
    final model = TransactionModel.fromEntity(transaction);
    return dataSource.updateTransaction(model);
  }

  @override
  Future<void> deleteTransaction(String id) {
    return dataSource.deleteTransaction(id);
  }

  @override
  Future<TransactionEntity> getTransactionById(String id) async {
    final model = await dataSource.getTransactionById(id);
    return model.toEntity();
  }

  @override
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
  }) async {
    final models = await dataSource.getTransactions(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );

    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Map<DateTime, List<TransactionEntity>>> getTransactionsGroupedByDate({
    required String userId,
    required String walletId,
    TransactionTypeModel? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final modelMap = await dataSource.getTransactionsGroupedByDate(
      userId: userId,
      walletId: walletId,
      type: type,
      startDate: startDate,
      endDate: endDate,
    );

    return modelMap.map(
      (key, value) => MapEntry(
        key,
        value.map((e) => e.toEntity()).toList(),
      ),
    );
  }
}
