part of 'investment_bloc.dart';

sealed class InvestmentState extends Equatable {
  const InvestmentState();

  @override
  List<Object?> get props => [];
}

final class InvestmentInitial extends InvestmentState {}

final class InvestmentLoading extends InvestmentState {}

final class InvestmentLoaded extends InvestmentState {
  final List<InvestmentEntity> investments;
  final double totalAmount;

  const InvestmentLoaded(this.investments, {this.totalAmount = 0.0});

  /// Portföy özet metrikleri — UI build içinde hesap yapmasın diye state'te.
  double get totalCurrentValue =>
      investments.fold(0.0, (sum, item) => sum + item.currentValue);

  double get totalProfit => totalCurrentValue - totalAmount;

  double get totalProfitPercentage =>
      totalAmount > 0 ? (totalProfit / totalAmount) * 100 : 0.0;

  @override
  List<Object> get props => [investments, totalAmount];
}

final class InvestmentError extends InvestmentState {
  final String message;

  const InvestmentError(this.message);

  @override
  List<Object> get props => [message];
}

final class InvestmentActionSuccess extends InvestmentState {
  final String message;

  /// Yalnız silmede dolu: UI bunu "Geri al" eylemine bağlar. Satışta da
  /// dolu — satış da kaydı defterden kaldırıp gelir yazar, geri alınabilir.
  final DeletionUndo? undo;

  const InvestmentActionSuccess(this.message, {this.undo});

  @override
  List<Object?> get props => [message, undo];
}
