// lib/features/compare/data/repositories/compare_repository_impl.dart

import 'package:cunehat/features/compare/domain/models/combine_model.dart';
import 'package:cunehat/features/compare/domain/repository/compare_repository.dart';

/// **Compare Repository Implementation**
///
/// Uses polymorphism to switch between Hive and Firestore datasources
class CompareRepositoryImpl implements CompareRepository {
  final CompareRepository dataSource;

  CompareRepositoryImpl({required this.dataSource});

  @override
  Stream<List<CombinedTransaction>> getTransactions({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return dataSource.getTransactions(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Stream<List<CombinedTransaction>> getExpenses({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return dataSource.getExpenses(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Stream<List<CombinedTransaction>> getIncomes({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return dataSource.getIncomes(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
