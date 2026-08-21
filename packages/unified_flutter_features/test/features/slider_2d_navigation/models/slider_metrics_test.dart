import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/constants/slider_config.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_metrics.dart';

/// Sabit 100/50/130/42 dörtlüsü üç kusur üretiyordu (hepsi ölçüldü):
/// komşu etiket viewport kenarında kesiliyordu, ana etiket ellipsis'e
/// düşüyordu, ShaderMask'in beyaz bandı satır kutusundan dardı.
///
/// Bu testler o üç kusurun geri gelmesini engelleyen değişmezleri tutar.
void main() {
  const trLabels = ['BİRİKİM', 'İŞLEMLER', 'BORÇ', 'Detay', 'Rapor', 'Geçmiş'];
  const enLabels = [
    'SAVINGS',
    'TRANSACTIONS',
    'DEBT',
    'Details',
    'Report',
    'History',
  ];

  Future<SliderMetrics> resolve(
    WidgetTester tester, {
    required List<String> labels,
    required double scale,
    required double trackWidth,
  }) async {
    late SliderMetrics metrics;
    // `Scaffold` ŞART: ortam metin stili `Material`'dan geliyor. Onsuz
    // `DefaultTextStyle` hata-ayıklama fontuna (monospace) düşer ve ölçüm
    // gerçek yerleşimi temsil etmez.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: Builder(builder: (inner) {
              metrics = SliderMetrics.resolve(
                context: inner,
                labels: labels,
                trackWidth: trackWidth,
              );
              return const SizedBox();
            }),
          );
        }),
      ),
    ));
    return metrics;
  }

  const scales = [1.0, 1.15, 1.3, 1.5, 1.8, 2.0, 2.5];
  const trackWidths = [304.0, 344.0, 395.0, 464.0]; // 320/360/411/480 dp − 16

  for (final labels in [trLabels, enLabels]) {
    final locale = identical(labels, trLabels) ? 'TR' : 'EN';

    testWidgets('$locale — komşu etiket hapla çakışmaz', (tester) async {
      for (final scale in scales) {
        for (final width in trackWidths) {
          final m = await resolve(tester,
              labels: labels, scale: scale, trackWidth: width);
          final neighbourTop =
              m.sliderHeight / 2 + m.itemExtent - m.lineBox / 2;
          final pillBottom = m.sliderHeight / 2 + m.knobHeight / 2;
          expect(neighbourTop, greaterThanOrEqualTo(pillBottom),
              reason:
                  'scale=$scale width=$width — etiket hapın üstüne biniyor');
        }
      }
    });

    testWidgets('$locale — komşu etiket viewport dışına taşmaz',
        (tester) async {
      for (final scale in scales) {
        for (final width in trackWidths) {
          final m = await resolve(tester,
              labels: labels, scale: scale, trackWidth: width);
          final neighbourBottom =
              m.sliderHeight / 2 + m.itemExtent + m.lineBox / 2;
          expect(neighbourBottom, lessThanOrEqualTo(m.sliderHeight),
              reason: 'scale=$scale width=$width — etiketin altı kesiliyor');
        }
      }
    });

    testWidgets('$locale — punto tabana inmeden hiçbir etiket kesilmez',
        (tester) async {
      // Sözleşme: punto ≥ minFontSize iken sığdırmak mümkünse kesilme yok.
      // Tabana rağmen sığmıyorsa (çok uzun etiket + dar ekran) okunabilirlik
      // kesilmemeye tercih edilir — o durumda puntonun gerçekten tabanda
      // olduğunu doğruluyoruz, "pes edildi" diye sessizce geçmiyoruz.
      for (final scale in scales) {
        for (final width in trackWidths) {
          final m = await resolve(tester,
              labels: labels, scale: scale, trackWidth: width);
          final available = m.knobWidth - 2 * SliderConfig.knobLabelPaddingH;
          for (final label in labels) {
            final painter = TextPainter(
              text: TextSpan(text: label, style: m.labelStyle),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            final fits = painter.width <= available + 0.5;
            expect(
                fits || m.fontSize == SliderConfig.knobLabelMinFontSize, isTrue,
                reason: '"$label" scale=$scale width=$width — ne sığıyor '
                    'ne de punto tabana indirilmiş (${m.fontSize})');
            painter.dispose();
          }
        }
      }
    });

    testWidgets('$locale — odak bandı satır kutusunu tam kapsar',
        (tester) async {
      for (final scale in scales) {
        final m = await resolve(tester,
            labels: labels, scale: scale, trackWidth: 344);
        final stops = m.focusStops;
        final bandTop = stops[2] * m.sliderHeight;
        final bandBottom = stops[3] * m.sliderHeight;
        final textTop = m.sliderHeight / 2 - m.lineBox / 2;
        final textBottom = m.sliderHeight / 2 + m.lineBox / 2;
        expect(bandTop, lessThanOrEqualTo(textTop),
            reason: 'scale=$scale — satırın üstü griye düşüyor');
        expect(bandBottom, greaterThanOrEqualTo(textBottom),
            reason: 'scale=$scale — satırın altı griye düşüyor');
      }
    });
  }

  testWidgets('TR etiketleri hiçbir ekran/ölçek birleşiminde kesilmez',
      (tester) async {
    // Uygulamanın gönderdiği etiket kümesi bu; burada ellipsis KABUL EDİLMEZ.
    for (final scale in scales) {
      for (final width in trackWidths) {
        final m = await resolve(tester,
            labels: trLabels, scale: scale, trackWidth: width);
        final available = m.knobWidth - 2 * SliderConfig.knobLabelPaddingH;
        for (final label in trLabels) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: m.labelStyle),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          expect(painter.width, lessThanOrEqualTo(available + 0.5),
              reason: '"$label" scale=$scale width=$width');
          painter.dispose();
        }
      }
    }
  });

  testWidgets('lineBox gerçekten boyanan satır kutusuna eşittir',
      (tester) async {
    // Tüm geometri bu varsayıma dayanıyor: `TextStyle.height` verildiğinde
    // satır kutusu font metriklerinden DEĞİL, fontSize*height'tan gelir.
    for (final scale in scales) {
      final m = await resolve(tester,
          labels: trLabels, scale: scale, trackWidth: 344);
      for (final label in [...trLabels, 'Ğğ']) {
        final painter = TextPainter(
          text: TextSpan(text: label, style: m.labelStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        expect(painter.height, closeTo(m.lineBox, 0.5),
            reason: '"$label" scale=$scale');
        painter.dispose();
      }
    }
  });

  testWidgets('ölçüm ortamdaki font ailesini kullanır', (tester) async {
    // `knobLabelStyle` aile taşımıyor; aileyi tema veriyor. Ölçüm çıplak bir
    // `TextSpan` kullansaydı platform varsayılanıyla ölçer, `Text` ise tema
    // ailesiyle boyardı — ikisi sessizce ayrışırdı.
    late SliderMetrics metrics;
    late TextStyle ambient;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'SahteAile'),
      home: Scaffold(
        body: Builder(builder: (context) {
          ambient = DefaultTextStyle.of(context).style;
          metrics = SliderMetrics.resolve(
            context: context,
            labels: trLabels,
            trackWidth: 344,
          );
          return const SizedBox();
        }),
      ),
    ));

    expect(ambient.fontFamily, 'SahteAile');
    expect(metrics.labelStyle.fontFamily, 'SahteAile');
    // Stilin kendi alanları temanınkini ezmeli.
    expect(metrics.labelStyle.fontWeight, FontWeight.w900);
    expect(metrics.labelStyle.height, SliderConfig.knobLabelLineHeight);
  });

  testWidgets('yazı ölçeği kırpılır; kaydırıcı ekranı yutmaz', (tester) async {
    final m =
        await resolve(tester, labels: trLabels, scale: 3.0, trackWidth: 344);
    expect(m.textScale, SliderConfig.maxTextScale);
    expect(m.sliderHeight, lessThan(SliderConfig.sliderHeight * 1.5));
  });

  testWidgets('knob parkurun yarısından geniş olmaz', (tester) async {
    for (final width in trackWidths) {
      final m = await resolve(tester,
          labels: enLabels, scale: 2.0, trackWidth: width);
      expect(m.knobWidth,
          lessThanOrEqualTo(width * SliderConfig.knobWidthTrackShare + 0.5));
    }
  });

  testWidgets('ölçüler durumlar arası sabittir (knob boy değiştirmez)',
      (tester) async {
    // Etiket kümesi TÜM durumları kapsadığı için knob genişliği kaydırıcı
    // hareket ederken değişmemeli.
    final all =
        await resolve(tester, labels: trLabels, scale: 1.0, trackWidth: 344);
    final onlyOne =
        await resolve(tester, labels: ['BORÇ'], scale: 1.0, trackWidth: 344);
    expect(all.knobWidth, greaterThanOrEqualTo(onlyOne.knobWidth));
  });
}
