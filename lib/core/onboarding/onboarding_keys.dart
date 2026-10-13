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
///
/// Yalnız iki hedef kaldı (bkz. `OnboardingFlow`): ikisi de ekranda yazmayan
/// bir jesti / ilişkiyi anlatır.
class OnboardingKeys {
  OnboardingKeys._();

  /// Alttaki kaydırıcıyı (`SliderButtonView`) saran hedef; navigasyon kartını
  /// gösterir. `home_page.dart`'ta, yalnız kaydırıcı kurulduğunda tanımlanır.
  static final GlobalKey addActionSlider =
      GlobalKey(debugLabel: 'onboarding_add_action_slider');

  /// Kredi kartı düğmesi (üst çubuk).
  static final GlobalKey cardRail =
      GlobalKey(debugLabel: 'onboarding.cardRail');
}
