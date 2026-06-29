import 'package:hive/hive.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';

part 'budget_model.g.dart';

// typeId 10 DebtTypeAdapter tarafından kullanılıyor; çakışırsa adapter hiç
// kaydedilmez ve her budget yazımı "unknown type" ile düşer.
@HiveType(typeId: 12)
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

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'limitAmount': limitAmount,
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      categoryId: json['categoryId'] as String? ?? '',
      limitAmount: (json['limitAmount'] as num? ?? 0).toDouble(),
    );
  }
}
