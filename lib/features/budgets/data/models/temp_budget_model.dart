import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:hive/hive.dart';

part 'temp_budget_model.g.dart';

/// Tek seferlik bütçe kaydı. Kurallar [TempBudgetEntity]'de.
///
/// typeId 19, kutu `temp_budgets_box`, anahtar [id]. Dolu typeId'lerin ve
/// sıradaki `HiveField` numarasının tek kaydı **`CLAUDE.md`**.
/// `HiveObject`'ten TÜREMEZ (bkz. [CategoryModel] — aynı tercih).
@HiveType(typeId: 19)
class TempBudgetModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String walletId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final double limitAmount;

  @HiveField(4)
  final DateTime startDate;

  /// Aralığın son günü — DAHİL.
  @HiveField(5)
  final DateTime endDate;

  @HiveField(6)
  final List<String> categoryIds;

  const TempBudgetModel({
    required this.id,
    required this.walletId,
    required this.name,
    required this.limitAmount,
    required this.startDate,
    required this.endDate,
    required this.categoryIds,
  });

  factory TempBudgetModel.fromEntity(TempBudgetEntity e) => TempBudgetModel(
        id: e.id,
        walletId: e.walletId,
        name: e.name,
        limitAmount: e.limitAmount,
        startDate:
            DateTime(e.startDate.year, e.startDate.month, e.startDate.day),
        endDate: DateTime(e.endDate.year, e.endDate.month, e.endDate.day),
        categoryIds: List.unmodifiable(e.categoryIds),
      );

  TempBudgetEntity toEntity() => TempBudgetEntity(
        id: id,
        walletId: walletId,
        name: name,
        limitAmount: limitAmount,
        startDate: startDate,
        endDate: endDate,
        categoryIds: List.unmodifiable(categoryIds),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'walletId': walletId,
        'name': name,
        'limitAmount': limitAmount,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'categoryIds': categoryIds,
      };

  /// Sıkı cast: eksik ya da yanlış tipte alan gürültüyle düşer (bkz.
  /// `CLAUDE.md` → "sessiz yanlış yorumlama, gürültülü hatadan kötüdür").
  factory TempBudgetModel.fromJson(Map<String, dynamic> json) =>
      TempBudgetModel(
        id: json['id'] as String,
        walletId: json['walletId'] as String,
        name: json['name'] as String,
        limitAmount: (json['limitAmount'] as num).toDouble(),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        categoryIds: (json['categoryIds'] as List).cast<String>().toList(),
      );
}
