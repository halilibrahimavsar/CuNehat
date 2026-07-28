import 'package:flutter/widgets.dart';

import '../../config/di/injection.dart';
import 'onboarding_coordinator.dart';

/// Route yığını her değiştiğinde bekleyen turları yeniden değerlendirtir.
///
/// Turların görünürlük kapısı "route'um güncel mi" koşulunu içerir; bu koşulu
/// değiştiren tek olay route itme/çıkarma olduğundan (sheet ve diyaloglar
/// dahil) tetikleyici buradan gelir. Sayfa içi sinyallere (kabuk animasyonu,
/// route giriş/örtme animasyonları) ek bir güvencedir.
class OnboardingRouteObserver extends NavigatorObserver {
  void _pump() {
    if (!getIt.isRegistered<OnboardingCoordinator>()) return;
    getIt<OnboardingCoordinator>().notifyMaybeReady();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _pump();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _pump();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _pump();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _pump();
}
