import 'dart:async';

import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:cunehat/features/main_feature/widgets/main_content_swipe.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Bu jest eklenene kadar `lib` içinde tek bir `onHorizontalDrag` yoktu:
/// sayfalar arası geçmenin tek yolu alttaki 130×100 px'lik knob'du.
void main() {
  Future<HomeNavigationController> pump(
    WidgetTester tester, {
    Widget? content,
    List<Widget> subViews = const [],
    bool renderStack = true,
  }) async {
    late HomeNavigationController controller;
    await tester.pumpWidget(MaterialApp(
      home: _Host(
        content: content,
        subViews: subViews,
        renderStack: renderStack,
        onReady: (c) => controller = c,
      ),
    ));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('içeriği sola sürüklemek sonraki sayfaya geçirir',
      (tester) async {
    final controller = await pump(tester);
    expect(controller.currentSliderState, SliderState.transactions);

    await tester.drag(find.byKey(const Key('icerik')), const Offset(-width, 0));
    await tester.pumpAndSettle();

    expect(controller.currentSliderState, SliderState.debt);
    expect(controller.horizontalController.value, closeTo(1.0, 0.001));
  });

  testWidgets('içeriği sağa sürüklemek önceki sayfaya geçirir', (tester) async {
    final controller = await pump(tester);

    await tester.drag(find.byKey(const Key('icerik')), const Offset(width, 0));
    await tester.pumpAndSettle();

    expect(controller.currentSliderState, SliderState.savedMoney);
    expect(controller.horizontalController.value, closeTo(0.0, 0.001));
  });

  testWidgets('bir ekran genişliği tam bir sayfa eder (parmakla 1:1)',
      (tester) async {
    final controller = await pump(tester);

    // Yarım ekran = yarım sayfa: sınır (0.25/0.75) geçilir ama tam bir
    // sayfadan azdır; oturma en yakın duruma gider.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('icerik'))),
    );
    await gesture.moveBy(const Offset(-width / 2, 0));
    await tester.pump();
    expect(controller.horizontalController.value,
        closeTo(0.5 + HomeNavigationController.pageSpan / 2, 0.01));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('kısa ama HIZLI fiske yine de sayfa değiştirir', (tester) async {
    // Eskiden yalnız konuma bakılıyordu: %15 yol almış hızlı fiske
    // hiçbir şey yapmadan geri yaslanıyordu.
    final controller = await pump(tester);

    await tester.fling(
      find.byKey(const Key('icerik')),
      const Offset(-60, 0),
      1500,
    );
    await tester.pumpAndSettle();

    expect(controller.currentSliderState, SliderState.debt);
  });

  testWidgets('kısa ve YAVAŞ sürükleme aynı sayfada oturur', (tester) async {
    final controller = await pump(tester);

    await tester.drag(find.byKey(const Key('icerik')), const Offset(-40, 0));
    await tester.pumpAndSettle();

    expect(controller.currentSliderState, SliderState.transactions);
    expect(controller.horizontalController.value, closeTo(0.5, 0.001));
  });

  testWidgets('dikey liste kaydırması çalınmaz', (tester) async {
    final controller = await pump(
      tester,
      content: ListView.builder(
        key: const Key('icerik'),
        itemCount: 40,
        itemBuilder: (_, i) => SizedBox(height: 40, child: Text('satır $i')),
      ),
    );

    await tester.drag(find.byKey(const Key('icerik')), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(controller.horizontalController.value, closeTo(0.5, 0.001),
        reason: 'Dikey kaydırma yatay eksene sızdı');
    expect(find.text('satır 0'), findsNothing, reason: 'Liste hiç kaymadı');
  });

  testWidgets('sürükleme sürerken kabuk "duruyor" saymaz', (tester) async {
    // İnteraktif tur bu bayrağa bakıyor. Hem knob hem içerik jesti değeri
    // `animateTo` ile değil doğrudan yazdığı için `isAnimating` false
    // kalıyordu: parmak ekrandayken tur açılabilirdi.
    final controller = await pump(tester);
    expect(controller.isAnimating, isFalse);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('icerik'))),
    );
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();

    expect(controller.isAnimating, isTrue,
        reason: 'Parmak ekrandayken kabuk durur sayıldı');

    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.isAnimating, isFalse,
        reason: 'Oturma bittiği hâlde kabuk hâlâ hareketli sayılıyor');
  });

  testWidgets('daha derindeki yatay jest (kaydır-sil) önceliklidir',
      (tester) async {
    var dismissed = false;
    final controller = await pump(
      tester,
      content: Center(
        child: SizedBox(
          key: const Key('icerik'),
          height: 80,
          child: Dismissible(
            key: const Key('kart'),
            onDismissed: (_) => dismissed = true,
            child: const ColoredBox(
              color: Color(0xFFEEEEEE),
              child: Center(child: Text('KART')),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.text('KART'), const Offset(-width, 0));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
    expect(controller.horizontalController.value, closeTo(0.5, 0.001),
        reason: 'Kaydır-sil jesti sayfayı da değiştirdi');
  });

  // ================== ALT SAYFA KAPISI ==================
  //
  // Ölçülen hata: alt sayfa (Rapor) açıkken içerikteki her yatay jest önce
  // grafiğin kendi jestini iptal ettiriyor, sonra da alt sayfayı kapatıyordu.

  Future<HomeNavigationController> pumpWithSubView(
    WidgetTester tester, {
    required Widget subView,
  }) async {
    final controller = await pump(tester, subViews: [subView]);
    unawaited(controller.navigateToView(1));
    await tester.pumpAndSettle();
    expect(controller.isAtMainView, isFalse, reason: 'alt sayfa açılmadı');
    return controller;
  }

  testWidgets('alt sayfa açıkken küçük bir yatay kayma sayfayı KAPATMAZ',
      (tester) async {
    // 25 px: kTouchSlop'un (18) hemen üstü — kazara bir parmak kayması.
    // Kapıdan önce bu kadarı raporu kapatıp ana görünüme döndürüyordu.
    final controller = await pumpWithSubView(
      tester,
      subView: const ColoredBox(
        key: Key('rapor'),
        color: Color(0xFFCCCCFF),
        child: SizedBox.expand(),
      ),
    );

    await tester.drag(find.byKey(const Key('rapor')), const Offset(-25, 0));
    await tester.pumpAndSettle();

    expect(controller.isAtMainView, isFalse,
        reason: 'Alt sayfa yatay kaymayla kapandı');
    expect(controller.horizontalController.value, closeTo(0.5, 0.001),
        reason: 'Alt sayfadayken ana eksen kıpırdadı');
  });

  testWidgets('alt sayfa açıkken TAM ekran genişliği sürükleme de etkisiz',
      (tester) async {
    final controller = await pumpWithSubView(
      tester,
      subView: const ColoredBox(
        key: Key('rapor'),
        color: Color(0xFFCCCCFF),
        child: SizedBox.expand(),
      ),
    );

    await tester.drag(find.byKey(const Key('rapor')), const Offset(-width, 0));
    await tester.pumpAndSettle();

    expect(controller.currentSliderState, SliderState.transactions);
    expect(controller.isAtMainView, isFalse);
  });

  testWidgets('alt sayfadaki grafik kendi sürükleme jestini geri alıyor',
      (tester) async {
    // Kapıdan önce ölçülen olay dizisi: [FlPanDownEvent, FlPanCancelEvent].
    // Grafiğin PanGestureRecognizer'ı 36 px'e (kPanSlop) ulaşamadan kabuk
    // 18 px'te (kTouchSlop) arenayı kazanıp iptal ettiriyordu.
    final events = <String>[];
    await pumpWithSubView(
      tester,
      subView: SizedBox.expand(
        key: const Key('rapor'),
        child: BarChart(BarChartData(
          barGroups: List.generate(
            5,
            (i) => BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(toY: (i + 1) * 3.0, width: 20)],
            ),
          ),
          barTouchData: BarTouchData(
            touchCallback: (event, _) => events.add(event.runtimeType.toString()),
          ),
        )),
      ),
    );

    // Gerçek parmak gibi küçük adımlarla: tek büyük sıçrama pan slop'unu
    // bir hamlede aşar ve arenayı yalancı biçimde grafiğe kazandırır.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(BarChart)),
    );
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(-8, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(events, contains('FlPanUpdateEvent'),
        reason: 'Grafik sürüklemeyi göremedi: $events');
    expect(events, isNot(contains('FlPanCancelEvent')),
        reason: 'Grafiğin jesti iptal ettirildi: $events');
  });

  testWidgets('kapı açılıp kapanırken içerik yeniden mount EDİLMEZ',
      (tester) async {
    // Kapı, sarmalayıcıyı ağaçtan çıkararak değil callback'leri null'a
    // çekerek işlemeli: koşullu `child` döndürmek Element'i düşürür ve
    // sayfaların bloc/scroll durumunu sıfırlardı.
    final controller = await pump(
      tester,
      subViews: const [
        ColoredBox(key: Key('rapor'), color: Color(0xFFCCCCFF)),
      ],
      content: const _MountCounter(key: Key('icerik')),
      // Yığın çizilmez: ölçülen tek şey KAPININ çocuğa etkisi. (Küp yığını
      // görünmeyen yüzü zaten kendisi unmount eder; o ayrı bir davranış.)
      renderStack: false,
    );

    final state = tester.state<_MountCounterState>(find.byType(_MountCounter));
    expect(_MountCounter.mounts, 1);

    unawaited(controller.navigateToView(1));
    await tester.pumpAndSettle();
    unawaited(controller.closeToMain());
    await tester.pumpAndSettle();
    expect(controller.isAtMainView, isTrue);

    expect(_MountCounter.mounts, 1, reason: 'İçerik yeniden mount edildi');
    expect(tester.state<_MountCounterState>(find.byType(_MountCounter)),
        same(state),
        reason: 'İçeriğin State nesnesi değişti');
  });
}

/// Kaç kez mount edildiğini sayan içerik.
class _MountCounter extends StatefulWidget {
  const _MountCounter({super.key});

  static int mounts = 0;

  @override
  State<_MountCounter> createState() => _MountCounterState();
}

class _MountCounterState extends State<_MountCounter> {
  @override
  void initState() {
    super.initState();
    _MountCounter.mounts++;
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFFDDDDDD),
        child: SizedBox.expand(),
      );
}

