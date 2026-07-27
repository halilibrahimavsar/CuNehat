/// Para aritmetiği için tek nokta: kuruş yuvarlama ve tolerans karşılaştırma.
///
/// Tutarlar double saklanır; her YAZIM noktası [roundToCents]'ten geçer,
/// her KARŞILAŞTIRMA yarım kuruş toleransıyla yapılır. Böylece
/// 314.55999999999995 gibi FP artıkları kullanıcıya "kalan tutardan fazla"
/// hatası olarak dönmez.
///
/// Gösterim amaçlı fold/`+=` toplamları (rapor/analiz servisleri) bilinçli
/// olarak ham bırakılır: saklanan tutarlar kuruş-temiz olduğundan biriken
/// hata ~1e-9 mertebesinde kalır ve formatMoney render'da zaten yuvarlar.
/// İstisna: toplam bir KARARA girecekse (ör. bütçenin "tam doldu mu"su)
/// ya yuvarlanmalı ya da buradaki toleranslı karşılaştırıcılarla ölçülmeli.
library;

/// Yarım kuruş toleransı: fark bunun altındaysa iki değer para olarak eşittir.
const double kMoneyEpsilon = 0.005;

/// Kuruşa (2 hane) yuvarlar. 314.55999999999995 → 314.56.
double roundToCents(double v) => (v * 100).roundToDouble() / 100;

/// a, b'den anlamlı şekilde (yarım kuruştan fazla) büyük mü?
/// Tutar üst-sınır doğrulamalarında kullanılır.
bool moneyGreaterThan(double a, double b) => a - b > kMoneyEpsilon;

/// a ≥ b (tolerans dahilinde). isPaid türü "tamamlandı mı" kontrolleri için.
bool moneyGte(double a, double b) => a - b >= -kMoneyEpsilon;

/// İki tutar para olarak eşit mi?
bool moneyEquals(double a, double b) => (a - b).abs() <= kMoneyEpsilon;

/// Tutar para olarak sıfırdan büyük mü? (−0.001 artığı "kalan borç" sayılmaz.)
bool moneyIsPositive(double v) => v > kMoneyEpsilon;
