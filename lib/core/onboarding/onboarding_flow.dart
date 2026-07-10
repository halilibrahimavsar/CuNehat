/// Ana ekranlara ve alt sayfalara bağlı interaktif turlar. investment/
/// transactions/debt Ayarlar'dan tek tek tekrar oynatılabilir (bkz.
/// OnboardingHelpCard); alt sayfa akışları (Detay/İçgörü/Rapor/Geçmiş) o
/// sayfaya ilk gidişte otomatik tetiklenir, ayrıca "Tüm Turları Sıfırla" ile
/// topluca sıfırlanabilir.
enum OnboardingFlow {
  investment,
  investmentDetail,
  investmentAdd,
  transactions,
  transactionsInsights,
  transactionsReport,
  transactionsAdd,
  debt,
  debtHistory,
  debtAdd,
  appBar,
  walletManagement,
  budgets,
  recurringTemplates,
}
