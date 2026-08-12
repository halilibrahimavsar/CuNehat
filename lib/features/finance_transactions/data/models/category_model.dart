import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:hive/hive.dart';

part 'category_model.g.dart';

/// Kategori kaydı. Bkz. [CategoryEntity] — kimlik/hiyerarşi kuralları orada.
///
/// typeId 15: 0-2, 4-7 ve 9-14 kullanımda; 3 ve 8 geçmişte kullanılmış
/// olabileceği için atlandı.
/// `HiveObject`'ten TÜREMEZ (bkz. `TransactionModel` — aynı tercih): bir
/// HiveObject örneği iki farklı anahtarla saklanamaz, güncellemede her seferinde
/// taze örnek üretmek zorunda kalmak sessiz bir tuzak olurdu.
@HiveType(typeId: 15)
class CategoryModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String iconName;

  @HiveField(3)
  final bool isExpense;

  /// `null` → ana kategori. Gerçekten nullable bir alan, sürüm fallback'i değil.
  @HiveField(4)
  final String? parentId;

  @HiveField(5)
  final int sortOrder;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.isExpense,
    this.parentId,
    this.sortOrder = 0,
  });

  // ========== ENTITY MAPPING ==========

  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        name: name,
        iconName: iconName,
        isExpense: isExpense,
        parentId: parentId,
        sortOrder: sortOrder,
      );

  factory CategoryModel.fromEntity(CategoryEntity e) => CategoryModel(
        id: e.id,
        name: e.name,
        iconName: e.iconName,
        isExpense: e.isExpense,
        parentId: e.parentId,
        sortOrder: e.sortOrder,
      );

  // ========== JSON (yedek) ==========

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'isExpense': isExpense,
        'parentId': parentId,
        'sortOrder': sortOrder,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        iconName: json['iconName'] as String,
        isExpense: json['isExpense'] as bool,
        // Gerçekten nullable alan (ana kategoride yok), sürüm fallback'i değil.
        parentId: json['parentId'] as String?,
        sortOrder: json['sortOrder'] as int,
      );

  @override
  String toString() =>
      'CategoryModel($id, $name, isExpense: $isExpense, parentId: $parentId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
