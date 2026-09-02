import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/core/texts/slider_texts.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/dynamic_slider.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Dikey navigasyonun tek AKTİF ipucu. Duran bir chevron kullanıcıya
/// "buradan aşağı sürükle" diyemiyordu; çark bir kez inip yaylanarak dönüyor.
void main() {
  final subs = {
    SliderState.savedMoney: [
      SubMenuItem(icon: Icons.pie_chart, label: 'Detay', onTap: () {}),
    ],
    SliderState.transactions: [
      SubMenuItem(icon: Icons.insights, label: 'Detay', onTap: () {}),
      SubMenuItem(icon: Icons.analytics, label: 'Rapor', onTap: () {}),
    ],
    SliderState.debt: [
      SubMenuItem(icon: Icons.history, label: 'Geçmiş', onTap: () {}),
    ],
  };

  // `ListWheelScrollView` içeride Scrollable'ın PRIVATE alt sınıfını kuruyor;
  // `find.byType(Scrollable)` tam tür eşleşmesi aradığı için onu bulamaz.
  final wheelFinder = find.byWidgetPredicate((w) => w is Scrollable);

  double wheelOffset(WidgetTester tester) =>
      tester.state<ScrollableState>(wheelFinder).position.pixels;

  testWidgets('tanıtım bir kez oynar, çark yerine döner ve haber verir',
      (tester) async {
    final played = <SliderState>[];
    await tester.pumpWidget(_Host(
      subs: subs,
      peekStates: SliderState.values.toSet(),
      onPeekPlayed: played.add,
    ));

    // İlk kareden sonra tanıtım başlar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(wheelOffset(tester), greaterThan(0.0),
        reason: 'Çark hiç kıpırdamadı');

    await tester.pumpAndSettle();
    expect(wheelOffset(tester), closeTo(0.0, 0.01),
        reason: 'Çark başlangıç konumuna dönmedi');
    expect(played, [SliderState.transactions]);
  });

  testWidgets('tanıtım seçili öğeyi değiştirmez', (tester) async {
    await tester.pumpWidget(_Host(
      subs: subs,
      peekStates: SliderState.values.toSet(),
      onPeekPlayed: (_) {},
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final position = tester.state<ScrollableState>(wheelFinder).position
        as FixedExtentMetrics;
    expect(position.itemIndex, 0, reason: 'Tanıtım alt sayfaya geçirdi');
    // '+' rozeti yalnız ana başlık ortadayken görünür: seçim korunmuş demek.
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('aynı durumda ikinci kez oynamaz', (tester) async {
    final played = <SliderState>[];
    await tester.pumpWidget(_Host(
      subs: subs,
      peekStates: SliderState.values.toSet(),
      onPeekPlayed: played.add,
    ));
    await tester.pumpAndSettle();
    expect(played, [SliderState.transactions]);

    // Durumdan çık ve geri dön.
    final host = tester.state<_HostState>(find.byType(_Host));
    host.controller.animateTo(1.0, duration: const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    host.controller.animateTo(0.5, duration: const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(played, [SliderState.transactions, SliderState.debt],
        reason: 'İşlemler ikinci kez oynadı ya da Borç hiç oynamadı');
  });

  testWidgets('canPeek false iken ERTELENİR: oynamaz ve "görüldü" yazılmaz',
      (tester) async {
    final played = <SliderState>[];
    var allowed = false;
    await tester.pumpWidget(_Host(
      subs: subs,
      peekStates: SliderState.values.toSet(),
      onPeekPlayed: played.add,
      canPeek: () => allowed,
    ));
    await tester.pumpAndSettle();

    expect(played, isEmpty, reason: 'Kapı kapalıyken oynadı');
    expect(wheelOffset(tester), closeTo(0.0, 0.01));

    // Kapı açılıp bir rebuild geldiğinde tanıtım hâlâ borçlu olmalı.
    allowed = true;
    final host = tester.state<_HostState>(find.byType(_Host));
    host.bump();
    await tester.pumpAndSettle();

    expect(played, [SliderState.transactions],
        reason: 'Ertelenen tanıtım kayboldu');
  });

  testWidgets(
      'ertelenen tanıtım, ÜST durumu setState eden bir sahipte de patlamaz',
      (tester) async {
    // Uygulamadaki şekil: `onPeekPlayed` üst durumda `setState` çağırıyor
    // (bekleyen tanıtım kümesinden düşürmek için). Tanıtım `didUpdateWidget`
    // içinden SENKRON çağrılırsa, üst durum kendi rebuild'inin ortasında
    // kirletilir ve Flutter `Element.rebuild`'in sonundaki `assert(!_dirty)`
    // ile çöker (cihazda `Showcase > SliderButtonView` altında görüldü).
    final played = <SliderState>[];
    var allowed = false;
    await tester.pumpWidget(_Host(
      subs: subs,
      peekStates: SliderState.values.toSet(),
      onPeekPlayed: played.add,
      canPeek: () => allowed,
      ownerSetsStateOnPeek: true,
    ));
    await tester.pumpAndSettle();
    expect(played, isEmpty);

    allowed = true;
    tester.state<_PeekOwnerState>(find.byType(_PeekOwner)).bump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'tanıtım build fazında üst durumu kirletti');
    expect(played, [SliderState.transactions]);
  });

  testWidgets('listede olmayan durum için oynamaz', (tester) async {
    final played = <SliderState>[];
    await tester.pumpWidget(_Host(
      subs: subs,
      peekStates: const {SliderState.debt},
      onPeekPlayed: played.add,
    ));
    await tester.pumpAndSettle();

    expect(played, isEmpty);
    expect(wheelOffset(tester), closeTo(0.0, 0.01));
  });
}

class _Host extends StatefulWidget {
  const _Host({
    required this.subs,
    required this.peekStates,
    required this.onPeekPlayed,
    this.canPeek,
    this.ownerSetsStateOnPeek = false,
  });

  final Map<SliderState, List<SubMenuItem>> subs;
  final Set<SliderState> peekStates;
  final ValueChanged<SliderState> onPeekPlayed;
  final bool Function()? canPeek;

  /// Kaydırıcıyı, `onPeekPlayed`'de kendi `setState`'ini çağıran bir durum
  /// sahibinin altına kurar — uygulamadaki `SliderButtonView` gibi.
  final bool ownerSetsStateOnPeek;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    value: 0.5,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Kaydırıcıyı yeniden kurdurur (uygulamada cüzdan/kaydırıcı olayları
  /// bunu doğal olarak yapıyor).
  void bump() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final slider = DynamicSlider(
      controller: controller,
      subMenuItems: widget.subs,
      peekStates: widget.peekStates,
      onPeekPlayed: widget.onPeekPlayed,
      canPeek: widget.canPeek,
      texts: const SliderTexts(
        savings: 'BİRİKİM',
        transactions: 'İŞLEMLER',
        debt: 'BORÇ',
      ),
    );

    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const Spacer(),
            if (widget.ownerSetsStateOnPeek)
              _PeekOwner(
                controller: controller,
                subs: widget.subs,
                peekStates: widget.peekStates,
                onPeekPlayed: widget.onPeekPlayed,
                canPeek: widget.canPeek,
              )
            else
              slider,
          ],
        ),
      ),
    );
  }
}

