/// Ana ekranlara, alt sayfalara ve kendi route'una sahip yüzeylere (sheet /
/// tam sayfa) bağlı interaktif turlar.
///
/// **Bildirim sırası = öncelik.** Aynı anda birden çok tur oynatılabilir
/// duruma gelirse [OnboardingCoordinator] bu sırayı izler; önce kabuk
/// (appBar), sonra ana ekranlar, sonra alt sayfalar, en sonda kendi
/// route'una sahip yüzeyler gelir. Kalıcı bayrak `flow.name` üzerinden
/// yazıldığından sıra değiştirmek kayıtlı "görüldü" bilgisini bozmaz.
enum OnboardingFlow {
  appBar,
  investment,
  transactions,
  debt,
  investmentDetail,
  transactionsInsights,
  transactionsReport,
  debtHistory,
  investmentAdd,
  transactionsAdd,
  debtAdd,
  walletManagement,
  budgets,
  recurringTemplates,
}

/// Bir turun ana kabuktaki (HomePage) konumu.
///
/// HomePage üç ana ekranı yatay küpte, alt sayfaları dikey yığında tutar;
/// ikisi de geçiş sırasında hedef widget'ları ekranda kaydırır. Tur yalnızca
/// kabuk TAM OLARAK bu konumda durduğunda oynatılır — "sıra gelince nerede
/// olursak olalım başlat" davranışının panzehiri budur.
class OnboardingHomeSlot {
  /// Yatay küpteki demirleme değeri (0.0 yatırım, 0.5 işlemler, 1.0 borç).
  /// null ise yatay konum önemsizdir (kabuk kromu: appBar).
  final double? sliderValue;

  /// Dikey yığındaki indeks (0 ana görünüm, 1+ alt sayfalar).
  /// null ise dikey konum önemsizdir.
  final int? stackIndex;

  const OnboardingHomeSlot({this.sliderValue, this.stackIndex});

  /// Kabuğun her yerinde görünen kromu (appBar): yalnızca "kabuk duruyor mu"
  /// koşulunu arar.
  static const OnboardingHomeSlot chrome = OnboardingHomeSlot();
}

extension OnboardingFlowSurface on OnboardingFlow {
  /// Turun HomePage kabuğundaki konumu; `null` ise yüzeyin kendi route'u
  /// vardır (sheet / itilmiş sayfa) ve görünürlük yalnızca route durumundan
  /// belirlenir.
  ///
  /// Alt sayfa indeksleri `SubViewFactory.createSubViewsForState` ile
  /// birebir eşleşmek zorundadır.
  OnboardingHomeSlot? get homeSlot => switch (this) {
        OnboardingFlow.appBar => OnboardingHomeSlot.chrome,
        OnboardingFlow.investment =>
          const OnboardingHomeSlot(sliderValue: 0.0, stackIndex: 0),
        OnboardingFlow.investmentDetail =>
          const OnboardingHomeSlot(sliderValue: 0.0, stackIndex: 1),
        OnboardingFlow.transactions =>
          const OnboardingHomeSlot(sliderValue: 0.5, stackIndex: 0),
        OnboardingFlow.transactionsInsights =>
          const OnboardingHomeSlot(sliderValue: 0.5, stackIndex: 1),
        OnboardingFlow.transactionsReport =>
          const OnboardingHomeSlot(sliderValue: 0.5, stackIndex: 2),
        OnboardingFlow.debt =>
          const OnboardingHomeSlot(sliderValue: 1.0, stackIndex: 0),
        OnboardingFlow.debtHistory =>
          const OnboardingHomeSlot(sliderValue: 1.0, stackIndex: 1),
        OnboardingFlow.investmentAdd ||
        OnboardingFlow.transactionsAdd ||
        OnboardingFlow.debtAdd ||
        OnboardingFlow.walletManagement ||
        OnboardingFlow.budgets ||
        OnboardingFlow.recurringTemplates =>
          null,
      };

  /// Ayarlar'dan tek tek tekrar oynatılabilen üç ana ekran turu; HomePage
  /// bunlarda kaydırıcıyı ilgili ekrana taşır.
  bool get isReplayableMainScreen =>
      this == OnboardingFlow.investment ||
      this == OnboardingFlow.transactions ||
      this == OnboardingFlow.debt;
}
