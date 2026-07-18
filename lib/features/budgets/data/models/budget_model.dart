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

  /// Bütçenin ait olduğu cüzdan. null = walletId öncesi eski kayıt;
  /// datasource ilk yüklemede aktif cüzdana migrasyon yapar.
  @HiveField(2)
  final String? walletId;

  BudgetModel({
    required this.categoryId,
    required this.limitAmount,
    this.walletId,
  });

  /// Hive/yedek anahtarı. Cüzdanlı kayıtta `walletId::categoryId` — aynı
  /// kategori farklı cüzdanlarda ayrı bütçe tutabilsin. Eski (cüzdansız)
  /// kayıt çıplak categoryId anahtarını korur; migrasyon bunu yeniden yazar.
  String get storageKey => buildStorageKey(walletId, categoryId);

  static String buildStorageKey(String? walletId, String categoryId) =>
      (walletId == null || walletId.isEmpty)
          ? categoryId
          : '$walletId::$categoryId';

  /// Domain Entity'den Model'e dönüştürür.
  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      categoryId: entity.categoryId,
      limitAmount: entity.limitAmount,
      walletId: entity.walletId.isEmpty ? null : entity.walletId,
    );
  }

  /// Model'den Domain Entity'ye dönüştürür.
  BudgetEntity toEntity() {
    return BudgetEntity(
      categoryId: categoryId,
      limitAmount: limitAmount,
      walletId: walletId ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'limitAmount': limitAmount,
      'walletId': walletId,
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      categoryId: json['categoryId'] as String? ?? '',
      limitAmount: (json['limitAmount'] as num? ?? 0).toDouble(),
      walletId: json['walletId'] as String?,
    );
  }
}
