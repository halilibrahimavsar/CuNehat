import 'package:equatable/equatable.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';

abstract class BudgetsEvent extends Equatable {
  const BudgetsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgetsEvent extends BudgetsEvent {
  final String userId;
  final String walletId;

  const LoadBudgetsEvent({required this.userId, required this.walletId});

  @override
  List<Object?> get props => [userId, walletId];
}

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

/// Tek seferlik bütçe ekler ya da günceller. `walletId` boşsa bloc aktif
/// cüzdanı damgalar (aylık bütçeyle aynı kural).
class SaveTempBudgetEvent extends BudgetsEvent {
  final TempBudgetEntity budget;

  const SaveTempBudgetEvent(this.budget);

  @override
  List<Object?> get props => [budget];
}

class DeleteTempBudgetEvent extends BudgetsEvent {
  final String id;

  const DeleteTempBudgetEvent(this.id);

  @override
  List<Object?> get props => [id];
}
