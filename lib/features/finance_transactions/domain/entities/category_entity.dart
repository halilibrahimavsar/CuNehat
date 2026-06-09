import 'package:equatable/equatable.dart';

/// İşlem kategorisi. `id` aynı zamanda görünen addır (mevcut veri modeliyle
/// birebir; kategoriler SharedPreferences'ta isimle saklanır).
class CategoryEntity extends Equatable {
  final String id;
  final String iconName;
  final bool isExpense;

  /// Sistem kategorisi (silinemez).
  final bool isDefault;
  final int sortOrder;

  const CategoryEntity({
    required this.id,
    required this.iconName,
    required this.isExpense,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  CategoryEntity copyWith({
    String? id,
    String? iconName,
    bool? isExpense,
    bool? isDefault,
    int? sortOrder,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      iconName: iconName ?? this.iconName,
      isExpense: isExpense ?? this.isExpense,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [id, iconName, isExpense, isDefault, sortOrder];
}
