/// İlk kurulumda kullanıcıya ÖNERİLEN kategori setleri.
///
/// Burada "varsayılan kategori" YOKTUR: bu liste yalnız bir öneridir, kurulan
/// her kayıt kullanıcının kendi kategorisi olur — düzenlenebilir, silinebilir,
/// hiçbir bayrak taşımaz. Kullanıcı seti atlayabilir; kategori yöneticisinin
/// boş durumundan geri dönebilir.
///
/// **Grup adları [CategoryGuesser] sözlüğünün grup adlarıyla hizalıdır.**
/// Banka ekstresi tahmini kullanıcının kategorilerini ADA göre eşler; buradaki
/// bir adı değiştirmek o eşleşmeyi sessizce koparır. Bağ
/// `category_starter_pack_guesser_test.dart` ile kilitlidir.
library;

/// Bir ana kategori ve önerilen alt kategorileri.
typedef StarterPackGroup = ({
  String name,
  String iconName,
  List<({String name, String iconName})> children,
});

class CategoryStarterPack {
  const CategoryStarterPack._();

  static const List<StarterPackGroup> expense = [
    (
      name: 'Market',
      iconName: 'shopping_cart',
      children: [
        (name: 'Manav', iconName: 'restaurant'),
        (name: 'Kasap', iconName: 'restaurant'),
        (name: 'Su & İçecek', iconName: 'local_cafe'),
      ],
    ),
    (
      name: 'Yemek',
      iconName: 'restaurant',
      children: [
        (name: 'Restoran', iconName: 'restaurant'),
        (name: 'Kafe', iconName: 'local_cafe'),
        (name: 'Paket Servis', iconName: 'two_wheeler'),
      ],
    ),
    (
      name: 'Ulaşım',
      iconName: 'directions_bus',
      children: [
        (name: 'Yakıt', iconName: 'local_gas_station'),
        (name: 'Toplu Taşıma', iconName: 'directions_bus'),
        (name: 'Taksi', iconName: 'local_taxi'),
        (name: 'Otopark', iconName: 'directions_car'),
      ],
    ),
    (
      name: 'Fatura',
      iconName: 'receipt_long',
      children: [
        (name: 'Elektrik', iconName: 'lightbulb'),
        (name: 'Su', iconName: 'water_drop'),
        (name: 'Doğalgaz', iconName: 'emergency'),
        (name: 'İnternet', iconName: 'language'),
        (name: 'Telefon', iconName: 'phone_android'),
      ],
    ),
    (
      name: 'Konut',
      iconName: 'home',
      children: [
        // 'Kira' CategoryGuesser'ın grup adı — alt kategori olarak da ada göre
        // eşleşir, sözlük bozulmaz.
        (name: 'Kira', iconName: 'home'),
        (name: 'Aidat', iconName: 'apartment'),
        (name: 'Bakım & Onarım', iconName: 'construction'),
      ],
    ),
    (
      name: 'Alışveriş',
      iconName: 'shopping_bag',
      children: [
        (name: 'Giyim', iconName: 'checkroom'),
        (name: 'Elektronik', iconName: 'devices'),
        (name: 'Ev Eşyası', iconName: 'chair'),
      ],
    ),
    (
      name: 'Sağlık',
      iconName: 'medical_services',
      children: [
        (name: 'İlaç', iconName: 'health_and_safety'),
        (name: 'Doktor', iconName: 'medical_services'),
        (name: 'Spor', iconName: 'fitness_center'),
      ],
    ),
    (
      name: 'Eğitim',
      iconName: 'school',
      children: [
        (name: 'Okul & Kurs', iconName: 'school'),
        (name: 'Kitap', iconName: 'menu_book'),
      ],
    ),
    (
      name: 'Eğlence',
      iconName: 'movie',
      children: [
        (name: 'Sinema & Konser', iconName: 'movie'),
        (name: 'Abonelikler', iconName: 'tv'),
        (name: 'Oyun', iconName: 'sports_esports'),
      ],
    ),
    (
      name: 'Kişisel',
      iconName: 'face',
      children: [
        (name: 'Kuaför', iconName: 'content_cut'),
        (name: 'Kozmetik', iconName: 'face'),
      ],
    ),
    // Gider tarafında da bir "Yatırım" kalemi var: ekstredeki hisse/fon/altın
    // ALIMI cüzdandan çıkan paradır. (Uygulama içinden yapılan yatırım
    // hareketleri sistem etiketi taşır, bu kategoriye düşmez —
    // bkz. CashMovementTags.investmentBuy.)
    (name: 'Yatırım', iconName: 'trending_up', children: []),
    (name: 'Diğer', iconName: 'category', children: []),
  ];

  static const List<StarterPackGroup> income = [
    (name: 'Maaş', iconName: 'payments', children: []),
    (
      name: 'Ek Gelir',
      iconName: 'savings',
      children: [
        (name: 'Prim & İkramiye', iconName: 'savings'),
        (name: 'Serbest Çalışma', iconName: 'work'),
      ],
    ),
    (name: 'Kira Geliri', iconName: 'apartment', children: []),
    (name: 'Yatırım', iconName: 'trending_up', children: []),
    (name: 'Diğer Gelir', iconName: 'category', children: []),
  ];

  /// Bir grubun kuracağı kayıt sayısı (kendisi + çocukları).
  static int sizeOf(StarterPackGroup group) => 1 + group.children.length;

  /// Önerilen bir ad pakette bir ALT kategoriyse üst kategorisinin adı, değilse
  /// `null`.
  ///
  /// Banka ekstresi eksik bir kategoriyi kurmayı önerdiğinde ("Kira") onu
  /// paketteki doğru yere ("Konut › Kira") yerleştirmek için kullanılır;
  /// aksi hâlde ekstre kökte ikinci bir "Kira" üretirdi.
  static String? parentNameOf(String childName, {required bool isExpense}) {
    for (final group in isExpense ? expense : income) {
      for (final child in group.children) {
        if (child.name == childName) return group.name;
      }
    }
    return null;
  }

  /// Pakette geçen bir adın önerilen ikonu (ana ya da alt kategori).
  static String? iconNameOf(String name, {required bool isExpense}) {
    for (final group in isExpense ? expense : income) {
      if (group.name == name) return group.iconName;
      for (final child in group.children) {
        if (child.name == name) return child.iconName;
      }
    }
    return null;
  }
}
