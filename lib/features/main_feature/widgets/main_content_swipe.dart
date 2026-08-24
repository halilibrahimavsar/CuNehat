import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:flutter/material.dart';

/// Ana sayfalar (Birikim ↔ İşlemler ↔ Borç) arasında içerik üzerinden yatay
/// geçiş.
///
/// Bu jest eklenene kadar `lib` içinde tek bir `onHorizontalDrag` yoktu:
/// üç sayfa arasında geçmenin TEK yolu ekranın altındaki 130×100 px'lik
/// knob'u yakalamaktı. Kullanıcıların navigasyonu bulamamasının en büyük
/// payı buradaydı.
///
/// Dikey liste kaydırmasıyla çakışmaz (jest arenası yönü ayırır) ve daha
/// derindeki YATAY jestler — kaydır-sil, takvimin ay değiştirmesi, yatay
/// listeler — önceliklidir, çünkü isabet testi en derinden başlar ve eşit
/// eşikte önce çözen kazanır.
///
/// ## Yalnız ANA görünümde kurulur
///
/// Alt sayfa (Rapor, İçgörüler, Detay, Borç geçmişi) açıkken jest **hiç
/// kurulmaz**. İki ölçülmüş neden:
///
/// 1. Alt sayfada yatay eksene dokunmak yıkıcı: `dragMainBy` ekseni
///    kıpırdatır kıpırdatmaz [HomeNavigationController] alt sayfayı kapatır.
///    Ölçüldü: alt sayfa açıkken **25 px**'lik kazara bir yatay kayma raporu
///    kapatıp ana görünüme döndürüyordu.
/// 2. Grafikler alt sayfalarda yaşıyor ve fl_chart dokunuşu kendi
///    `PanGestureRecognizer`'ıyla okuyor. Pan eşiği 36 px (`kPanSlop`), bu
///    jestin eşiği 18 px (`kTouchSlop`): yatay sürüklemede kabuk arenayı
///    HER ZAMAN önce kazanıp grafiği iptal ettiriyordu. Ölçülen olay dizisi
///    `[FlPanDownEvent, FlPanCancelEvent]` — yani ipucu balonu dokunur
///    dokunmaz beliriyor, parmak kıpırdayınca ölüyordu.
///
/// Kapı, callback'leri **null**'a çekerek işler: [GestureDetector] o zaman
/// `HorizontalDragGestureRecognizer`'ı hiç kurmaz, jest arenasına hiç
/// girmez. Kontrolü callback'in İÇİNDE yapmak yetmez — tanınıp yok sayılan
/// bir jest arenayı yine kazanır ve grafiği yine iptal ettirir.
///
/// Sarmalayıcı ağaçtan çıkarılmaz (koşullu `child` döndürülmez): o yol
/// [child]'ın Element'ini düşürüp tüm sayfa yığınını yeniden mount ederdi.
///
/// Kapı ANA sayfalardaki grafikleri kapsamaz; bugün böyle bir grafik yok
/// (ölçüldü: `InvestmentChart`'ın pastası `touchCallback` vermiyor, o yüzden
/// fl_chart olayı hiç işlemiyor ve arenaya girmiyor). Ana sayfaya etkileşimli
/// bir grafik konursa kapı yetmez; ölçülmüş çare, kabuğun yatay eşiğini özel
/// bir recognizer'la (`hasSufficientGlobalDistanceToAccept`) `kPanSlop`'un
/// ÜSTÜNE çıkarmaktır: 45 px'te grafik arenayı önce kazanıyor, sayfa jesti
/// de çalışmaya devam ediyor. Bedeli her yerde ~27 px'lik ölü yol.
class MainContentSwipe extends StatelessWidget {
  const MainContentSwipe({
    super.key,
    required this.controller,
    required this.child,
  });

  final HomeNavigationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ListenableBuilder(
          // Alt sayfa açılıp kapanınca kapı yeniden değerlendirilmeli.
          // `navigateTo` _currentIndex'i yazdıktan HEMEN sonra haber verir.
          listenable: controller.viewStack,
          builder: (context, content) {
            final enabled = controller.isAtMainView;
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: enabled
                  ? (details) => controller.dragMainBy(
                        deltaX: details.delta.dx,
                        width: width,
                      )
                  : null,
              onHorizontalDragEnd: enabled
                  ? (details) => controller.settleMain(
                        velocityX: details.velocity.pixelsPerSecond.dx,
                      )
                  : null,
              onHorizontalDragCancel: enabled ? controller.settleMain : null,
              child: content,
            );
          },
          child: child,
        );
      },
    );
  }
}
