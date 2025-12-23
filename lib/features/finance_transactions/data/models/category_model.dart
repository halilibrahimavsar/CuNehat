/// Transaction Category Model
///
/// Represents a category for income or expense transactions
class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final bool isExpense; // true for expense, false for income
  final bool isDefault; // true if it's a system category (cannot be deleted)
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.isExpense,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  // ========== JSON SERIALIZATION ==========

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'isExpense': isExpense,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
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
      name: name ?? this.name,
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
        id: 'exp_food',
        name: 'Yemek',
        iconName: 'restaurant',
        isExpense: true,
        isDefault: true,
        sortOrder: 1,
      ),
      const CategoryModel(
        id: 'exp_transport',
        name: 'Ulaşım',
        iconName: 'directions_bus',
        isExpense: true,
        isDefault: true,
        sortOrder: 2,
      ),
      const CategoryModel(
        id: 'exp_shopping',
        name: 'Alışveriş',
        iconName: 'shopping_bag',
        isExpense: true,
        isDefault: true,
        sortOrder: 3,
      ),
      const CategoryModel(
        id: 'exp_bills',
        name: 'Fatura',
        iconName: 'receipt_long',
        isExpense: true,
        isDefault: true,
        sortOrder: 4,
      ),
      const CategoryModel(
        id: 'exp_entertainment',
        name: 'Eğlence',
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
        id: 'inc_salary',
        name: 'Maaş',
        iconName: 'payments',
        isExpense: false,
        isDefault: true,
        sortOrder: 1,
      ),
      const CategoryModel(
        id: 'inc_investment',
        name: 'Yatırım',
        iconName: 'trending_up',
        isExpense: false,
        isDefault: true,
        sortOrder: 2,
      ),
      const CategoryModel(
        id: 'inc_freelance',
        name: 'Serbest',
        iconName: 'work',
        isExpense: false,
        isDefault: true,
        sortOrder: 3,
      ),
    ];
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, isExpense: $isExpense)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
