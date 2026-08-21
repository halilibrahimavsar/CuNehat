import 'package:cunehat/features/main_feature/utils/app_bar_style_helper.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBarStyleHelper', () {
    test('getAppBarColor returns correct color based on slider value', () {
      // At 0.0 (fully left/saved money), it should be primaryGreen
      expect(AppBarStyleHelper.getAppBarColor(0.0), AppColors.primaryGreen);

      // At 0.5 (center/transactions), it should be primaryBlue
      expect(AppBarStyleHelper.getAppBarColor(0.5), AppColors.primaryBlue);

      // At 1.0 (fully right/debt), it should be primaryRed
      expect(AppBarStyleHelper.getAppBarColor(1.0), AppColors.primaryRed);

      // Lerp checks
      final greenBlueLerp =
          Color.lerp(AppColors.primaryGreen, AppColors.primaryBlue, 0.5);
      expect(AppBarStyleHelper.getAppBarColor(0.25), greenBlueLerp);

      final blueRedLerp =
          Color.lerp(AppColors.primaryBlue, AppColors.primaryRed, 0.5);
      expect(AppBarStyleHelper.getAppBarColor(0.75), blueRedLerp);
    });

    test(
        'getAppbarDecoration returns decoration with linear gradient and correct properties',
        () {
      final decoration = AppBarStyleHelper.getAppbarDecoration(0.5);

      expect(decoration.gradient, isA<LinearGradient>());
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.begin, Alignment.topLeft);
      expect(gradient.end, Alignment.bottomRight);
      expect(gradient.colors.length, 3);

      // At 0.5, the gradient should be pure Blue shades
      expect(gradient.colors[0], Colors.blue[400]);
      expect(gradient.colors[1], Colors.blue[700]);
      expect(gradient.colors[2], Colors.blue[900]);

      // Border radius check
      expect(
          decoration.borderRadius,
          const BorderRadius.only(
            bottomLeft: Radius.circular(AppBorderRadius.appBarBottom),
            bottomRight: Radius.circular(AppBorderRadius.appBarBottom),
          ));

      // Box shadow check
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, 1);
      expect(decoration.boxShadow![0].blurRadius, 15);
      expect(decoration.boxShadow![0].offset, const Offset(0, 5));
    });

    test(
        'getAppbarShape returns RoundedRectangleBorder with correct border radius',
        () {
      final shape = AppBarStyleHelper.getAppbarShape();
      expect(shape, isA<RoundedRectangleBorder>());

      final border = shape as RoundedRectangleBorder;
      expect(
          border.borderRadius,
          const BorderRadius.only(
            bottomLeft: Radius.circular(AppBorderRadius.appBarBottom),
            bottomRight: Radius.circular(AppBorderRadius.appBarBottom),
          ));
    });
  });
}
