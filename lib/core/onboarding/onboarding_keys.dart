import 'package:flutter/widgets.dart';

/// Turların Showcase hedefleri.
///
/// Anahtarlar modül seviyesinde sabit tutulur: hedefi taşıyan widget'ların bir
/// kısmı StatelessWidget olduğundan (kendi initState'leri yok) her rebuild'de
/// yeni bir GlobalKey yaratılsa Showcase'in kayıt sistemi her seferinde farklı
/// bir key görüp hedefi bulamazdı. Turun kapısı ([OnboardingTour]) hedefin
/// gerçekten render edildiğini `isTargetRendered` ile bu anahtarlar üzerinden
/// doğrular — bu yüzden bir turun TÜM adımları aynı anda ağaçta olmak
/// zorundadır.
class OnboardingKeys {
  OnboardingKeys._();

  // ==================== Kabuk (OnboardingFlow.shell) ====================

  /// AppBar'da dokunulunca cüzdan sheet'ini açan cüzdan adı/bakiye alanı.
  static final GlobalKey appBarWalletArea =
      GlobalKey(debugLabel: 'onboarding_appbar_wallet_area');

  /// AppBar'daki menü (drawer) butonu.
  static final GlobalKey appBarMenuButton =
      GlobalKey(debugLabel: 'onboarding_appbar_menu');

  /// SliderButtonView'ı (gelir/gider/yatırım/borç ekle eylemleri) saran
  /// Showcase hedefi; kabuk turunun son adımı olarak navigasyon kartını
  /// gösterir. lib/features/main_feature/pages/home_page.dart'ta tanımlanır.
  static final GlobalKey addActionSlider =
      GlobalKey(debugLabel: 'onboarding_add_action_slider');

  // ============== Cüzdan yönetimi (OnboardingFlow.walletManagement) ======

  /// Cüzdan sheet'inin başlığı: cüzdan listesi ve toplam karşılık. Adım
  /// listedeki bir karta değil başlığa konur — liste `ListView.builder`,
  /// yani elemanları tembel kurulur ve üstündeki bir hedef `isTargetRendered`
  /// kapısında kararsız davranır.
  static final GlobalKey walletManagementHeader =
      GlobalKey(debugLabel: 'onboarding_wallet_header');

  /// "Yeni Cüzdan Oluştur" butonu.
  static final GlobalKey walletManagementAddButton =
      GlobalKey(debugLabel: 'onboarding_wallet_add_button');

  // ============== Gelir/gider formu (OnboardingFlow.transactionsAdd) =====

  static final GlobalKey transactionAddForm =
      GlobalKey(debugLabel: 'onboarding_tx_add_form');
  static final GlobalKey transactionAddCategory =
      GlobalKey(debugLabel: 'onboarding_tx_add_category');
  static final GlobalKey transactionAddRecurring =
      GlobalKey(debugLabel: 'onboarding_tx_add_recurring');

  // ============== Borç/alacak formu (OnboardingFlow.debtAdd) =============

  /// Tutar kartı ve vade hapı: ikisi de HEM borç HEM alacak modunda ağaçta.
  /// Yalnız borç modunda görünen alanlara (tür çipleri, taksit/faiz) adım
  /// konulamaz — kapı tüm hedefleri aradığından tur alacak modunda hiç
  /// oynamazdı.
  static final GlobalKey debtAddForm =
      GlobalKey(debugLabel: 'onboarding_debt_add_form');
  static final GlobalKey debtAddDueDate =
      GlobalKey(debugLabel: 'onboarding_debt_add_due_date');

  // ============== Yatırım formu (OnboardingFlow.investmentAdd) ===========

  /// Altın/hisse/özel sheet'lerinin üçü de aynı flow'u kullanır; hangisi önce
  /// açılırsa tur onda gösterilir. İlk iki adım üçünde de vardır, miktar adımı
  /// yalnız altın ve hissede (aynı anda yalnız biri mount olur).
  static final GlobalKey investmentAddForm =
      GlobalKey(debugLabel: 'onboarding_investment_add_form');
  static final GlobalKey investmentAddCost =
      GlobalKey(debugLabel: 'onboarding_investment_add_cost');
  static final GlobalKey investmentAddQuantity =
      GlobalKey(debugLabel: 'onboarding_investment_add_quantity');
}