class _Host extends StatefulWidget {
  const _Host({
    required this.onReady,
    this.content,
    this.subViews = const [],
    this.renderStack = true,
  });

  final void Function(HomeNavigationController) onReady;
  final Widget? content;
  final List<Widget> subViews;

  /// false ise MainContentSwipe'ın çocuğu yığın değil [content]'tir: kapının
  /// açılıp kapanmasının çocuğa etkisi yığının kendi mount davranışından
  /// ayrılabilsin diye.
  final bool renderStack;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with TickerProviderStateMixin {
  late final HomeNavigationController controller =
      HomeNavigationController(this);

  @override
  void initState() {
    super.initState();
    controller.setupViewStack(
      mainView: const SizedBox.expand(),
      subViews: widget.subViews,
    );
    widget.onReady(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: 600,
          child: MainContentSwipe(
            controller: controller,
            child: (widget.subViews.isEmpty || !widget.renderStack)
                ? (widget.content ??
                    const ColoredBox(
                      key: Key('icerik'),
                      color: Color(0xFFDDDDDD),
                      child: SizedBox.expand(),
                    ))
                : AnimatedBuilder(
                    animation: Listenable.merge(
                      [controller, controller.viewStack],
                    ),
                    builder: (_, __) => controller.viewStack.buildTransition(),
                  ),
          ),
        ),
      ),
    );
  }
}

const width = 400.0;
