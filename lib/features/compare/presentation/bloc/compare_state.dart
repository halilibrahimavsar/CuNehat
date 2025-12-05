// lib/features/compare/presentation/bloc/compare_state.dart

part of 'compare_bloc.dart';

sealed class CompareState extends Equatable {
  const CompareState();

  @override
  List<Object> get props => [];
}

/// Initial state
final class CompareInitialSt extends CompareState {
  const CompareInitialSt();
}

/// Loading state
final class CompareLoadingSt extends CompareState {
  const CompareLoadingSt();
}

/// Data loaded successfully
final class CompareLoadedSt extends CompareState {
  final List<CombinedTransaction> transactions;

  const CompareLoadedSt(this.transactions);

  @override
  List<Object> get props => [transactions];
}

/// No data found
final class CompareEmptySt extends CompareState {
  const CompareEmptySt();
}

/// Error occurred
final class CompareErrorSt extends CompareState {
  final String error;

  const CompareErrorSt(this.error);

  @override
  List<Object> get props => [error];
}
