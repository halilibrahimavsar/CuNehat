part of 'investment_bloc.dart';

sealed class InvestmentEvent extends Equatable {
  const InvestmentEvent();

  @override
  List<Object> get props => [];
}

final class GetInvestmentsEvent extends InvestmentEvent {
  final String userId;
  final String walletId;

  const GetInvestmentsEvent({
    required this.userId,
    required this.walletId,
  });
  @override
  List<Object> get props => [userId, walletId];
}

final class CreateInvestmentEvent extends InvestmentEvent {
  final String userId;
  final String walletId;
  final InvestmentEntity investment;

  const CreateInvestmentEvent({
    required this.investment,
    required this.userId,
    required this.walletId,
  });
  @override
  List<Object> get props => [investment, userId, walletId];
}

final class UpdateInvestmentEvent extends InvestmentEvent {
  final String userId;
  final String walletId;
  final InvestmentEntity investment;
  final double prevAmount;
  final double newAmount;

  const UpdateInvestmentEvent({
    required this.investment,
    required this.userId,
    required this.walletId,
    required this.prevAmount,
    required this.newAmount,
  });
  @override
  List<Object> get props => [investment, userId, walletId];
}

final class DeleteInvestmentEvent extends InvestmentEvent {
  final String userId;
  final String walletId;
  final String id;
  final double amount;

  /// Silme = satış kabul edilir; güncel değer kadar nakit gelir oluşturulur.
  final double currentValue;

  const DeleteInvestmentEvent({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.amount,
    required this.currentValue,
  });
  @override
  List<Object> get props => [id, userId, walletId];
}
