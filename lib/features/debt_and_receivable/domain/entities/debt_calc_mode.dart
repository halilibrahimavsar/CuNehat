/// Bir borcun toplam geri ödemesinin **hangi yöntemle** hesaplandığı.
///
/// Kayıtla birlikte saklanır ve tek gerçek kaynaktır. Eskiden mod, `interestRate`
/// alanının değerinden geri türetiliyordu ("oran 0 ise kullanıcı aylık taksit
/// girmiştir" gibi) — bu tahmin üç ayrı sessiz veri kaybına yol açıyordu:
///
///  * Basit vade farkı modunda oran hiç saklanmıyordu (sentinel 0), düzenleyip
///    kaydetmek vade farkını toplamdan siliyordu (12.000 → 10.000).
///  * KKDF/BSMV anahtarını saklayan bir alan yoktu; düzenleme toplamı
///    vergisiz yeniden hesaplıyordu (117.694,01 → 113.471,52).
///  * Faizi gerçekten %0 olan bir kredi yanlış moda düşüyor, o modda
///    gösterilmeyen gecikme faizi sıfırlanıyordu.
///
/// Mod açıkça saklandığından oran artık saf veridir ve düzenleme kaydı
/// olduğu gibi bırakır.
enum DebtCalcMode {
  /// Faizsiz: toplam = ana para. (Kişisel borç)
  none,

  /// Aylık taksit biliniyor: toplam = taksit × vade. (Banka kredisi)
  fixedInstallment,

  /// Eşit taksitli kredi (amortisman), aylık faiz oranı üzerinden.
  amortized,

  /// Amortisman + tüketici kredisi vergileri (%15 KKDF + %15 BSMV).
  amortizedWithTaxes,

  /// Basit vade farkı: toplam = ana para × (1 + oran/100). (Taksitli borç)
  flatSurcharge,

  /// Basit aylık faiz: toplam = ana para × (1 + oran × vade/100). (Diğer)
  ///
  /// Oran **aylıktır** — form da "Aylık Faiz %" diyor. Eskiden aynı alan
  /// yıllık nominal faiz gibi işleniyordu (`rate × term / 1200`), yani girilen
  /// oranın etkisi 12 kat küçüktü.
  simpleMonthlyInterest,
}

extension DebtCalcModeX on DebtCalcMode {
  /// Bu mod `interestRate` alanını kullanıyor mu? Kullanmıyorsa form o alanı
  /// hiç göstermez ve kayda 0 yazılır.
  bool get usesInterestRate =>
      this != DebtCalcMode.none && this != DebtCalcMode.fixedInstallment;
}
