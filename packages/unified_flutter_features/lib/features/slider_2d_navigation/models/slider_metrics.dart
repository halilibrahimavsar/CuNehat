import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/slider_config.dart';

/// Kaydırıcının ölçüleri: sabit sayılar yerine sistem yazı ölçeğinden türetilir.
///
/// Sabit `itemExtent` (42) + sabit yükseklik (100) + sabit knob genişliği (130)
/// üçlüsü ölçülerek bulunan üç ayrı kusurun ortak köküydü:
///
/// * **Komşu öğe viewport kenarında kesiliyordu.** Merkez y=H/2, sonraki öğenin
///   kutusu y=H/2+42'de; `ListWheelScrollView` varsayılan olarak `Clip.hardEdge`
///   uyguluyor. Ölçülen kesilme: x1.0'da 4,7 px (satırın %20'si), x2.0'da
///   17,6 px (%42).
/// * **Ana etiket ellipsis'e düşüyordu.** Yuva 130−16=114 px; gerçek Roboto
///   Black 16 px ile `İŞLEMLER` x1.8'de 129 px, `TRANSACTIONS` daha x1.0'da
///   tam 114 px.
/// * **ShaderMask'in beyaz odak bandı satır kutusundan dardı** (16 px'e karşı
///   23 px): `İ`nin noktası ve `Ş`nin çengeli banttan taşıp griye düşüyordu.
///
/// Buradaki kural şu: **komşu etiket ne hapla çakışır ne de viewport'tan taşar.**
///
/// ```
///   H/2 + itemExtent − lineBox/2  ≥  H/2 + knobHeight/2   (hapla çakışma yok)
///   H/2 + itemExtent + lineBox/2  ≤  H                     (kesilme yok)
/// ```
@immutable
class SliderMetrics {
  const SliderMetrics({
    required this.textScale,
    required this.fontSize,
    required this.lineBox,
    required this.itemExtent,
    required this.sliderHeight,
    required this.knobHeight,
    required this.knobWidth,
    required this.labelStyle,
  });

  /// Kırpılmış yazı ölçeği (bkz. [SliderConfig.maxTextScale]).
  final double textScale;

  /// Etiketlerin nihai punto değeri; hiçbir etiket sığmıyorsa küçültülmüştür.
  final double fontSize;

  /// Etiketlerin NİHAİ stili — ölçüm de boyama da bunu kullanır.
  ///
  /// Ortamdaki `DefaultTextStyle` ile birleştirilmiş olması şart: aksi halde
  /// `TextPainter` çıplak bir `TextSpan`'i platform varsayılan fontuyla
  /// ölçerken `Text` ortamdaki aileyle boyar ve ikisi sessizce ayrışır.
  final TextStyle labelStyle;

  /// Tek satırın kapladığı yükseklik ([SliderConfig.knobLabelLineHeight] ile).
  final double lineBox;

  /// Çarkın öğe adımı. Merkez etiket ile komşu etiket arasındaki mesafe.
  final double itemExtent;

  /// Kaydırıcının toplam yüksekliği.
  final double sliderHeight;

  /// Renkli hapın yüksekliği.
  final double knobHeight;

  /// Renkli hapın genişliği; en uzun etikete göre büyür.
  final double knobWidth;

  /// ShaderMask'in duraklarını üretir: beyaz bant tam olarak merkezdeki satır
  /// kutusunu kaplar, komşular dışarıda kalır.
  List<double> get focusStops {
    final half = (lineBox / 2 + SliderConfig.focusBandPadding) / sliderHeight;
    const feather = SliderConfig.focusBandFeather;
    return <double>[
      0.0,
      (0.5 - half - feather).clamp(0.0, 1.0),
      (0.5 - half).clamp(0.0, 1.0),
      (0.5 + half).clamp(0.0, 1.0),
      (0.5 + half + feather).clamp(0.0, 1.0),
      1.0,
    ];
  }

