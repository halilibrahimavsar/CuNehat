// // lib/features/compare/domain/repositories/compare_repository.dart

// import 'package:cunehat/features/compare/domain/models/combine_model.dart';

// /// **Compare Repository Interface**
// ///
// /// Provides methods to fetch income and expense data for comparison
// abstract class CompareRepository {
//   /// Get all transactions (incomes + expenses) for a specific wallet
//   ///
//   /// Returns a stream of [CombinedTransaction] list
//   Stream<List<CombinedTransaction>> getTransactions({
//     required String userId,
//     required String walletId,
//     required DateTime startDate,
//     required DateTime endDate,
//   });

//   /// Get only expenses for a specific wallet and date range
//   Stream<List<CombinedTransaction>> getExpenses({
//     required String userId,
//     required String walletId,
//     required DateTime startDate,
//     required DateTime endDate,
//   });

//   /// Get only incomes for a specific wallet and date range
//   Stream<List<CombinedTransaction>> getIncomes({
//     required String userId,
//     required String walletId,
//     required DateTime startDate,
//     required DateTime endDate,
//   });
// }
