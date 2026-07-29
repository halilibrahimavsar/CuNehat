import 'package:equatable/equatable.dart';

/// İşlem kategorisi.
///
/// [id] SABİT, opak bir anahtardır — kullanıcıya asla gösterilmez ve yeniden
/// adlandırmada DEĞİŞMEZ. `TransactionEntity.tag` ve bütçe anahtarı
/// (`walletId::categoryId`) doğrudan bu değere bağlıdır; id değişseydi her
/// yeniden adlandırma tüm işlemleri ve bütçeleri yetim bırakırdı.
///
/// Görünen ad [displayName]'dir. `null` ise ad id'den çözülür:
/// varsayılan kategorilerde l10n'a çevrilir (bkz. `context.categoryLabel`),
/// özel kategorilerde id zaten oluşturulurken verilen addır.
class CategoryEntity extends Equatable {
  final String id;

  /// Kullanıcının verdiği görünen ad. `null` → ad id'den çözülür.
  final String? displayName;

  final String iconName;
  final bool isExpense;

  /// Sistem kategorisi (silinemez).
  final bool isDefault;
  final int sortOrder;

  const CategoryEntity({
    required this.id,
    this.displayName,
    required this.iconName,
    required this.isExpense,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  /// [id] BİLEREK yoktur: kimlik değişmez.
  ///
  /// Düzeltilen hata tam olarak `copyWith(id: yeniAd)` idi — form yeniden
  /// adlandırmayı id'ye yazıyordu; updateCategory kaydı YENİ id ile aradığı
  /// için hiçbir zaman bulamıyor, her yeniden adlandırma "kategori bulunamadı"
  /// ile düşüyordu (yalnız ikon değişikliği çalışıyordu). Parametre burada
  /// durursa aynı veri bozulması her an geri gelebilir; olmayınca derleme
  /// hatasına dönüşür. Yeniden adlandırma [displayName] üzerinden yapılır.
  CategoryEntity copyWith({
    String? displayName,
    String? iconName,
    bool? isExpense,
    bool? isDefault,
    int? sortOrder,
  }) {
    return CategoryEntity(
      id: id,
      displayName: displayName ?? this.displayName,
      iconName: iconName ?? this.iconName,
      isExpense: isExpense ?? this.isExpense,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props =>
      [id, displayName, iconName, isExpense, isDefault, sortOrder];
}
