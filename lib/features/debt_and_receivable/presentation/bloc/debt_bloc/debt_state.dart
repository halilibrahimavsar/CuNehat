part of 'debt_bloc.dart';

sealed class DebtState extends Equatable {
  const DebtState();

  @override
  List<Object> get props => [];
}

final class DebtInitial extends DebtState {}
