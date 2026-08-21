import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:flutter/material.dart';

/// Küpün dikey yığınını sistem geri jestine bağlar.
///
/// Alt sayfalar (Detay / Rapor / Geçmiş) route DEĞİL, ana sayfanın içinde bir
/// yığın indeksidir. Bu kapı olmadan geri jesti onları hiç görmez: çerçeve
/// poplanacak route bulamaz ve `SystemNavigator.pop` ile uygulamayı kapatır —
/// kullanıcı "bir seviye geri" derken uygulama launcher'a uçar (targetSdk 36
/// olduğu için predictive animasyonuyla birlikte).
///
/// [PopScope.canPop] false iken Flutter Android'e "geriyi ben hallediyorum"
/// der; hem çıkış engellenir hem o animasyon hiç başlamaz.
class CubeBackHandler extends StatelessWidget {
  const CubeBackHandler({
    super.key,
    required this.controller,
    required this.child,
  });

  final HomeNavigationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.viewStack,
      builder: (context, child) => PopScope(
        canPop: controller.isAtMainView,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          controller.closeToMain();
        },
        child: child!,
      ),
      child: child,
    );
  }
}
