import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/core/texts/slider_texts.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/constants/slider_config.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/dynamic_slider.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/widgets/slider_knob.dart';

/// Hap etiketi ÇÖZÜLEN puntoyla boyanır; sistem yazı ölçeği ikinci kez
/// uygulanmaz.
///
/// `SliderMetrics.fontSize` yazı ölçeğini zaten içerir (16 × ölçek, en çok
/// ×1,5) ve hapın genişliği o puntoya göre çözülür. `Text` ortamdaki ölçeği
/// bir kez DAHA uygularsa etiket hesaplanandan ×1,3–×1,5 büyük boyanır ve
/// kesilir: cihazda ölçek 2,0 iken hap "İşle…", altındaki etiket "İçg…"
/// yazıyordu (13 Eki 2026). `slider_metrics_test` yalnız hesabı ölçtüğü için
/// bunu görmüyordu; burada BOYANAN paragraf ölçülür.
void main() {
  Future<void> pump(WidgetTester tester, double scale) async {
    tester.view.physicalSize = const Size(411, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_Host(scale: scale));
    await tester.pumpAndSettle();
  }

  RenderParagraph inWheel(WidgetTester tester, String label) =>
      tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(ListWheelScrollView),
          matching: find.text(label),
        ),
      );

  for (final scale in const [1.0, 1.3, 1.5, 2.0]) {
    testWidgets('ölçek $scale: hap etiketi kesilmez', (tester) async {
      await pump(tester, scale);

      for (final label in const ['İşlemler', 'İçgörü']) {
        final paragraph = inWheel(tester, label);
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      }
    });

    testWidgets('ölçek $scale: boyanan satır = çözülen satır kutusu',
        (tester) async {
      await pump(tester, scale);

      // Çözülen ölçü (dar hapta punto küçültülmüş olabilir) widget'tan okunur.
      final metrics =
          tester.widget<SliderKnob>(find.byType(SliderKnob)).metrics;
      expect(
        inWheel(tester, 'İşlemler').size.height,
        closeTo(metrics.lineBox, 1.0),
        reason: 'Ölçek iki kez uygulanırsa satır kutusu bunun katı olur',
      );
      expect(metrics.textScale, lessThanOrEqualTo(SliderConfig.maxTextScale));
    });
  }
}

class _Host extends StatefulWidget {
  const _Host({required this.scale});

  final double scale;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 0.5,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(widget.scale)),
          child: Scaffold(
            body: Column(
              children: [
                const Spacer(),
                DynamicSlider(
                  controller: _controller,
                  texts: const SliderTexts(
                    savings: 'Birikim',
                    transactions: 'İşlemler',
                    debt: 'Borç',
                  ),
                  subMenuItems: {
                    SliderState.transactions: [
                      SubMenuItem(
                        icon: Icons.insights,
                        label: 'İçgörü',
                        onTap: () {},
                      ),
                      SubMenuItem(
                        icon: Icons.pie_chart,
                        label: 'Rapor',
                        onTap: () {},
                      ),
                    ],
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
