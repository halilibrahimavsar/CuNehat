/// Kullanıcıya **keşfedilemeyeni** gösteren interaktif turlar.
///
/// Küratörlük kuralı: bir adım ancak ekranda yazmayan bir JESTİ anlatıyorsa
/// vardır. Bir alanın ne işe yaradığını anlatan adım tur değildir; o bilgi
/// alanın altında durur (`FieldHint`, `InvestmentHintCaption`), ilk açılışta
/// bir kez gösterilip kaybolmaz.
///
/// Eskiden altı tur ve 14 hedef vardı: kabuk (3 adım), cüzdan sayfası (2),
/// gelir/gider formu (3), borç formu (2), birikim formu (3), kart şeridi (1).
/// Yeni kullanıcı ilk harcamasını yazmadan önce altı baloncuğu kapatıyordu.
/// Kalan iki tur birer adımdır.
///
/// **Bildirim sırası = öncelik.** Kalıcı bayrak `flow.name` üzerinden
/// yazıldığından değer çıkarmak ötekilerin kayıtlı "görüldü" bilgisini
/// bozmaz; çıkarılan turların bayrakları tercihlerde yetim kalır (zararsız).
enum OnboardingFlow {
  /// Alttaki kaydırıcı: yana = bölüm değiştir, yukarı = alt sayfa, dokun =
  /// ekle. Yalnız kaydırıcı varken, yani ikinci bölüm (Birikim ya da Borç)
  /// açıldıktan sonra oynar; yalnız İşlemler açıkken ekranda jest yoktur.
  shell,

  /// Kredi kartı düğmesi: ilk kart eklendikten sonra, işlemler ekranında TEK
  /// adım — kartın ayrı bir cüzdan değil hesabın içinde olduğu ekranda
  /// yazmıyor.
  cardRail,
}

extension OnboardingFlowSurface on OnboardingFlow {
  /// Turun yüzeyi HomePage kabuğunun kendisi mi?
  ///
  /// Kalan iki turun ikisi de kabuktadır: hedefleri (kaydırıcı, kart düğmesi)
  /// kabuğa aittir ve kabuk, alt sayfa açıkken veya geçiş animasyonu sürerken
  /// bu hedefleri ekranda kaydırır — tur ancak kabuk kökte ve durur haldeyken
  /// oynayabilir.
  bool get requiresHomeShellAtRoot => true;
}
