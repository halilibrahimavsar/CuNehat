part of 'investment_bloc.dart';

sealed class InvestmentEvent extends Equatable {
  const InvestmentEvent();

  @override
  List<Object> get props => [];
}

final class GetInvestmentsEvent extends InvestmentEvent {}

final class CreateInvestmentEvent extends InvestmentEvent {
  final String userId;
  final InvestmentEntity investment;

  const CreateInvestmentEvent(this.investment, this.userId);
  @override
  List<Object> get props => [investment];
}

final class UpdateInvestmentEvent extends InvestmentEvent {
  final InvestmentEntity investment;

  const UpdateInvestmentEvent(this.investment);
  @override
  List<Object> get props => [investment];
}

final class DeleteInvestmentEvent extends InvestmentEvent {
  final String id;

  const DeleteInvestmentEvent(this.id);
  @override
  List<Object> get props => [id];
}
