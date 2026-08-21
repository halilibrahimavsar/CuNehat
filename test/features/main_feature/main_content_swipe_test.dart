import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:cunehat/features/main_feature/widgets/main_content_swipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Bu jest eklenene kadar `lib` içinde tek bir `onHorizontalDrag` yoktu:
/// sayfalar arası geçmenin tek yolu alttaki 130×100 px'lik knob'du.
void main() {
  Future<HomeNavigationController> pump(
    WidgetTester tester, {
    Widget? content,
  }) async {
    late HomeNavigationController controller;
    await tester.pumpWidget(MaterialApp(
      home: _Host(
        content: content,
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
}

class _Host extends StatefulWidget {
  const _Host({required this.onReady, this.content});

  final void Function(HomeNavigationController) onReady;
  final Widget? content;

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
      subViews: const [],
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
            child: widget.content ??
                const ColoredBox(
                  key: Key('icerik'),
                  color: Color(0xFFDDDDDD),
                  child: SizedBox.expand(),
                ),
          ),
        ),
      ),
    );
  }
}

const width = 400.0;
