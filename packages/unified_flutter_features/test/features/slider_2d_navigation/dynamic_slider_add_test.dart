import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/core/texts/slider_texts.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/dynamic_slider.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// '+' ve mini düğmeler ALT SAYFADA DA çalışır.
///
/// Eskiden yalnız ana başlık ortadayken açıktı: Rapor'a bakan kullanıcı
/// kaydırıcıya dokunduğunda hiçbir şey olmuyor, işlem eklemek için önce ana
/// görünüme dönmesi gerekiyordu.
void main() {
  // `ListWheelScrollView` içeride Scrollable'ın PRIVATE alt sınıfını kuruyor.
  final wheelFinder = find.byWidgetPredicate((w) => w is Scrollable);

  FixedExtentMetrics wheel(WidgetTester tester) =>
      tester.state<ScrollableState>(wheelFinder).position as FixedExtentMetrics;

  Future<_HostState> pump(
    WidgetTester tester, {
    bool withMiniButtons = true,
  }) async {
    await tester.pumpWidget(_Host(withMiniButtons: withMiniButtons));
    await tester.pumpAndSettle();
    return tester.state<_HostState>(find.byType(_Host));
  }

  /// Çarkı alt sayfaya (indeks 1) getirir — uygulamada dikey sürüklemenin
  /// oturduğu durum.
  Future<void> openSubView(WidgetTester tester) async {
    final position = tester.state<ScrollableState>(wheelFinder).position;
    position.jumpTo(wheel(tester).maxScrollExtent / 2);
    await tester.pumpAndSettle();
    expect(wheel(tester).itemIndex, 1);
  }

  testWidgets('ana başlıkta dokunuş mini düğmeleri açar', (tester) async {
    await pump(tester);

    // Ana başlık paketin varsayılan metniyle çizilir.
    await tester.tap(find.text(const SliderTexts().transactions).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Gider'), findsOneWidget);
    expect(find.text('Gelir'), findsOneWidget);
  });

  testWidgets('ALT SAYFADA ortadaki etikete dokunuş da mini düğmeleri açar',
      (tester) async {
    final host = await pump(tester);
    await openSubView(tester);

    expect(find.byIcon(Icons.add), findsOneWidget,
        reason: 'alt sayfada + rozeti gizlenmemeli');

    await tester.tap(find.text('İçgörü').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Gider'), findsOneWidget);
    expect(host.navigations, isEmpty,
        reason: 'ortadaki etikete dokunmak gezinme tetiklememeli');
    expect(host.stateTaps, 0, reason: 'ekleme eylemi alt sayfayı kapatmamalı');
  });

  testWidgets('alt sayfada mini düğmeye dokunmak eylemi çalıştırır',
      (tester) async {
    final host = await pump(tester);
    await openSubView(tester);

    await tester.tap(find.text('İçgörü').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gider'));
    await tester.pumpAndSettle();

    expect(host.actions, ['gider']);
    expect(find.text('Gider'), findsNothing, reason: 'katman kapanmalı');
  });

  testWidgets('mini düğmesi olmayan durumda + rozeti yok', (tester) async {
    await pump(tester, withMiniButtons: false);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}

class _Host extends StatefulWidget {
  const _Host({required this.withMiniButtons});

  final bool withMiniButtons;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    value: 0.5,
    duration: const Duration(milliseconds: 300),
  );

  final List<String> actions = [];
  final List<String> navigations = [];
  int stateTaps = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: DynamicSlider(
            controller: controller,
            onStateTap: (_) => stateTaps++,
            miniButtons: widget.withMiniButtons
                ? {
                    SliderState.transactions: [
                      MiniButtonData(
                        icon: Icons.arrow_circle_up,
                        label: 'Gelir',
                        color: Colors.green,
                        onTap: () => actions.add('gelir'),
                      ),
                      MiniButtonData(
                        icon: Icons.arrow_circle_down,
                        label: 'Gider',
                        color: Colors.red,
                        onTap: () => actions.add('gider'),
                      ),
                    ],
                  }
                : const {},
            subMenuItems: {
              SliderState.transactions: [
                SubMenuItem(
                  icon: Icons.insights,
                  label: 'İçgörü',
                  onTap: () => navigations.add('içgörü'),
                ),
                SubMenuItem(
                  icon: Icons.analytics,
                  label: 'Rapor',
                  onTap: () => navigations.add('rapor'),
                ),
              ],
            },
          ),
        ),
      ),
    );
  }
}