/// `SliderButtonView`in test karşılığı: tanıtım oynayınca kendi durumunu
/// `setState` ile günceller ve kaydırıcıyı ARADA bileşen olmadan (yalnız
/// `Padding`) taşır — kirlenmenin üst duruma ulaştığı gerçek şekil budur.
class _PeekOwner extends StatefulWidget {
  const _PeekOwner({
    required this.controller,
    required this.subs,
    required this.peekStates,
    required this.onPeekPlayed,
    required this.canPeek,
  });

  final AnimationController controller;
  final Map<SliderState, List<SubMenuItem>> subs;
  final Set<SliderState> peekStates;
  final ValueChanged<SliderState> onPeekPlayed;
  final bool Function()? canPeek;

  @override
  State<_PeekOwner> createState() => _PeekOwnerState();
}

class _PeekOwnerState extends State<_PeekOwner> {
  late Set<SliderState> _pending = {...widget.peekStates};

  void bump() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: DynamicSlider(
        controller: widget.controller,
        subMenuItems: widget.subs,
        peekStates: _pending,
        canPeek: widget.canPeek,
        onPeekPlayed: (state) {
          widget.onPeekPlayed(state);
          if (!mounted) return;
          setState(() => _pending = {..._pending}..remove(state));
        },
        texts: const SliderTexts(
          savings: 'BİRİKİM',
          transactions: 'İŞLEMLER',
          debt: 'BORÇ',
        ),
      ),
    );
  }
}
