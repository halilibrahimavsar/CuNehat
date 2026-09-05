import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String? id;
  final String userId;
  final String name;
  final double balance;
  final double debt;
  final double credit;
  final double investment;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final bool isActive;
  final int sortOrder;

  /// Cüzdanın açılış (başlangıç) bakiyesi; oluşturulurken atanır.
  /// Defter değişmezi: `balance = openingBalance + Σ signed(işlemler)`.
  final double openingBalance;

  /// Cüzdanın para birimi ('TRY' | 'USD' | 'EUR'). Tüm tutarlar (balance,
  /// işlemler) bu birimde tutulur; işlem geçmişi oluştuktan sonra
  /// değiştirilemez (geçmiş tutarların anlamı bozulur).
  final String currency;

  /// Bu cüzdanda GÖRÜNÜR kategorilerin kimlikleri.
  ///
  /// Kategoriler küresel kayıtlardır (bkz. [CategoryEntity]); cüzdan onlara
  /// sahip olmaz, yalnız hangilerini kullandığını söyler. Böylece aynı
  /// kategori iki cüzdanda AYNI kimliği taşır — işlem `tag`'i, bütçe anahtarı
  /// ve CSV'deki okunaklı ad cüzdandan bağımsız kalır.
  ///
  /// **`null` = kürasyon yapılmamış → hepsi görünür.** Bu, alanı olmayan eski
  /// kayıtların (Hive'da alan 14 yok, v9 yedeğinde anahtar yok) anlamıdır ve
  /// mevcut kurulumlarda davranışı hiç değiştirmez. Yeni cüzdanlar BOŞ küme
  /// (`const []`) ile doğar: "henüz hiçbir kategori seçilmedi", bu yüzden
  /// başlangıç paketi onlara yeniden önerilir.
  ///
  /// Değişmez: bir alt kategori kümedeyse ana kategorisi de kümededir
  /// (bkz. `wallet_category_scope.dart`).
  final List<String>? categoryIds;

  const WalletEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.debt,
    required this.credit,
    required this.investment,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    this.isActive = false,
    this.sortOrder = 0,
    required this.openingBalance,
    this.currency = 'TRY',
    this.categoryIds,
  });

  WalletEntity copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    double? debt,
    double? credit,
    double? investment,
    String? colorHex,
    String? iconName,
    DateTime? createdAt,
    bool? isActive,
    int? sortOrder,
    double? openingBalance,
    String? currency,
    List<String>? categoryIds,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      debt: debt ?? this.debt,
      credit: credit ?? this.credit,
      investment: investment ?? this.investment,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      openingBalance: openingBalance ?? this.openingBalance,
      currency: currency ?? this.currency,
      // `null` = KORU (alışıldık copyWith kuralı). Kürasyonu geri almak
      // (küme → null) kullanıcıya sunulan bir eylem değil, bu yüzden
      // `clearCategoryIds` bayrağı bilerek yok.
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        balance,
        debt,
        credit,
        investment,
        colorHex,
        iconName,
        createdAt,
        isActive,
        sortOrder,
        openingBalance,
        currency,
        categoryIds,
      ];
}
