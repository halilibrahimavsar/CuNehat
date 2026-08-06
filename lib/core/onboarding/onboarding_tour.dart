import 'package:flutter/widgets.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../config/di/injection.dart';
import 'onboarding_coordinator.dart';
import 'onboarding_flow.dart';

/// Bir interaktif turun sahibi. Görsel etkisi yoktur — [child]'ı olduğu gibi
/// render eder; tek işi turun **doğru sayfada ve doğru anda** oynamasını
/// sağlayan kapıyı tutmaktır.
///
/// Kapı koşulları:
/// 1. Sahip widget hâlâ ağaçta (`mounted`),
/// 2. sahibinin route'u güncel — üstünde başka sayfa, sheet ya da diyalog yok,
/// 3. route'un giriş animasyonu bitti,
/// 4. tur kabuğa bağlıysa (bkz. [OnboardingFlowSurface.requiresHomeShellAtRoot])
///    kabuk kökte ve duruyor (küp geçişi yok, drawer/cüzdan dönüşümü yok),
/// 5. turun tüm Showcase hedefleri gerçekten render edilmiş.
///
/// Koşullardan biri sağlanmıyorsa istek düşürülmez, **beklemede kalır**:
/// kullanıcı o sayfaya döndüğünde tur oracıkta oynar. Bayrak ancak tur
/// gerçekten başladığında yazıldığından, oynatılamayan bir tur kaybolmaz.
class OnboardingTour extends StatefulWidget {
  final OnboardingFlow flow;

  /// Turun adımları (Showcase hedef anahtarları), sırasıyla.
  final List<GlobalKey> keys;

  /// false ise tur hiç istenmez (ör. düzenleme modundaki form, TL dışı
  /// cüzdanda hedefleri mount edilmeyen sayfa).
  final bool enabled;

  final Widget child;

  const OnboardingTour({
    super.key,
    required this.flow,
    required this.keys,
    required this.child,
    this.enabled = true,
  });

  @override
  State<OnboardingTour> createState() => _OnboardingTourState();
}

class _OnboardingTourState extends State<OnboardingTour> {
  late final OnboardingCoordinator? _coordinator =
      getIt.isRegistered<OnboardingCoordinator>()
          ? getIt<OnboardingCoordinator>()
          : null;

  ModalRoute<dynamic>? _route;
  Animation<double>? _enterAnimation;
  Animation<double>? _coverAnimation;

  @override
  void initState() {
    super.initState();
    // Ayarlar'dan "turu tekrar göster" bayrağı temizlediğinde canlı sayfalar
    // isteklerini yeniden açsın.
    _coordinator?.addListener(_onCoordinatorChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _arm());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (identical(route, _route)) return;
    _detachRouteListeners();
    _route = route;
    // Giriş animasyonu = "sayfam yerine oturdu", örtme animasyonu = "üstümdeki
    // sayfa gidip geldi". İkisi de kapının açılabileceği anları işaret eder;
    // route yığını değişimleri başka hiçbir dinleyiciye yansımaz.
    _enterAnimation = route?.animation?..addStatusListener(_onRouteAnimation);
    _coverAnimation = route?.secondaryAnimation
      ?..addStatusListener(_onRouteAnimation);
  }

  @override
  void didUpdateWidget(covariant OnboardingTour oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) _arm();
  }

  void _detachRouteListeners() {
    _enterAnimation?.removeStatusListener(_onRouteAnimation);
    _coverAnimation?.removeStatusListener(_onRouteAnimation);
    _enterAnimation = null;
    _coverAnimation = null;
  }

  void _onRouteAnimation(AnimationStatus _) => _coordinator?.notifyMaybeReady();

  void _onCoordinatorChanged() {
    final coordinator = _coordinator;
    if (coordinator == null || !mounted) return;
    if (coordinator.isSeen(widget.flow) || coordinator.isPending(widget.flow)) {
      return;
    }
    _arm();
  }

  void _arm() {
    final coordinator = _coordinator;
    if (coordinator == null || !mounted || !widget.enabled) return;
    coordinator.requestTour(
      widget.flow,
      owner: this,
      keys: widget.keys,
      isAlive: () => mounted,
      isReady: _isReady,
    );
  }

  bool _isReady() {
    if (!mounted || !widget.enabled) return false;

    final route = _route;
    if (route == null || !route.isCurrent) return false;
    final enterAnimation = route.animation;
    if (enterAnimation != null && enterAnimation.value < 1.0) return false;
    // Üstteki sayfa çıkarken route "güncel" sayılır ama ekranı hâlâ örter;
    // örtme animasyonu tamamen bitmeden tur açılmamalı.
    final coverAnimation = route.secondaryAnimation;
    if (coverAnimation != null && coverAnimation.value > 0.0) return false;

    if (widget.flow.requiresHomeShellAtRoot &&
        !(_coordinator?.isHomeShellAtRoot() ?? false)) {
      return false;
    }

    // Hedefi ağaçta olmayan bir adım overlay'i boş/yanlış yere çizer.
    final showcase = ShowcaseView.get();
    for (final key in widget.keys) {
      if (!showcase.isTargetRendered(key)) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _detachRouteListeners();
    _coordinator
      ?..removeListener(_onCoordinatorChanged)
      ..cancelTour(widget.flow, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bekleyen istek varken her yeniden çizim bir yeniden değerlendirme
    // fırsatıdır: görünürlük koşulu çoğu zaman bir rebuild ile değişir
    // (cüzdan yüklendi, alt yığın kapandı, sheet kapandı...).
    final coordinator = _coordinator;
    if (coordinator != null &&
        !coordinator.isSeen(widget.flow) &&
        coordinator.isPending(widget.flow)) {
      coordinator.notifyMaybeReady();
    }
    return widget.child;
  }
}
