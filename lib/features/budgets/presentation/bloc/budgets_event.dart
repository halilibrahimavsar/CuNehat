import 'package:equatable/equatable.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';


abstract class BudgetsEvent extends Equatable {
  const BudgetsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgetsEvent extends BudgetsEvent {}

class SaveBudgetEvent extends BudgetsEvent {
  final BudgetEntity budget;

  const SaveBudgetEvent(this.budget);

  @override
  List<Object?> get props => [budget];
}

class DeleteBudgetEvent extends BudgetsEvent {
  final String categoryId;

  const DeleteBudgetEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}
