import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'cube_face.dart';

/// Direction of cube transition
enum CubeDirection {
  left, // Horizontal: slide left
  right, // Horizontal: slide right
  up, // Vertical: slide up (going to higher index)
  down, // Vertical: slide down (going to lower index)
}

bool _isHorizontal(CubeDirection direction) =>
    direction == CubeDirection.left || direction == CubeDirection.right;

/// Bir küp yüzünün geçiş parametrelerini üretir.
///
/// [isOutgoing] false ise yüz "gelen" taraftır. Duran bir yığında geçerli
/// yüz, `value = 1.0` ile gelen taraf olarak çizilir; tüm dönüşümler birim
/// olduğundan görsel olarak dokunulmamış görünür.
CubeFace _cubeFace({
  required Widget child,
  required bool visible,
  required bool isOutgoing,
  required double value,
  required CubeDirection direction,
  required bool useFade,
}) {
  // right/down = normal (-1 for outgoing rotation to go right/down)
  // left/up = reverse (1 for outgoing rotation to go left/up)
  final sign =
      (direction == CubeDirection.right || direction == CubeDirection.down)
          ? -1.0
          : 1.0;
  final horizontal = _isHorizontal(direction);

  final rotation = isOutgoing
      ? Tween(begin: 0.0, end: sign * math.pi / 2.2).transform(value)
      : Tween(begin: -sign * math.pi / 2.2, end: 0.0).transform(value);

  final Offset translation;
  if (horizontal) {
    translation = isOutgoing
        ? Tween<Offset>(begin: Offset.zero, end: Offset(sign, 0.0))
            .transform(value)
        : Tween<Offset>(begin: Offset(-sign, 0.0), end: Offset.zero)
            .transform(value);
  } else {
    translation = isOutgoing
        ? Tween<Offset>(begin: Offset.zero, end: Offset(0.0, sign))
            .transform(value)
        : Tween<Offset>(begin: Offset(0.0, -sign), end: Offset.zero)
            .transform(value);
  }

  final Alignment alignment;
  if (horizontal) {
    alignment = isOutgoing
        ? (sign < 0 ? Alignment.centerRight : Alignment.centerLeft)
        : (sign < 0 ? Alignment.centerLeft : Alignment.centerRight);
  } else {
    alignment = isOutgoing
        ? (sign < 0 ? Alignment.bottomCenter : Alignment.topCenter)
        : (sign < 0 ? Alignment.topCenter : Alignment.bottomCenter);
  }

  return CubeFace(
    visible: visible,
    alignment: alignment,
    rotationX: horizontal ? 0.0 : rotation,
    rotationY: horizontal ? rotation : 0.0,
    translation: translation,
    opacity: useFade ? (isOutgoing ? 1.0 - value : value) : 1.0,
    child: child,
  );
}

/// Unified cube transition widget supporting all directions
///
/// Supports both horizontal (main menu) and vertical (subview list) transitions
class UnifiedCubeTransition extends StatelessWidget {
  final AnimationController controller;
  final Widget outgoingView;
  final Widget incomingView;
  final CubeDirection direction;
  final bool useFade;

  const UnifiedCubeTransition({
    super.key,
    required this.controller,
    required this.outgoingView,
    required this.incomingView,
    required this.direction,
    this.useFade = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            _cubeFace(
              child: outgoingView,
              visible: value < 0.95,
              isOutgoing: true,
              value: value,
              direction: direction,
              useFade: useFade,
            ),
            _cubeFace(
              child: incomingView,
              visible: value > 0.05,
              isOutgoing: false,
              value: value,
              direction: direction,
              useFade: useFade,
            ),
          ],
        );
      },
    );
  }
}

/// Manager for vertical list-style transitions
///
/// Treats views as a vertical stack:
/// - Index 0: MainView
/// - Index 1+: SubViews
///
/// Down (index increase): View comes from bottom
/// Up (index decrease): View comes from top
class VerticalListTransitionManager extends ChangeNotifier {
  late final AnimationController _controller;

  /// Geçişi süren eğrili animasyon.
  ///
  /// Eskiden yüzler doğrudan `_controller.value`'yu okuyordu ve `navigateTo`
  /// `forward(from: 0)` çağırıyordu: hareket baştan sona **doğrusaldı**.
  /// Doğrusal hareket mekanik/ucuz okunur; yatay eksen zaten `animateTo`
  /// üzerinden eğriliydi, dikey eksen değildi.
  late final CurvedAnimation _curved;

  final List<Widget> _views = [];
  List<Widget>? _pendingViews;
  int? _pendingTarget;
  int _currentIndex = 0;
  int? _previousIndex;
  bool _isTransitioning = false;

  VerticalListTransitionManager(TickerProvider vsync, {Duration? duration}) {
    _controller = AnimationController(
      vsync: vsync,
      duration: duration ?? const Duration(milliseconds: 500),
    );
    // `easeInOutCubic`, `easeOutCubic` DEĞİL: ikincisi t=0'da doğrusalın üç
    // katı hızla açılıyor ve geçiş "fırlamış" gibi hissettiriyordu. Yavaş
    // başlayıp yavaş biten eğri, doğrusalın mekanikliğini de almadan yumuşak.
    _curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.addStatusListener(_onStatusChanged);
  }

