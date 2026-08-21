import 'package:flutter/cupertino.dart'
    show
        CupertinoFullscreenDialogTransition,
        CupertinoPageTransition,
        CupertinoRouteTransitionMixin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android'in sistem geri jestini iOS tarzı kayma/paralaks geçişine bağlar.
///
/// **Neden:** `PredictiveBackPageTransitionsBuilder` jesti canlı takip ediyor
/// ama hareketi çok küçük — kaynaktan: üstteki sayfa `0.90`'a küçülüyor ve
/// yalnız `genişlik/20 − 8` kadar kayıyor (360 dp'de **10 piksel**), üstüne
/// parmağın dikey hareketiyle aşağı yukarı gidiyor. Alttaki sayfa ise hiç
/// kıpırdamıyor: `secondaryAnimation` veriliyor ama gövdede hiç okunmuyor ve
/// `delegatedTransition` yok (SDK'da `flutter#153577` TODO'su).
///
/// **Nasıl:** 3.44'te predictive-back zincirinin tamamı public
/// (`WidgetsBindingObserver.handleStartBackGesture` ve kardeşleri;
/// `PageRoute.handleStartBackGesture` / `...UpdateBackGestureProgress` /
/// `...Commit` / `...Cancel`). Yani jesti sistemden alıp route'un
/// animasyonunu parmakla sürerken görseli kendimiz seçebiliyoruz. Görsel için
/// Flutter'ın kendi `CupertinoPageTransition`'ı kullanılıyor — tam genişlik
/// kayma, alttaki sayfada paralaks ve kenar gölgesi.
///
/// **Ödünleşim:** Android'in kendi predictive-back görünümü (küçülüp arkayı
/// gösterme) terk ediliyor. Platformla birebir uyum yerine belirgin ve
/// gerçekten etkileşimli bir geçiş tercih edildi.
///
/// **Kapsam:** predictive back yalnız Android 14+ (API 34) ve jest etkinken
/// ilerleme olayı gönderiyor. Altındaki sürümlerde jest canlı OLAMAZ — ama
/// jest dışı yol da aynı kaymayı kullandığı için o cihazlar da eski cılız
/// fade yerine düzgün bir geçiş görüyor.
class PredictiveSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const PredictiveSlidePageTransitionsBuilder();

  @override
  Duration get transitionDuration =>
      CupertinoRouteTransitionMixin.kTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      CupertinoPageTransition.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Sürükleme sürerken geçiş DOĞRUSAL olmalı, yoksa sayfa parmakla aynı
    // hızda gitmez. `buildTransitions` route'un kendi `AnimatedBuilder`'ı
    // tarafından kare başına çağrıldığı için bu değer tazedir.
    final linearTransition = route.popGestureInProgress;

    return SystemBackGestureDriver(
      route: route,
      child: route.fullscreenDialog
          ? CupertinoFullscreenDialogTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: linearTransition,
              child: child,
            )
          : CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: linearTransition,
              child: child,
            ),
    );
  }
}

/// Sistemin predictive-back olaylarını route'un animasyonuna bağlar.
///
/// Flutter'ın aynı işi yapan dedektörü private; buradaki kopya yalnız public
/// API kullanıyor. Görsel etkisi yok — [child]'ı olduğu gibi render eder.
///
/// Jest sırasında `buildTransitions` her route için çağrıldığından bu widget
/// aynı anda birden çok kez mount olur; yalnız GÜNCEL route'unki jesti kabul
/// eder ([_isEnabled]) ve çerçeve güncelleme/bitirme olaylarını da yalnız
/// kabul edenlere dağıtır.
@visibleForTesting
class SystemBackGestureDriver extends StatefulWidget {
  const SystemBackGestureDriver({
    super.key,
    required this.route,
    required this.child,
  });

  final PageRoute<dynamic> route;
  final Widget child;

  @override
  State<SystemBackGestureDriver> createState() =>
      _SystemBackGestureDriverState();
}

class _SystemBackGestureDriverState extends State<SystemBackGestureDriver>
    with WidgetsBindingObserver {
  /// `handleStartBackGesture` içinde `assert(isCurrent)` var; kapı şart.
  bool get _isEnabled =>
      widget.route.isCurrent && widget.route.popGestureEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _clearPendingStop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// `linearTransition` route'un `popGestureInProgress`'inden okunuyor;
  /// jest başında/bitiminde animasyon değeri değişmeyebileceği için o
  /// okumayı tazelemek adına bir kare zorlanır.
  void _refresh() {
    if (mounted) setState(() {});
  }

  // ---- WidgetsBindingObserver ----

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent || !_isEnabled) return false;
    // Route'un animasyonu 1 → 0 gidiyor; jest ilerlemesi 0 → 1.
    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    _refresh();
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    widget.route
        .handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
  }

  /// İptalde çerçevenin kendi yolu doğru: `forward()` mevcut değerden devam
  /// eder (süre de kalan mesafeye göre ölçeklenir), sıçrama yok.
  @override
  void handleCancelBackGesture() {
    widget.route.handleCancelBackGesture();
    _refresh();
  }

  /// Onayda `route.handleCommitBackGesture()` KULLANILMIYOR.
  ///
  /// O yol popladıktan hemen sonra `_controller.reverse(from: upperBound)`
  /// çağırıyor (`routes.dart:601-605`), yani animasyonu **1.0'a geri
  /// sıçratıp baştan oynatıyor. SDK'nın kendi geçişleri bunu maskeleyen ayrı
  /// bir "commit" animasyonu çizdiği için orada görünmüyor; doğrusal eşlenen
  /// bir kayma geçişinde ise sayfa parmağın bıraktığı yerden geri fırlayıp
  /// tekrar çıkıyor — iki ayrı animasyon gibi. Ölçüldü: 677 px → 382 px.
  ///
  /// Bunun yerine Cupertino'nun sürükle-bırakının yaptığı yapılıyor: düz
  /// `pop()`. `didPop` zaten `reverse()`ü MEVCUT değerden başlatıyor ve
  /// `AnimationController` süreyi kalan mesafeyle ölçeklediği için oturma
  /// hem kesintisiz hem orantılı oluyor.
  @override
  void handleCommitBackGesture() {
    final route = widget.route;
    final navigator = route.navigator;

    if (route.isCurrent) {
      navigator?.pop();
    }
    // `handleStartBackGesture` içindeki `didStartUserGesture()` dengelenmeli.
    // Oturma bitene kadar beklenir ki `popGestureInProgress` — dolayısıyla
    // `linearTransition` — animasyon boyunca sürsün.
    _stopUserGestureWhenSettled(navigator, route.animation);
    _refresh();
  }

  AnimationStatusListener? _pendingStop;
  Animation<double>? _pendingStopAnimation;

  void _stopUserGestureWhenSettled(
    NavigatorState? navigator,
    Animation<double>? animation,
  ) {
    _clearPendingStop();
    final status = animation?.status;
    if (animation == null ||
        (status != AnimationStatus.forward &&
            status != AnimationStatus.reverse)) {
      navigator?.didStopUserGesture();
      return;
    }

    void listener(AnimationStatus status) {
      if (status == AnimationStatus.forward ||
          status == AnimationStatus.reverse) {
        return;
      }
      _clearPendingStop();
      navigator?.didStopUserGesture();
    }

    _pendingStop = listener;
    _pendingStopAnimation = animation;
    animation.addStatusListener(listener);
  }

  void _clearPendingStop() {
    final listener = _pendingStop;
    if (listener == null) return;
    _pendingStopAnimation?.removeStatusListener(listener);
    _pendingStop = null;
    _pendingStopAnimation = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
