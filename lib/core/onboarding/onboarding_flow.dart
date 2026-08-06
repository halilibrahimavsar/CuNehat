/// Kullanıcıya **keşfedilemeyeni** gösteren interaktif turlar.
///
/// Küratörlük kuralı: bir adım ancak ekranda yazmayan bir davranışı
/// anlatıyorsa vardır. Sayfa başlığını tekrar eden ("Geçmiş → geçmişiniz
/// burada") ya da boş bir listenin üstünde oynayan tur yoktur; o işi
/// sayfaların kendi boş durum ekranları yapar. Bu yüzden turlar kullanıcının
/// iş yaptığı yüzeylerde toplanmıştır: kabuk, cüzdan yönetimi ve üç ekleme
/// formu.
///
/// **Bildirim sırası = öncelik.** Aynı anda birden çok tur oynatılabilir
/// duruma gelirse [OnboardingCoordinator] bu sırayı izler. Kalıcı bayrak
/// `flow.name` üzerinden yazıldığından sıra değiştirmek kayıtlı "görüldü"
/// bilgisini bozmaz.
enum OnboardingFlow {
  /// Kabuk: aktif cüzdan alanı → menü → ekle/navigasyon kartı. İlk cüzdan
  /// oluştuktan SONRA oynar (bkz. AppBarContent'teki `enabled` koşulu);
  /// cüzdanı olmayan kullanıcıya "işte aktif cüzdanın" demenin anlamı yok.
  shell,

  /// Cüzdan sheet'i: cüzdan listesi → yeni cüzdan.
  walletManagement,

  /// Gelir/gider formu: tutar → kategori → tekrar sıklığı.
  transactionsAdd,

  /// Borç/alacak formu: tutar kartı → vade tarihi.
  debtAdd,

  /// Yatırım formu: mevcut değer → toplam maliyet → (altın/hisse) miktar.
  investmentAdd,
}

extension OnboardingFlowSurface on OnboardingFlow {
  /// Turun yüzeyi HomePage kabuğunun kendisi mi?
  ///
  /// Yalnız [OnboardingFlow.shell] için true: hedefleri (appBar, ekle
  /// kaydırıcısı) kabuğa aittir ve kabuk, alt sayfa açıkken veya geçiş
  /// animasyonu sürerken bu hedefleri ekranda kaydırır — tur ancak kabuk
  /// kökte ve durur haldeyken oynayabilir. Diğer turların kendi route'u
  /// vardır (sheet / itilmiş sayfa); görünürlükleri yalnızca route
  /// durumundan belirlenir.
  bool get requiresHomeShellAtRoot => this == OnboardingFlow.shell;
}
