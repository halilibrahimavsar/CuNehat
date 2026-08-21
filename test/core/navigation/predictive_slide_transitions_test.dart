import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/navigation/predictive_slide_page_transitions_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sistem geri jesti (`flutter/backgesture`) route'un animasyonunu parmakla
/// sürüyor mu, görsel gerçekten kayıyor mu, iptal/onay doğru mu?
///
/// Kanal normal bir `MethodChannel` olduğu için olaylar testten sentezlenebilir
/// — cihaz gerekmiyor.
void main() {
  const codec = StandardMethodCodec();

  Future<void> send(WidgetTester tester, String method,
      [Map<String, Object?>? args]) {
    return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.backGesture.name,
      codec.encodeMethodCall(MethodCall(method, args)),
      (_) {},
    );
  }

  Map<String, Object?> event(double progress) => <String, Object?>{
        'touchOffset': <Object?>[0.0, 300.0],
        'progress': progress,
        'swipeEdge': 0, // SwipeEdge.left
      };

  Future<void> start(WidgetTester tester, {double progress = 0.0}) =>
      send(tester, 'startBackGesture', event(progress));
  Future<void> update(WidgetTester tester, double progress) =>
      send(tester, 'updateBackGestureProgress', event(progress));
  Future<void> commit(WidgetTester tester) => send(tester, 'commitBackGesture');
  Future<void> cancel(WidgetTester tester) => send(tester, 'cancelBackGesture');

  Future<void> pushSecond(WidgetTester tester) async {
    await tester.tap(find.text('AÇ'));
    await tester.pumpAndSettle();
    expect(find.text('SAYFA2'), findsOneWidget);
  }

  double leftOf(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dx;

  testWidgets('jest sayfayı parmakla birlikte kaydırır', (tester) async {
    await tester.pumpWidget(const _App());
    await pushSecond(tester);

    final resting = leftOf(tester, 'SAYFA2');

    await start(tester);
    await tester.pump();
    await update(tester, 0.5);
    await tester.pump();

    final dragged = leftOf(tester, 'SAYFA2');
    expect(dragged, greaterThan(resting),
        reason: 'Üstteki sayfa jest sırasında hiç kaymadı');

    // Doğrusal takip: yarı yolda ekranın yaklaşık yarısı kadar.
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(dragged - resting, closeTo(width / 2, width * 0.08),
        reason: 'Hareket parmağı doğrusal izlemiyor');

    await cancel(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('alttaki sayfa da hareket eder (paralaks)', (tester) async {
    await tester.pumpWidget(const _App());
    await pushSecond(tester);

    // Alttaki sayfa üst sayfa oturduğunda offstage olduğundan ölçüm jest
    // SIRASINDA yapılır: ilerleme arttıkça yerine doğru gelmeli.
    await start(tester);
    await tester.pump();
    await update(tester, 0.3);
    await tester.pump();
    final erken = leftOf(tester, 'SAYFA1');

    await update(tester, 0.7);
    await tester.pump();
    final gec = leftOf(tester, 'SAYFA1');

    // Eski `PredictiveBackPageTransitionsBuilder`'da alttaki sayfa HİÇ
    // kıpırdamıyordu (secondaryAnimation okunmuyor, delegatedTransition yok).
    expect(gec, greaterThan(erken), reason: 'Alttaki sayfa paralaks yapmıyor');

    await cancel(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('iptal sayfayı yerine geri getirir', (tester) async {
    await tester.pumpWidget(const _App());
    await pushSecond(tester);
    final resting = leftOf(tester, 'SAYFA2');

    await start(tester);
    await tester.pump();
    await update(tester, 0.4);
    await tester.pump();
    expect(leftOf(tester, 'SAYFA2'), greaterThan(resting));

    await cancel(tester);
    await tester.pumpAndSettle();

    expect(find.text('SAYFA2'), findsOneWidget, reason: 'İptal poplamış');
    expect(leftOf(tester, 'SAYFA2'), closeTo(resting, 0.5));
  });

  testWidgets('onay sayfayı poplar', (tester) async {
    await tester.pumpWidget(const _App());
    await pushSecond(tester);

    await start(tester);
    await tester.pump();
    await update(tester, 0.8);
    await tester.pump();
    await commit(tester);
    await tester.pumpAndSettle();

    expect(find.text('SAYFA2'), findsNothing);
    expect(find.text('SAYFA1'), findsOneWidget);
  });

  testWidgets('onaydan sonra sayfa geri sıçramaz (tek animasyon)',
      (tester) async {
    // `TransitionRoute.handleCommitBackGesture` popladıktan SONRA
    // `_controller.reverse(from: upperBound)` çağırıyor: animasyon 1.0'a
    // GERİ SIÇRAYIP baştan oynuyor. SDK'nın kendi geçişleri bunu maskeleyen
    // ayrı bir "commit" animasyonu çiziyor; doğrusal eşlenen bir kayma
    // geçişinde ise iki ayrı animasyon gibi görünüyor.
    await tester.pumpWidget(const _App());
    await pushSecond(tester);

    await start(tester);
    await tester.pump();
    await update(tester, 0.4);
    await tester.pump();

    final atCommit = leftOf(tester, 'SAYFA2');
    await commit(tester);
    await tester.pump();

    final positions = <double>[];
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.text('SAYFA2').evaluate().isEmpty) break;
      positions.add(leftOf(tester, 'SAYFA2'));
    }

    for (final p in positions) {
      expect(p, greaterThanOrEqualTo(atCommit - 1.0),
          reason: 'Sayfa parmağın bıraktığı yerin GERİSİNE döndü: '
              '$atCommit → $positions');
    }
    await tester.pumpAndSettle();
  });

  testWidgets('kök rotada jest sayfayı oynatmaz', (tester) async {
    await tester.pumpWidget(const _App());
    final resting = leftOf(tester, 'SAYFA1');

    await start(tester);
    await tester.pump();
    await update(tester, 0.6);
    await tester.pump();

    expect(leftOf(tester, 'SAYFA1'), closeTo(resting, 0.5),
        reason: 'Poplanacak route yokken sayfa kaydı');

    await cancel(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('düğmeyle gelen geri olayı jest sayılmaz', (tester) async {
    await tester.pumpWidget(const _App());
    await pushSecond(tester);
    final resting = leftOf(tester, 'SAYFA2');

    // touchOffset yok = donanım/gezinme düğmesi.
    await send(tester, 'startBackGesture', <String, Object?>{
      'touchOffset': null,
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await tester.pump();
    await update(tester, 0.7);
    await tester.pump();

    expect(leftOf(tester, 'SAYFA2'), closeTo(resting, 0.5),
        reason: 'Düğme olayı parmak sürüklemesi gibi işlendi');

    await cancel(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('jest bayrağı onay ve iptalden sonra temizlenir', (tester) async {
    // Bayrak asılı kalırsa `popGestureInProgress` sonsuza dek true kalır:
    // `linearTransition` bir daha kapanmaz ve sonraki tüm geçişler eğrisiz
    // oynar. `didStartUserGesture` mutlaka dengelenmeli.
    await tester.pumpWidget(const _App());
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);

    await pushSecond(tester);
    await start(tester);
    await tester.pump();
    await update(tester, 0.5);
    await tester.pump();
    expect(navigator.userGestureInProgress, isTrue);

    await commit(tester);
    await tester.pumpAndSettle();
    expect(navigator.userGestureInProgress, isFalse,
        reason: 'Onaydan sonra jest bayrağı asılı kaldı');

    // İptal yolu da dengeli olmalı ve ikinci jest hâlâ çalışmalı.
    await pushSecond(tester);
    await start(tester);
    await tester.pump();
    await update(tester, 0.3);
    await tester.pump();
    expect(navigator.userGestureInProgress, isTrue);

    await cancel(tester);
    await tester.pumpAndSettle();
    expect(navigator.userGestureInProgress, isFalse,
        reason: 'İptalden sonra jest bayrağı asılı kaldı');
    expect(find.text('SAYFA2'), findsOneWidget);
  });

  test('tema Android için bu builder\'ı kullanır', () {
    for (final theme in ThemeNames.all.values) {
      expect(theme.pageTransitionsTheme.builders[TargetPlatform.android],
          isA<PredictiveSlidePageTransitionsBuilder>());
    }
  });
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeNames.all[ThemeNames.sysLight],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('SAYFA1'),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('SAYFA2')),
                      ),
                    ),
                  ),
                  child: const Text('AÇ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
