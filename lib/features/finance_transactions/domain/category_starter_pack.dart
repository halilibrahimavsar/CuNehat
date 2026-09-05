/// İlk kurulumda kullanıcıya ÖNERİLEN kategori setleri.
///
/// Burada "varsayılan kategori" YOKTUR: bu liste yalnız bir öneridir, kurulan
/// her kayıt kullanıcının kendi kategorisi olur — düzenlenebilir, silinebilir,
/// hiçbir bayrak taşımaz. Kullanıcı seti atlayabilir; kategori yöneticisinin
/// boş durumundan geri dönebilir.
///
/// **Burada AD yok, ANAHTAR var.** Kurulacak ad seçili dile göre çözülür
/// (bkz. `categorySeedName`) ve kurulduğu anda kullanıcı verisine dönüşür.
/// Anahtar sabittir: [CategoryGuesser] sözlüğü de aynı anahtarları hedefler,
/// yani bir çeviriyi değiştirmek ekstre tahminini koparmaz. Bağ
/// `category_starter_pack_test.dart` ile kilitlidir.
library;

/// Bir ana kategori ve önerilen alt kategorileri.
typedef StarterPackGroup = ({
  String key,
  String iconName,
  List<({String key, String iconName})> children,
});

class CategoryStarterPack {
  const CategoryStarterPack._();

  static const List<StarterPackGroup> expense = [
    (
      key: 'groceries',
      iconName: 'shopping_cart',
      children: [
        (key: 'groceries.produce', iconName: 'restaurant'),
        (key: 'groceries.butcher', iconName: 'restaurant'),
        (key: 'groceries.drinks', iconName: 'local_cafe'),
      ],
    ),
    (
      key: 'dining',
      iconName: 'restaurant',
      children: [
        (key: 'dining.restaurant', iconName: 'restaurant'),
        (key: 'dining.cafe', iconName: 'local_cafe'),
        (key: 'dining.takeaway', iconName: 'two_wheeler'),
      ],
    ),
    (
      key: 'transport',
      iconName: 'directions_bus',
      children: [
        (key: 'transport.fuel', iconName: 'local_gas_station'),
        (key: 'transport.public', iconName: 'directions_bus'),
        (key: 'transport.taxi', iconName: 'local_taxi'),
        (key: 'transport.parking', iconName: 'directions_car'),
      ],
    ),
    (
      key: 'bills',
      iconName: 'receipt_long',
      children: [
        (key: 'bills.electricity', iconName: 'lightbulb'),
        (key: 'bills.water', iconName: 'water_drop'),
        (key: 'bills.gas', iconName: 'emergency'),
        (key: 'bills.internet', iconName: 'language'),
        (key: 'bills.phone', iconName: 'phone_android'),
      ],
    ),
    (
      key: 'housing',
      iconName: 'home',
      children: [
        // 'housing.rent' CategoryGuesser'ın da hedefi — alt kategori olarak
        // eşleşir, sözlük bozulmaz.
        (key: 'housing.rent', iconName: 'home'),
        (key: 'housing.dues', iconName: 'apartment'),
        (key: 'housing.maintenance', iconName: 'construction'),
      ],
    ),
    (
      key: 'shopping',
      iconName: 'shopping_bag',
      children: [
        (key: 'shopping.clothing', iconName: 'checkroom'),
        (key: 'shopping.electronics', iconName: 'devices'),
        (key: 'shopping.homegoods', iconName: 'chair'),
      ],
    ),
    (
      key: 'health',
      iconName: 'medical_services',
      children: [
        (key: 'health.pharmacy', iconName: 'health_and_safety'),
        (key: 'health.doctor', iconName: 'medical_services'),
        (key: 'health.fitness', iconName: 'fitness_center'),
      ],
    ),
    (
      key: 'education',
      iconName: 'school',
      children: [
        (key: 'education.school', iconName: 'school'),
        (key: 'education.books', iconName: 'menu_book'),
      ],
    ),
    (
      key: 'entertainment',
      iconName: 'movie',
      children: [
        (key: 'entertainment.cinema', iconName: 'movie'),
        (key: 'entertainment.subscriptions', iconName: 'tv'),
        (key: 'entertainment.games', iconName: 'sports_esports'),
      ],
    ),
    (
      key: 'personal',
      iconName: 'face',
      children: [
        (key: 'personal.hairdresser', iconName: 'content_cut'),
        (key: 'personal.cosmetics', iconName: 'face'),
      ],
    ),
    // Gider tarafında da bir "Yatırım" kalemi var: ekstredeki hisse/fon/altın
    // ALIMI cüzdandan çıkan paradır. (Uygulama içinden yapılan yatırım
    // hareketleri sistem etiketi taşır, bu kategoriye düşmez —
    // bkz. CashMovementTags.investmentBuy.)
    (key: 'investment', iconName: 'trending_up', children: []),
    (key: 'other', iconName: 'category', children: []),
  ];

  static const List<StarterPackGroup> income = [
    (key: 'salary', iconName: 'payments', children: []),
    (
      key: 'sideIncome',
      iconName: 'savings',
      children: [
        (key: 'sideIncome.bonus', iconName: 'savings'),
        (key: 'sideIncome.freelance', iconName: 'work'),
      ],
    ),
    (key: 'rentalIncome', iconName: 'apartment', children: []),
    // Gelir tarafının "Yatırım"ı gider tarafındakiyle AYNI adı taşır ama ayrı
    // bir anahtardır: ikisi ayrı ad uzaylarında (gelir/gider) yaşayan iki ayrı
    // kategoridir. Adları eşit olduğu için ada bakan eşleşme yine de doğru
    // havuzda doğru kaydı bulur.
    (key: 'investmentIncome', iconName: 'trending_up', children: []),
    (key: 'otherIncome', iconName: 'category', children: []),
  ];

  /// Bir grubun kuracağı kayıt sayısı (kendisi + çocukları).
  static int sizeOf(StarterPackGroup group) => 1 + group.children.length;

  /// Önerilen bir anahtar pakette bir ALT kategoriyse üst kategorisinin
  /// anahtarı, değilse `null`.
  ///
  /// Banka ekstresi eksik bir kategoriyi kurmayı önerdiğinde (`housing.rent`)
  /// onu paketteki doğru yere ("Konut › Kira") yerleştirmek için kullanılır;
  /// aksi hâlde ekstre kökte ikinci bir "Kira" üretirdi.
  static String? parentKeyOf(String childKey, {required bool isExpense}) {
    for (final group in isExpense ? expense : income) {
      for (final child in group.children) {
        if (child.key == childKey) return group.key;
      }
    }
    return null;
  }

  /// Pakette geçen bir anahtarın önerilen ikonu (ana ya da alt kategori).
  static String? iconNameOf(String key, {required bool isExpense}) {
    for (final group in isExpense ? expense : income) {
      if (group.key == key) return group.iconName;
      for (final child in group.children) {
        if (child.key == key) return child.iconName;
      }
    }
    return null;
  }

  /// Paketteki TÜM anahtarlar (ana + alt), tür fark etmeksizin.
  static Iterable<String> get allKeys sync* {
    for (final group in [...expense, ...income]) {
      yield group.key;
      for (final child in group.children) {
        yield child.key;
      }
    }
  }
}
