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

  /// [value]'nun İşlemler durumuna (0,5) yakınlığı: tam üstünde 1, komşu
  /// durumlarda (0 = Birikim, 1 = Borç) 0.
  static double transactionsProximity(double value) =>
      (1 - (value - 0.5).abs() * 2).clamp(0.0, 1.0);

  /// Çubuğun zemini. [cardColors] verilirse ve [cardFactor] > 0 ise zemin,
  /// İşlemler durumuna yakınlık ölçüsünde o kartın rengine harmanlanır
  /// (bkz. `AppBarBackground`): Birikim ve Borç hesabın verisidir, orada
  /// kart rengi YOKTUR.
  static BoxDecoration getAppbarDecoration(
    double currentValue, {
    List<Color>? cardColors,
    double cardFactor = 0,
  }) {
    var appBarColor = getAppBarColor(currentValue);
    var gradient = _getAppBarGradient(currentValue);

    final blend = cardColors == null || cardColors.isEmpty
        ? 0.0
        : cardFactor * transactionsProximity(currentValue);
    if (blend > 0) {
      final from = cardColors!.first;
      final to = cardColors.last;
      gradient = [
        for (var i = 0; i < gradient.length; i++)
          Color.lerp(
            gradient[i],
            Color.lerp(from, to, i / (gradient.length - 1)),
            blend,
          )!,
      ];
      appBarColor = Color.lerp(appBarColor, from, blend)!;
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient,
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
