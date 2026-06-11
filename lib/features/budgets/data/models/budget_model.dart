import 'package:hive/hive.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 10)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String categoryId;

  @HiveField(1)
  final double limitAmount;

  BudgetModel({
    required this.categoryId,
    required this.limitAmount,
  });

  /// Domain Entity'den Model'e dönüştürür.
  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      categoryId: entity.categoryId,
      limitAmount: entity.limitAmount,
    );
  }

  /// Model'den Domain Entity'ye dönüştürür.
  BudgetEntity toEntity() {
    return BudgetEntity(
      categoryId: categoryId,
      limitAmount: limitAmount,
    );
  }
}