  AnimationController get controller => _controller;

  /// Yüzlerin okuduğu eğrili animasyon.
  Animation<double> get animation => _curved;
  bool get isTransitioning => _isTransitioning;
  bool get isAtMainView => _currentIndex == 0;
  int get currentIndex => _currentIndex;
  List<Widget> get views => List.unmodifiable(_views);

  /// Register available views
  ///
  /// Geçiş animasyonu sürerken liste değiştirilmez; kapanan sayfanın
  /// animasyon ortasında başka bir sayfaya dönüşmemesi için yeni liste
  /// bekletilip animasyon bitince uygulanır.
  void setViews(List<Widget> views) {
    if (_isTransitioning) {
      _pendingViews = List.of(views);
      return;
    }
    _applyViews(views);
    // No notifyListeners() here to prevent 'markNeedsBuild() called during build' exception.
    // The widget calling this is already rebuilding, so the UI will update naturally.
  }

  void _applyViews(List<Widget> views) {
    _views.clear();
    _views.addAll(views);
    if (_currentIndex >= _views.length) {
      _currentIndex = 0;
    }
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _previousIndex = null;
      _isTransitioning = false;
      if (_pendingViews != null) {
        _applyViews(_pendingViews!);
        _pendingViews = null;
      }
      final pendingTarget = _pendingTarget;
      _pendingTarget = null;
      if (pendingTarget != null &&
          pendingTarget >= 0 &&
          pendingTarget < _views.length &&
          pendingTarget != _currentIndex) {
        navigateTo(pendingTarget);
      }
      notifyListeners();
    }
  }

  /// Navigate to a specific index
  ///
  /// Geçiş sürerken gelen istek düşürülmez; bekletilir ve mevcut animasyon
  /// bitince işlenir. Yoksa kapanış animasyonu sırasında yapılan alt menü
  /// seçimi yutulur ve knob ile ekran birbirinden kopar.
  Future<void> navigateTo(int index) async {
    if (_isTransitioning) {
      _pendingTarget = index;
      return;
    }
    if (index < 0 || index >= _views.length) return;
    if (index == _currentIndex) return;

    _isTransitioning = true;
    _previousIndex = _currentIndex;
    _currentIndex = index;
    notifyListeners();

    await _controller.forward(from: 0.0);
  }

  /// Build the current transition
  ///
  /// Her görünüm yığında **sabit bir yuvada** durur; geçiş başlarken ya da
  /// biterken widget zinciri değişmediğinden görünümler yeniden mount olmaz.
  /// (Eski sürüm duruyorken görünümü çıplak, geçerken sarmalanmış döndürüyor;
  /// bu da her alt sayfa açılışında sayfayı iki kez mount ediyordu.)
  /// [useFade] AÇIK olmalı: kapatıldığında dönen yüzün dikdörtgen kenarı
  /// ekranı süpürerek geçiyor (cihazda görüldü). `Opacity`nin geçiş boyunca
  /// açtığı iki tam ekran `saveLayer` bilinçli olarak kabul ediliyor.
  Widget buildTransition({bool useFade = true}) {
    if (_views.isEmpty) return const SizedBox.shrink();
    return _VerticalCubeStack(
      animation: _curved,
      views: List.of(_views),
      currentIndex: _currentIndex.clamp(0, _views.length - 1),
      previousIndex: _isTransitioning ? _previousIndex : null,
      useFade: useFade,
    );
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }
}

class _VerticalCubeStack extends StatelessWidget {
  final Animation<double> animation;
  final List<Widget> views;
  final int currentIndex;
  final int? previousIndex;
  final bool useFade;

  const _VerticalCubeStack({
    required this.animation,
    required this.views,
    required this.currentIndex,
    required this.previousIndex,
    required this.useFade,
  });

  @override
  Widget build(BuildContext context) {
    final previous = previousIndex;
    final isTransitioning = previous != null &&
        previous != currentIndex &&
        previous >= 0 &&
        previous < views.length;
    final direction = isTransitioning && currentIndex > previous
        ? CubeDirection.down
        : CubeDirection.up;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // Durur haldeyken geçerli yüz "gelen" tarafın bitiş konumundadır:
        // dönüşümler birim, opaklık 1.
        final value = isTransitioning ? animation.value : 1.0;
        return Stack(
          alignment: Alignment.center,
          // Yığın artık duruyorken de araya girdiğinden, görünümler eskiden
          // olduğu gibi ebeveynin kısıtlarını AYNEN almalı.
          fit: StackFit.passthrough,
          children: [
            for (var i = 0; i < views.length; i++)
              _cubeFace(
                child: views[i],
                isOutgoing: isTransitioning && i == previous,
                visible: i == currentIndex
                    ? value > 0.05
                    : (isTransitioning && i == previous && value < 0.95),
                value: value,
                direction: direction,
                useFade: useFade,
              ),
          ],
        );
      },
    );
  }
}