  /// [labels] içindeki en uzun etikete ve [trackWidth]'e göre ölçüleri çözer.
  ///
  /// Yazı ölçeği `SliderConfig.maxTextScale` ile kırpılır: kırpılmazsa
  /// kaydırıcı x2.0'da ekranın altını yer. Kırpma yalnız bu widget'a özgüdür;
  /// uygulamanın geri kalanı sistem ölçeğini olduğu gibi kullanır.
  static SliderMetrics resolve({
    required BuildContext context,
    required Iterable<String> labels,
    required double trackWidth,
  }) {
    final scale = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: SliderConfig.maxTextScale)
        .scale(1.0);

    // Ölçüm ile boyamanın aynı fontu kullanması için ortamdaki stille
    // birleştir: `knobLabelStyle` aile taşımıyor, aileyi tema veriyor.
    final baseStyle =
        DefaultTextStyle.of(context).style.merge(SliderConfig.knobLabelStyle);

    var fontSize = SliderConfig.knobLabelFontSize * scale;

    // Knob genişliği en uzun etikete göre büyür; ama parkurun yarısını
    // geçemez, yoksa kaydırılacak yol kalmaz.
    final maxKnobWidth = trackWidth * SliderConfig.knobWidthTrackShare;
    var widest = _widest(labels, baseStyle, fontSize);
    final knobWidth = (widest + 2 * SliderConfig.knobLabelPaddingH)
        .clamp(
          SliderConfig.knobWidth,
          math.max(SliderConfig.knobWidth, maxKnobWidth),
        )
        .toDouble();

    // Genişlik sınırına rağmen sığmayan etiket varsa punto küçültülür.
    //
    // Sözleşme: **punto ≥ [SliderConfig.knobLabelMinFontSize] iken sığdırmak
    // mümkünse etiket kesilmez.** Tabana inildiği hâlde sığmıyorsa (çok uzun
    // etiket + dar ekran) okunabilirlik kesilmemeye tercih edilir ve `Text`in
    // ellipsis'i devreye girer.
    //
    // letterSpacing puntoyla ölçeklenmediği için tek adım yetmez; oran
    // her turda 1'e yaklaştığından döngü hızla yakınsar.
    final available = knobWidth - 2 * SliderConfig.knobLabelPaddingH;
    for (var i = 0; i < 8 && widest > available; i++) {
      final shrunk = (fontSize * available / widest)
          .clamp(SliderConfig.knobLabelMinFontSize, fontSize)
          .toDouble();
      if (shrunk == fontSize) break; // daha fazla küçülemiyor
      fontSize = shrunk;
      widest = _widest(labels, baseStyle, fontSize);
    }

    final lineBox = fontSize * SliderConfig.knobLabelLineHeight;
    final knobHeight = math.max(SliderConfig.knobHeight, lineBox * 2.0);

    // Komşu etiket hapın altından başlasın (gap) ve viewport'a sığsın.
    final itemExtent = knobHeight / 2 + lineBox / 2 + SliderConfig.knobLabelGap;
    final sliderHeight = math.max(
      SliderConfig.sliderHeight,
      (itemExtent + lineBox / 2) * 2 + SliderConfig.sliderVerticalSlack,
    );

    return SliderMetrics(
      textScale: scale,
      fontSize: fontSize,
      lineBox: lineBox,
      itemExtent: itemExtent,
      sliderHeight: sliderHeight,
      knobHeight: knobHeight,
      knobWidth: knobWidth,
      labelStyle: baseStyle.copyWith(fontSize: fontSize),
    );
  }

  static double _widest(
    Iterable<String> labels,
    TextStyle baseStyle,
    double fontSize,
  ) {
    final style = baseStyle.copyWith(fontSize: fontSize);
    var widest = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return widest;
  }

  @override
  bool operator ==(Object other) =>
      other is SliderMetrics &&
      other.textScale == textScale &&
      other.fontSize == fontSize &&
      other.itemExtent == itemExtent &&
      other.sliderHeight == sliderHeight &&
      other.knobHeight == knobHeight &&
      other.knobWidth == knobWidth;

  @override
  int get hashCode => Object.hash(
      textScale, fontSize, itemExtent, sliderHeight, knobHeight, knobWidth);
}
