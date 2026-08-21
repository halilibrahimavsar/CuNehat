import 'package:cunehat/features/main_feature/utils/app_bar_style_helper.dart';
import 'package:flutter/material.dart';

/// Üst çubuğun kaydırıcıya bağlı gradyan zemini.
///
/// Kare başına yalnız BU ağaç yeniden kurulur; başlık tarafı ayrık duruma
/// bağlıdır (bkz. `SliderStateBuilder`).
///
/// **TUZAK — burada çocuksuz `DecoratedBox` KULLANILAMAZ.** `AppBar`,
/// `flexibleSpace`i `Stack(fit: StackFit.passthrough)` içine koyuyor
/// (`app_bar.dart:1198`), yani kısıtlar GEVŞEK geçiyor; çocuksuz bir
/// `RenderProxyBox` gevşek kısıtta `constraints.smallest`e, yani sıfır
/// yüksekliğe çöker. Ölçüldü: `DecoratedBox` → `Size(800, 0)`,
/// `Container` → `Size(800, 70)`. `Container` çocuksuz olduğunda kendini
/// `BoxConstraints.expand()` ile büyütmeyi zaten yapıyor; gradyan bir kez
/// bu yüzden görünmez oldu.
class AppBarBackground extends StatelessWidget {
  const AppBarBackground({super.key, required this.sliderAnimation});

  final Animation<double> sliderAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sliderAnimation,
      // `AnimatedContainer` DEĞİL: her karede yeni bir hedef aldığı için
      // gradyan parmağı takip etmek yerine 300 ms geriden geliyordu.
      builder: (context, _) => Container(
        decoration: AppBarStyleHelper.getAppbarDecoration(
          sliderAnimation.value,
        ),
      ),
    );
  }
}
