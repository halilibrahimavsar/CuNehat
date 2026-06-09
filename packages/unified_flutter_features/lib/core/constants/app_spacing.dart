import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // EdgeInsets shortcuts
  static const EdgeInsets xsAll = EdgeInsets.all(xs);
  static const EdgeInsets smallAll = EdgeInsets.all(small);
  static const EdgeInsets mediumAll = EdgeInsets.all(medium);
  static const EdgeInsets largeAll = EdgeInsets.all(large);
  static const EdgeInsets xlAll = EdgeInsets.all(xl);

  // Common combinations
  static const EdgeInsets horizontalMedium =
      EdgeInsets.symmetric(horizontal: medium);
  static const EdgeInsets verticalMedium =
      EdgeInsets.symmetric(vertical: medium);
  static const EdgeInsets horizontalSmall =
      EdgeInsets.symmetric(horizontal: small);
  static const EdgeInsets verticalSmall = EdgeInsets.symmetric(vertical: small);
}
