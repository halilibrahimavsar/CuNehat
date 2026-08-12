import 'package:equatable/equatable.dart';

/// İşlem kategorisi — en fazla İKİ seviye: ana kategori → alt kategori.
///
/// [id] UUID'dir; kullanıcıya asla gösterilmez ve yeniden adlandırmada DEĞİŞMEZ.
/// `TransactionEntity.tag` ve bütçe anahtarı (`walletId::categoryId`) doğrudan
/// bu değere bağlıdır.
///
/// Kimliğin addan ayrı olması hiyerarşinin ön koşuludur: ad kimlik olsaydı
/// `Fatura > Su` ile `Konut > Su` aynı anda var olamazdı. Ad tekilliği artık
/// yalnız KARDEŞLER arasında aranır (bkz. `category_tree.dart`).
class CategoryEntity extends Equatable {
  final String id;

  /// Kullanıcıya gösterilen ad. Kategorilerin tamamı kullanıcı tarafından
  /// oluşturulduğu için her zaman doludur — l10n'a çevrilecek "varsayılan
  /// kategori" kavramı yoktur.
  final String name;

  final String iconName;
  final bool isExpense;

  /// Bağlı olduğu ana kategori. `null` → bu kaydın kendisi ana kategoridir.
  ///
  /// Alt kategorinin alt kategorisi olamaz; kural `validateCategory` ile
  /// zorlanır.
  final String? parentId;

  /// Kardeşler arası sıra.
  final int sortOrder;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconName,
    required this.isExpense,
    this.parentId,
    this.sortOrder = 0,
  });

  bool get isRoot => parentId == null;

  /// [id] BİLEREK yoktur: kimlik değişmez.
  ///
  /// Düzeltilen hata tam olarak `copyWith(id: yeniAd)` idi — form yeniden
  /// adlandırmayı id'ye yazıyordu; updateCategory kaydı YENİ id ile aradığı
  /// için hiçbir zaman bulamıyor, her yeniden adlandırma "kategori bulunamadı"
  /// ile düşüyordu. Parametre burada durursa aynı veri bozulması her an geri
  /// gelebilir; olmayınca derleme hatasına dönüşür.
  ///
  /// [clearParent] alt kategoriyi ana kategoriye YÜKSELTİR: `parentId: null`
  /// geçmek `?? this.parentId` yüzünden işe yaramaz (bkz. aynı desen
  /// `FilterEntity.copyWith(clearCategories:)`).
  CategoryEntity copyWith({
    String? name,
    String? iconName,
    bool? isExpense,
    String? parentId,
    bool clearParent = false,
    int? sortOrder,
  }) {
    return CategoryEntity(
      id: id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      isExpense: isExpense ?? this.isExpense,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, iconName, isExpense, parentId, sortOrder];
}
