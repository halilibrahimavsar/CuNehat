import 'package:flutter/material.dart';

class SliderConfig {
  // Animation
  //
  // 380 ms denendi (Material'ın 300–500 ms aralığı gerekçesiyle) ve cihazda
  // fazla hızlı bulundu: küp geçişi o sürede okunmuyor. Kısaltma isteniyorsa
  // `kMainSettleDuration` ile BİRLİKTE değişmeli.
  static const animationDuration = Duration(milliseconds: 600);
  static const animationCurve = Curves.easeOutCubic;

  // Dimensions — TABAN değerler. Nihai ölçüler yazı ölçeğine göre
  // `SliderMetrics.resolve` içinde türetilir; bunlar alt sınırdır.
  static const sliderHeight = 100.0;
  static const knobHeight = 50.0;
  static const knobWidth = 130.0;
  static const trackPadding = 10.0;
  static const trackPaddingVertical = 25.0;
  static const trackRadius = 42.0;

  // Carousel
  //
  // `carouselItemHeight` artık SABİT DEĞİL: `SliderMetrics.itemExtent`
  // hesaplanır (hapla çakışmayacak, viewport'tan taşmayacak en küçük adım).
  // Eski `carouselTotalHeight` (=168) ölü koddu: çark `Positioned.fill` ile
  // sıkı 100 px alıyordu, o yüzden 168 hiçbir zaman uygulanmıyordu.

  /// Yazı ölçeği bunun üstüne çıkarsa kaydırıcı ekranın altını yemeye başlar.
  /// Kırpma yalnız kaydırıcıya özgüdür.
  static const maxTextScale = 1.5;

  /// Etiket puntosunun tabanı ve mutlak alt sınırı.
  static const knobLabelFontSize = 16.0;
  static const knobLabelMinFontSize = 11.0;

  /// `knobLabelStyle` artık AÇIK `height` taşıyor; taşımadığında Material 3'ün
  /// `bodyMedium`'undan `height: 1.43` miras alıyor ve satır kutusu 16 px'lik
  /// puntoda 23 px'e çıkıyordu (ölçüldü).
  static const knobLabelLineHeight = 1.08;

  /// Hapın alt kenarı ile komşu etiket arasındaki boşluk.
  static const knobLabelGap = 5.0;

  /// Knob genişliğinin parkur genişliğine oranı üst sınırı; daha genişi
  /// kaydırılacak yol bırakmaz.
  static const knobWidthTrackShare = 0.5;

  /// Kaydırıcının üst/alt nefes payı.
  static const sliderVerticalSlack = 8.0;

  /// Odak bandının satır kutusunun ötesine taşan payı ve yumuşama genişliği.
  static const focusBandPadding = 3.0;
  static const focusBandFeather = 0.06;

  // Mini buttons
  static const miniButtonSize = 40.0;
  static const miniButtonDistance = 76.0;
  static const miniButtonSpread = 0.9;

  // Arrow positioning (yalnız YATAY oklar; dikey chevron'lar yığın
  // göstergesiyle değiştirildi — komşu etiketle çakışıyorlardı).
  static const arrowOffsetHorizontal = 18.0;
  static const arrowSize = 18.0;
  static const arrowAlpha = 0.95;

  // Dikey yığın göstergesi (hapın sağ iç kenarında nokta rayı)
  static const stackIndicatorInset = 7.0;
  static const stackIndicatorDotSize = 4.0;
  static const stackIndicatorActiveLength = 11.0;
  static const stackIndicatorGap = 4.0;

  /// Göstergenin kapladığı yer etiketin iki yanından SİMETRİK ayrılır ki
  /// etiket hapın ortasında kalsın.
  static const knobLabelPaddingH = 18.0;

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
    fontSize: knobLabelFontSize,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.6,
    height: knobLabelLineHeight,
  );
  static const knobLabelFontSizeDragging = 12;
  static const knobLabelFontSizeNormal = 10;
  static const shadowColorBlack26 = Colors.black26;
  static const shadowBlurSmall = 2.0;
}
