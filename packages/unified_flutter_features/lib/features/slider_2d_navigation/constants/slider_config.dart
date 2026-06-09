import 'package:flutter/material.dart';

class SliderConfig {
  // Animation
  static const animationDuration = Duration(milliseconds: 600);
  static const animationCurve = Curves.easeOutCubic;

  // Dimensions
  static const sliderHeight = 100.0;
  static const knobHeight = 50.0;
  static const knobWidth = 130.0;
  static const trackPadding = 10.0;
  static const trackPaddingVertical = 25.0;
  static const trackRadius = 42.0;

  // Carousel
  static const carouselItemHeight = 42.0;
  static const carouselTotalHeight = carouselItemHeight * 4;

  // Mini buttons
  static const miniButtonSize = 40.0;
  static const miniButtonDistance = 76.0;
  static const miniButtonSpread = 0.9;

  // Arrow positioning
  static const arrowOffsetHorizontal = 14.0;
  static const arrowOffsetUp = 18.0;
  static const arrowOffsetDown = 16.0;
  static const arrowSize = 12.0;
  static const arrowSizeVertical = 22.0;
  static const arrowAlpha = 0.6;

  // Plus icon
  static const plusIconWidth = 30.0;
  static const plusIconHeight = 24.0;
  static const plusIconSize = 20.0;
  static const plusIconCornerRadius = 12.0;

  // Glass effect
  static const glassBlurSigma = 5.0;
  static const glassAlpha = 0.2;
  static const glassBorderAlpha = 0.3;
  static const glassBorderWidth = 1.5;

  // Knob animation
  static const knobAnimationDuration = 200;
  static const knobShadowBlur = 10.0;
  static const knobShadowBlurActive = 20.0;
  static const knobShadowOffset = 6.0;
  static const knobShadowAlpha = 0.6;

  // Mini button layout
  static const miniButtonLayoutWidth = 70.0;
  static const miniButtonLayoutHeight = 80.0;
  static const miniButtonLabelSpacing = 6.0;
  static const miniButtonLabelPaddingH = 6.0;
  static const miniButtonLabelPaddingV = 2.0;
  static const miniButtonLabelCornerRadius = 8.0;
  static const miniButtonLabelFontSize = 11.0;
  static const miniButtonIconSize = 24.0;
  static const miniButtonShadowBlur = 15.0;
  static const miniButtonShadowAlpha = 0.4;
  static const miniButtonShadowOffset = 5.0;
  static const miniButtonGradientAlpha = 0.7;
  static const miniButtonBlurAlpha = 0.1;
  static const miniButtonBlurRadius = 4.0;

  // Slider positioning
  static const knobPositionOffset = 8.0;
  static const sliderValueThresholdLeft = 0.5;
  static const sliderValueThresholdRight = 0.5;
  static const sliderAnimationDuration = 300;
  static const carouselAnimationDuration = 300;

  // Values
  static const miniButtonDistanceMultiplier = 0.7;
  static const transitionThresholdLow = 0.3;
  static const shadowAlpha = 0.15;
  static const shadowBlurRadius = 4.0;
  static const shadowOffsetY = 2.0;

  // Styles
  static const knobLabelStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.6,
  );
  static const knobLabelFontSizeDragging = 12;
  static const knobLabelFontSizeNormal = 10;
  static const shadowColorBlack26 = Colors.black26;
  static const shadowBlurSmall = 2.0;
}
