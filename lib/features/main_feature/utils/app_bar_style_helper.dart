import 'package:flutter/material.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/helpers/slider_state_helper.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

class AppBarStyleHelper {
  /// Bir durumun (ayrık) üst çubuk rengi — [getAppBarColor]'ın uç değeri.
  ///
  /// Gölge rengi sürekli değerden türetilirse `AppBar`'ın KENDİSİ kare başına
  /// yeniden kurulur; oysa %30 opaklıktaki bir gölgenin lerp'lenmesiyle
  /// durumdan duruma atlaması ayırt edilemiyor.
  static Color getAppBarColorForState(SliderState state) => getAppBarColor(
        SliderStateHelper.getTargetValue(state, SliderState.values.length),
      );

  static Color getAppBarColor(double value) {
    if (value < 0.5) {
      return Color.lerp(
          AppColors.primaryGreen, AppColors.primaryBlue, value * 2)!;
    } else {
      return Color.lerp(
          AppColors.primaryBlue, AppColors.primaryRed, (value - 0.5) * 2)!;
    }
  }

  static List<Color> _getAppBarGradient(double value) {
    if (value < 0.5) {
      return [
        Color.lerp(Colors.green[400]!, Colors.blue[400]!, value * 2)!,
        Color.lerp(Colors.green[700]!, Colors.blue[700]!, value * 2)!,
        Color.lerp(Colors.green[900]!, Colors.blue[900]!, value * 2)!,
      ];
    } else {
      return [
        Color.lerp(Colors.blue[400]!, Colors.red[400]!, (value - 0.5) * 2)!,
        Color.lerp(Colors.blue[700]!, Colors.red[700]!, (value - 0.5) * 2)!,
        Color.lerp(Colors.blue[900]!, Colors.red[900]!, (value - 0.5) * 2)!,
      ];
    }
  }

  static BoxDecoration getAppbarDecoration(double currentValue) {
    final appBarColor = getAppBarColor(currentValue);

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _getAppBarGradient(currentValue),
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(AppBorderRadius.appBarBottom),
        bottomRight: Radius.circular(AppBorderRadius.appBarBottom),
      ),
      boxShadow: [
        BoxShadow(
          color: appBarColor.withValues(alpha: 0.4),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  /// Şekil kaydırıcı değerinden BAĞIMSIZ (eskiden gereksiz bir parametre
  /// alıyor ve hiç kullanmıyordu).
  static ShapeBorder getAppbarShape() {
    return const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(AppBorderRadius.appBarBottom),
        bottomRight: Radius.circular(AppBorderRadius.appBarBottom),
      ),
    );
  }
}
