import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/core/texts/slider_texts.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/dynamic_slider.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/helpers/slider_state_helper.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/widgets/slider_knob.dart';

/// Kaydırıcı yalnız ETKİN durumlar arasında gezer.
///
/// Uygulamada Birikim ve Borç bölümleri kullandıkça açılıyor. Kapalı bir
/// bölümün düğmesi çizilmemeli, knob oraya sürüklenememeli, fiske oraya
/// oturtamamalı — ama denetleyicinin değer ekseni DEĞİŞMEMELİ: İşlemler her
/// koşulda 0,5'te kalır, yoksa bölüm sonradan açıldığında sayfalar yer
/// değiştirir.
void main() {
  SliderState stateOf(AnimationController c) =>
      SliderStateHelper.getStateFromValue(c.value, SliderState.values.length);

  const transactionsAndDebt = {SliderState.transactions, SliderState.debt};
  const savingsAndTransactions = {
    SliderState.savedMoney,
    SliderState.transactions,
  };

  Future<AnimationController> pump(
    WidgetTester tester, {
    required Set<SliderState> enabled,
    double initial = 0.5,
  }) async {
    late AnimationController controller;
    await tester.pumpWidget(
      _Host(
        enabledStates: enabled,
        initial: initial,
        onReady: (c) => controller = c,
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  group('çizim', () {
    testWidgets('kapalı durumun bölümü çizilmez', (tester) async {
      await pump(tester, enabled: transactionsAndDebt);

      expect(find.text('BİRİKİM'), findsNothing);
      expect(find.text('BORÇ'), findsOneWidget);
    });

    testWidgets('varsayılan: üç durum da çizilir', (tester) async {
      late AnimationController controller;
      await tester.pumpWidget(
        _Host(onReady: (c) => controller = c),
      );
      await tester.pumpAndSettle();

      expect(find.text('BİRİKİM'), findsOneWidget);
      expect(find.text('BORÇ'), findsOneWidget);
      expect(controller.value, 0.5);
    });

    testWidgets('iki durumda bölümler parkuru YARI yarıya paylaşır',
        (tester) async {
      await pump(tester, enabled: transactionsAndDebt);

      final track = tester.getSize(find.byType(DynamicSlider)).width;
      // Etkin durumun etiketi knob'da çizilir; öteki bölüm kendi yarısının
      // ortasında durur (üç durumda bu, parkurun 5/6'sı olurdu).
      final debt = tester.getCenter(find.text('BORÇ')).dx;
      final left = tester.getTopLeft(find.byType(DynamicSlider)).dx;
      expect(debt - left, closeTo(track * 0.75, 1.0));
    });

    testWidgets('etkin aralık parkurun tamamına yayılır: knob uçtan uca gider',
        (tester) async {
      final controller = await pump(tester, enabled: transactionsAndDebt);
      final knob = find.byType(SliderKnob);
      final slider = find.byType(DynamicSlider);

      // İşlemler (0,5) aralığın BAŞI: knob sol uçta.
      final atStart = tester.getCenter(knob).dx;
      expect(
        atStart,
        lessThan(tester.getCenter(slider).dx),
        reason: 'İşlemler iki durumlu aralığın ilk durağı; knob solda olmalı',
      );

      controller.value = 1.0;
      await tester.pumpAndSettle();
      final atEnd = tester.getCenter(knob).dx;

      final trackWidth = tester.getSize(slider).width;
      final knobWidth = tester.getSize(knob).width;
      expect(atEnd - atStart, closeTo(trackWidth - knobWidth, 1.0));
    });
  });

  group('sürükleme', () {
    testWidgets('knob kapalı duruma doğru sürüklenemez (alt uç)',
        (tester) async {
      final controller = await pump(tester, enabled: transactionsAndDebt);

      await tester.drag(find.byType(SliderKnob), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(controller.value, 0.5);
      expect(stateOf(controller), SliderState.transactions);
    });

    testWidgets('knob kapalı duruma doğru sürüklenemez (üst uç)',
        (tester) async {
      final controller = await pump(tester, enabled: savingsAndTransactions);

      await tester.drag(find.byType(SliderKnob), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(controller.value, 0.5);
      expect(stateOf(controller), SliderState.transactions);
    });

    testWidgets('uçtan uca sürükleme öteki etkin duruma götürür',
        (tester) async {
      final controller = await pump(tester, enabled: transactionsAndDebt);
      final travel = tester.getSize(find.byType(DynamicSlider)).width -
          tester.getSize(find.byType(SliderKnob)).width;

      await tester.drag(find.byType(SliderKnob), Offset(travel, 0));
      await tester.pumpAndSettle();

      expect(controller.value, closeTo(1.0, 0.001));
      expect(stateOf(controller), SliderState.debt);
    });

    testWidgets('yarı yoldan az sürükleme geri yaslanır', (tester) async {
      final controller = await pump(tester, enabled: transactionsAndDebt);

      await tester.drag(find.byType(SliderKnob), const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(controller.value, closeTo(0.5, 0.001));
    });

    testWidgets('fiske kapalı duruma OTURTAMAZ', (tester) async {
      final controller = await pump(tester, enabled: transactionsAndDebt);

      await tester.fling(find.byType(SliderKnob), const Offset(-60, 0), 4000);
      await tester.pumpAndSettle();

      expect(controller.value, closeTo(0.5, 0.001));
      expect(stateOf(controller), SliderState.transactions);
    });

    testWidgets('fiske etkin komşuya geçirir', (tester) async {
      final controller = await pump(tester, enabled: savingsAndTransactions);

      await tester.fling(find.byType(SliderKnob), const Offset(-60, 0), 2500);
      await tester.pumpAndSettle();

      expect(controller.value, closeTo(0.0, 0.001));
      expect(stateOf(controller), SliderState.savedMoney);
    });
  });

  group('dokunma', () {
    testWidgets('etkin bölüme dokunmak ona götürür', (tester) async {
      final controller = await pump(tester, enabled: transactionsAndDebt);

      await tester.tap(find.text('BORÇ'));
      await tester.pumpAndSettle();

      expect(controller.value, closeTo(1.0, 0.001));
    });
  });

  group('eksen sabit kalır', () {
    testWidgets(
        'İşlemler iki durumda da üç durumda da 0,5: bölüm açılınca değer '
        'değişmez', (tester) async {
      final controller = await pump(tester, enabled: transactionsAndDebt);
      expect(controller.value, 0.5);

      // Birikim sonradan açıldı.
      await tester.pumpWidget(
        _Host(onReady: (_) {}, controller: controller),
      );
      await tester.pumpAndSettle();

      expect(controller.value, 0.5);
      expect(stateOf(controller), SliderState.transactions);
      expect(find.text('BİRİKİM'), findsOneWidget);
    });
  });

  group('yön okları', () {
    Finder arrow(IconData icon) => find.descendant(
          of: find.byType(SliderKnob),
          matching: find.byIcon(icon),
        );

    double opacityOf(WidgetTester tester, Finder icon) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(of: icon, matching: find.byType(AnimatedOpacity)).first,
        )
        .opacity;

    testWidgets('aralığın başında sola ok gösterilmez', (tester) async {
      await pump(tester, enabled: transactionsAndDebt);

      expect(opacityOf(tester, arrow(Icons.arrow_back_ios)), 0.0);
      expect(opacityOf(tester, arrow(Icons.arrow_forward_ios)), 1.0);
    });

    testWidgets('aralığın sonunda sağa ok gösterilmez', (tester) async {
      await pump(tester, enabled: savingsAndTransactions);

      expect(opacityOf(tester, arrow(Icons.arrow_back_ios)), 1.0);
      expect(opacityOf(tester, arrow(Icons.arrow_forward_ios)), 0.0);
    });
  });
}

class _Host extends StatefulWidget {
  const _Host({
    required this.onReady,
    this.enabledStates,
    this.initial = 0.5,
    this.controller,
  });

  final void Function(AnimationController) onReady;
  final Set<SliderState>? enabledStates;
  final double initial;

  /// Verilirse host yeni denetleyici KURMAZ (aynı denetleyiciyle yeniden
  /// pompalama: "bölüm sonradan açıldı").
  final AnimationController? controller;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  AnimationController? _own;

  AnimationController get controller => widget.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _own = AnimationController(
        vsync: this,
        value: widget.initial,
        duration: const Duration(milliseconds: 300),
      );
    }
    widget.onReady(controller);
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabledStates;
    const texts = SliderTexts(
      savings: 'BİRİKİM',
      transactions: 'İŞLEMLER',
      debt: 'BORÇ',
    );
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const Spacer(),
            if (enabled == null)
              DynamicSlider(controller: controller, texts: texts)
            else
              DynamicSlider(
                controller: controller,
                texts: texts,
                enabledStates: enabled,
              ),
          ],
        ),
      ),
    );
  }
}
