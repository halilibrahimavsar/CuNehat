// // lib/features/compare/presentation/bloc/compare_event.dart

// part of 'compare_bloc.dart';

// sealed class CompareEvent extends Equatable {
//   const CompareEvent();

//   @override
//   List<Object> get props => [];
// }

// /// Get all transactions (incomes + expenses)
// final class GetTransactionsCompareEvent extends CompareEvent {
//   final String userId;
//   final String walletId;
//   final DateTime startDate;
//   final DateTime endDate;

//   const GetTransactionsCompareEvent({
//     required this.userId,
//     required this.walletId,
//     required this.startDate,
//     required this.endDate,
//   });

//   @override
//   List<Object> get props => [userId, walletId, startDate, endDate];
// }

// /// Get only expenses
// final class GetExpensesOnlyEvent extends CompareEvent {
//   final String userId;
//   final String walletId;
//   final DateTime startDate;
//   final DateTime endDate;

//   const GetExpensesOnlyEvent({
//     required this.userId,
//     required this.walletId,
//     required this.startDate,
//     required this.endDate,
//   });

//   @override
//   List<Object> get props => [userId, walletId, startDate, endDate];
// }

// /// Get only incomes
// final class GetIncomesOnlyEvent extends CompareEvent {
//   final String userId;
//   final String walletId;
//   final DateTime startDate;
//   final DateTime endDate;

//   const GetIncomesOnlyEvent({
//     required this.userId,
//     required this.walletId,
//     required this.startDate,
//     required this.endDate,
//   });

//   @override
//   List<Object> get props => [userId, walletId, startDate, endDate];
// }

// // ========== INTERNAL EVENTS (for stream handling) ==========

// final class _EmitLoadedEvent extends CompareEvent {
//   final List<CombinedTransaction> transactions;

//   const _EmitLoadedEvent(this.transactions);

//   @override
//   List<Object> get props => [transactions];
// }

// final class _EmitEmptyEvent extends CompareEvent {
//   const _EmitEmptyEvent();
// }

// final class _EmitErrorEvent extends CompareEvent {
//   final String error;

//   const _EmitErrorEvent(this.error);

//   @override
//   List<Object> get props => [error];
// }
