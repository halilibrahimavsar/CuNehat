part of 'investment_bloc.dart';

sealed class InvestmentState extends Equatable {
  const InvestmentState();

  @override
  List<Object> get props => [];
}

final class InvestmentInitial extends InvestmentState {}

final class InvestmentLoading extends InvestmentState {}

final class InvestmentLoaded extends InvestmentState {
  final List<InvestmentEntity> investments;
  final double totalAmount;

  const InvestmentLoaded(this.investments, {this.totalAmount = 0.0});

  @override
  List<Object> get props => [investments, totalAmount];
}

final class InvestmentError extends InvestmentState {
  final String message;

  const InvestmentError(this.message);

  @override
  List<Object> get props => [message];
}

final class InvestmentOperationSuccess extends InvestmentState {
  final String message;

  const InvestmentOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
