import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// Transaction Category Model
///
/// Represents a category for income or expense transactions
class CategoryModel {
  /// Sabit, opak anahtar — `TransactionEntity.tag` ve bütçe anahtarı buna
  /// bağlıdır, yeniden adlandırmada DEĞİŞMEZ. Bkz. [CategoryEntity].
  final String id;

  /// Kullanıcının verdiği görünen ad. `null` → ad id'den çözülür.
  final String? displayName;

  final String iconName;
  final bool isExpense; // true for expense, false for income
  final bool isDefault; // true if it's a system category (cannot be deleted)
  final int sortOrder;

  const CategoryModel({
    required this.id,
    this.displayName,
    required this.iconName,
    required this.isExpense,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  /// l10n'suz karşılaştırma etiketi (çakışma kontrolü, veri katmanı).
  /// Sunum katmanı varsayılanları l10n'a çevirir; bkz. `context.categoryLabel`.
  String get rawLabel => displayName ?? id;

  // ========== ENTITY MAPPING ==========

  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        displayName: displayName,
        iconName: iconName,
        isExpense: isExpense,
        isDefault: isDefault,
        sortOrder: sortOrder,
      );

  factory CategoryModel.fromEntity(CategoryEntity e) => CategoryModel(
        id: e.id,
        displayName: e.displayName,
        iconName: e.iconName,
        isExpense: e.isExpense,
        isDefault: e.isDefault,
        sortOrder: e.sortOrder,
      );

  // ========== JSON SERIALIZATION ==========

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'iconName': iconName,
      'isExpense': isExpense,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      // Gerçekten nullable alan (kullanıcı ad vermediyse yok), sürüm fallback'i değil.
      displayName: json['displayName'] as String?,
      iconName: json['iconName'] as String,
      isExpense: json['isExpense'] as bool,
      isDefault: json['isDefault'] as bool,
      sortOrder: json['sortOrder'] as int,
    );
  }

  // ========== COPYSWITH ==========

  /// Bkz. [CategoryEntity.copyWith] — `id` bilerek yoktur.
  CategoryModel copyWith({
    String? displayName,
    String? iconName,
    bool? isExpense,
    bool? isDefault,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id,
      displayName: displayName ?? this.displayName,
      iconName: iconName ?? this.iconName,
      isExpense: isExpense ?? this.isExpense,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // ========== DEFAULT CATEGORIES ==========

  /// Varsayılan gider kategorileri.
  ///
  /// `id`'ler opak anahtardır: kullanıcıya `context.categoryLabel` üzerinden
  /// l10n'a çevrilerek gösterilir, deftere (`TransactionEntity.tag`) ise
  /// buradaki hâliyle yazılır. Bu yüzden bir id'yi DEĞİŞTİRMEK, o kategoriye
  /// yazılmış tüm işlemleri ve bütçeleri yetim bırakır — yeni kategori ekle,
  /// mevcudun id'sini düzenleme.
  ///
  /// Adlar `CategoryGuesser` grup adlarıyla birebir eşleşir; dokunulmamış bir
  /// kurulumda banka ekstresi tahminleri doğrudan tutar.
  static List<CategoryModel> getDefaultExpenseCategories() {
    return [
      const CategoryModel(
        id: 'Market',
        iconName: 'shopping_cart',
        isExpense: true,
        isDefault: true,
        sortOrder: 1,
      ),
      const CategoryModel(
        id: 'Yemek',
        iconName: 'restaurant',
        isExpense: true,
        isDefault: true,
        sortOrder: 2,
      ),
      const CategoryModel(
        id: 'Ulaşım',
        iconName: 'directions_bus',
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
        id: 'Kira',
        iconName: 'home',
        isExpense: true,
        isDefault: true,
        sortOrder: 5,
      ),
      const CategoryModel(
        id: 'Alışveriş',
        iconName: 'shopping_bag',
        isExpense: true,
        isDefault: true,
        sortOrder: 6,
      ),
      const CategoryModel(
        id: 'Sağlık',
        iconName: 'medical_services',
        isExpense: true,
        isDefault: true,
        sortOrder: 7,
      ),
      const CategoryModel(
        id: 'Eğitim',
        iconName: 'school',
        isExpense: true,
        isDefault: true,
        sortOrder: 8,
      ),
      const CategoryModel(
        id: 'Eğlence',
        iconName: 'movie',
        isExpense: true,
        isDefault: true,
        sortOrder: 9,
      ),
    ];
  }

  /// Varsayılan gelir kategorileri. Bkz. [getDefaultExpenseCategories] —
  /// aynı id kuralları geçerlidir.
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
        id: 'Ek Gelir',
        iconName: 'savings',
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
      const CategoryModel(
        id: 'Yatırım',
        iconName: 'trending_up',
        isExpense: false,
        isDefault: true,
        sortOrder: 4,
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
