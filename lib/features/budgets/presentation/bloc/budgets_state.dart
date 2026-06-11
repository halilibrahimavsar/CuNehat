import 'package:equatable/equatable.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/core/error/failure.dart';

abstract class BudgetsState extends Equatable {
  const BudgetsState();

  @override
  List<Object?> get props => [];
}

class BudgetsInitial extends BudgetsState {}

class BudgetsLoading extends BudgetsState {}

class BudgetsLoaded extends BudgetsState {
  final List<BudgetEntity> budgets;

  const BudgetsLoaded(this.budgets);

  @override
  List<Object?> get props => [budgets];
}

class BudgetsError extends BudgetsState {
  final Failure failure;

  const BudgetsError(this.failure);

  @override
  List<Object?> get props => [failure];
}
