import 'package:flutter/widgets.dart';

/// HomePage seviyesinde tanımlı, üç ana ekran turunun da ortak son adımı
/// olarak kullandığı hedef anahtarlar (ör. ekle eylemleri kaydırıcısı).
class OnboardingKeys {
  OnboardingKeys._();

  /// SliderButtonView'ı (gelir/gider/yatırım/borç ekle eylemleri) saran
  /// Showcase hedefi. lib/features/main_feature/pages/home_page.dart'ta
  /// tanımlanır; üç sayfa da kendi tur listesinin sonuna bunu ekler.
  static final GlobalKey addActionSlider =
      GlobalKey(debugLabel: 'onboarding_add_action_slider');

  /// Alt sayfaların (Detay/İçgörü/Rapor/Geçmiş) tur hedefleri. Bu sayfalar
  /// StatelessWidget olduğundan (kendi initState'leri yok), her rebuild'de
  /// yeniden yaratılmaması için burada modül-seviyesinde sabit tutulur —
  /// aksi halde Showcase'in kayıt sistemi her seferinde farklı bir key
  /// görüp hedefi bulamaz.
  static final GlobalKey investmentDetailBody =
      GlobalKey(debugLabel: 'onboarding_investment_detail_body');
  static final GlobalKey transactionsInsightsBody =
      GlobalKey(debugLabel: 'onboarding_tx_insights_body');
  static final GlobalKey transactionsReportBody =
      GlobalKey(debugLabel: 'onboarding_tx_report_body');
  static final GlobalKey debtHistoryBody =
      GlobalKey(debugLabel: 'onboarding_debt_history_body');

  /// Ekleme sheet'leri (gelir/gider, borç/alacak, yatırım) — üçü de aynı
  /// desende: sheet açılınca bir kez, düzenleme değil yeni-kayıt modundayken.
  /// Yatırım tarafında altın/hisse/özel sheet'lerinin üçü de aynı key+flow'u
  /// kullanır; hangisi önce açılırsa tur onda gösterilir.
  static final GlobalKey transactionAddForm =
      GlobalKey(debugLabel: 'onboarding_tx_add_form');
  static final GlobalKey debtAddForm =
      GlobalKey(debugLabel: 'onboarding_debt_add_form');
  static final GlobalKey investmentAddForm =
      GlobalKey(debugLabel: 'onboarding_investment_add_form');

  /// AppBar: menü (drawer) butonu ve dokunulunca cüzdan sheet'ini açan
  /// cüzdan adı/bakiye alanı.
  static final GlobalKey appBarMenuButton =
      GlobalKey(debugLabel: 'onboarding_appbar_menu');
  static final GlobalKey appBarWalletArea =
      GlobalKey(debugLabel: 'onboarding_appbar_wallet_area');

  /// Cüzdan yönetimi sheet'i: "Yeni Cüzdan Oluştur" butonu.
  static final GlobalKey walletManagementAddButton =
      GlobalKey(debugLabel: 'onboarding_wallet_add_button');

  /// Bütçe sayfası: "yeni bütçe ekle" FAB.
  static final GlobalKey budgetsAddButton =
      GlobalKey(debugLabel: 'onboarding_budgets_add_button');

  /// Düzenli işlemler sayfası: tüm gövde (liste/boş durum).
  static final GlobalKey recurringTemplatesBody =
      GlobalKey(debugLabel: 'onboarding_recurring_templates_body');
}
