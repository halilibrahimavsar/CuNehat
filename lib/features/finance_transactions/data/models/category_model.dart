import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// Transaction Category Model
///
/// Represents a category for income or expense transactions
class CategoryModel {
  final String id;
  final String iconName;
  final bool isExpense; // true for expense, false for income
  final bool isDefault; // true if it's a system category (cannot be deleted)
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.iconName,
    required this.isExpense,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  // ========== ENTITY MAPPING ==========

  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        iconName: iconName,
        isExpense: isExpense,
        isDefault: isDefault,
        sortOrder: sortOrder,
      );

  factory CategoryModel.fromEntity(CategoryEntity e) => CategoryModel(
        id: e.id,
        iconName: e.iconName,
        isExpense: e.isExpense,
        isDefault: e.isDefault,
        sortOrder: e.sortOrder,
      );

  // ========== JSON SERIALIZATION ==========

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iconName': iconName,
      'isExpense': isExpense,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      iconName: json['iconName'] as String,
      isExpense: json['isExpense'] as bool,
      isDefault: json['isDefault'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  // ========== COPYSWITH ==========

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    bool? isExpense,
    bool? isDefault,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      iconName: iconName ?? this.iconName,
      isExpense: isExpense ?? this.isExpense,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // ========== DEFAULT CATEGORIES ==========

  /// Get default expense categories
  static List<CategoryModel> getDefaultExpenseCategories() {
    return [
      const CategoryModel(
        id: 'Yemek',
        iconName: 'restaurant',
        isExpense: true,
        isDefault: true,
        sortOrder: 1,
      ),
      const CategoryModel(
        id: 'Ulaşım',
        iconName: 'directions_bus',
        isExpense: true,
        isDefault: true,
        sortOrder: 2,
      ),
      const CategoryModel(
        id: 'Alışveriş',
        iconName: 'shopping_bag',
        isExpense: true,
        isDefault: true,
        sortOrder: 3,
      ),
      const CategoryModel(
        id: 'Fatura',
        iconName: 'receipt_long',
        isExpense: true,
        isDefault: true,
        sortOrder: 4,
      ),
      const CategoryModel(
        id: 'Eğlence',
        iconName: 'movie',
        isExpense: true,
        isDefault: true,
        sortOrder: 5,
      ),
    ];
  }

  /// Get default income categories
  static List<CategoryModel> getDefaultIncomeCategories() {
    return [
      const CategoryModel(
        id: 'Maaş',
        iconName: 'payments',
        isExpense: false,
        isDefault: true,
        sortOrder: 1,
      ),
      const CategoryModel(
        id: 'Yatırım',
        iconName: 'trending_up',
        isExpense: false,
        isDefault: true,
        sortOrder: 2,
      ),
      const CategoryModel(
        id: 'Serbest',
        iconName: 'work',
        isExpense: false,
        isDefault: true,
        sortOrder: 3,
      ),
    ];
  }

  @override
  String toString() {
    return 'CategoryModel(id(name): $id, isExpense: $isExpense)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
