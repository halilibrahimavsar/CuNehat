import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_tour.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

/// [OnboardingTour] kapısının davranışı: tur yalnız **kendi sayfası** ekranda
/// ve durur haldeyken oynar.
void main() {
  late OnboardingCoordinator coordinator;
  late List<List<GlobalKey>> started;
  late GlobalKey targetKey;

  setUpAll(() {
    getIt.allowReassignment = true;
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    coordinator = OnboardingCoordinator(await SharedPreferences.getInstance());
    started = [];
    coordinator.startShowcaseOverride = started.add;
    getIt.registerSingleton<OnboardingCoordinator>(coordinator);
    targetKey = GlobalKey(debugLabel: 'target');
  });

  tearDown(() async {
    coordinator.dispose();
    await getIt.reset();
  });

  Widget tourPage({String label = 'ana sayfa', bool enabled = true}) {
    return OnboardingTour(
      flow: OnboardingFlow.budgets,
      keys: [targetKey],
      enabled: enabled,
      child: Showcase(
        key: targetKey,
        title: 'başlık',
        description: 'açıklama',
        child: Scaffold(body: Text(label)),
      ),
    );
  }

  testWidgets('sayfa görünürken tur oynar', (tester) async {
    await tester.pumpWidget(MaterialApp(home: tourPage()));
    await tester.pumpAndSettle();

    expect(started, [
      [targetKey]
    ]);
  });

  testWidgets('üstte başka sayfa varken oynamaz, geri dönünce oynar',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: tourPage(),
    ));

    // Tur isteği açıldı ama daha değerlendirilmeden başka sayfaya geçiliyor
    // (cüzdan sheet'inden banka ekstresine geçiş senaryosu).
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('banka ekstresi')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('banka ekstresi'), findsOneWidget);
    expect(started, isEmpty,
        reason: 'tur başka sayfanın üstünde açılmamalı');
    expect(coordinator.isSeen(OnboardingFlow.budgets), isFalse,
        reason: 'oynatılamayan tur harcanmamalı');

    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(started, [
      [targetKey]
    ]);
  });

  testWidgets('sayfanın giriş animasyonu bitmeden oynamaz', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: const Scaffold(body: Text('kök')),
    ));

    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => tourPage(label: 'bütçeler')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(started, isEmpty, reason: 'sayfa hâlâ içeri kayıyor');

    await tester.pumpAndSettle();
    expect(started, [
      [targetKey]
    ]);
  });

  testWidgets('devre dışı turda istek hiç açılmaz', (tester) async {
    await tester.pumpWidget(MaterialApp(home: tourPage(enabled: false)));
    await tester.pumpAndSettle();

    expect(started, isEmpty);
    expect(coordinator.isPending(OnboardingFlow.budgets), isFalse);
  });

  testWidgets('hedef ağaçta değilken beklenir', (tester) async {
    // Showcase hedefi olmayan bir ağaç: tur isteği açılır ama oynamaz.
    await tester.pumpWidget(MaterialApp(
      home: OnboardingTour(
        flow: OnboardingFlow.budgets,
        keys: [targetKey],
        child: const Scaffold(body: Text('hedefsiz')),
      ),
    ));
    await tester.pumpAndSettle();

    expect(started, isEmpty);
    expect(coordinator.isPending(OnboardingFlow.budgets), isTrue);
  });

  testWidgets('sayfa yeniden mount olsa da tur bir kez oynar', (tester) async {
    await tester.pumpWidget(MaterialApp(home: tourPage()));
    await tester.pumpAndSettle();
    expect(started.length, 1);

    // Ağacı boşaltıp yeniden kurmak = yeniden mount.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpWidget(MaterialApp(home: tourPage()));
    await tester.pumpAndSettle();

    expect(started.length, 1);
  });

  testWidgets('kabuğa bağlı tur, kabuk doğru konumda değilken oynamaz',
      (tester) async {
    var stackIndex = 1; // alt sayfa açık
    coordinator.shellStatusProvider = () => OnboardingShellStatus(
          sliderValue: 0.5,
          stackIndex: stackIndex,
          isAnimating: false,
          isTransformed: false,
        );

    await tester.pumpWidget(MaterialApp(
      home: OnboardingTour(
        flow: OnboardingFlow.transactions,
        keys: [targetKey],
        child: Showcase(
          key: targetKey,
          title: 'başlık',
          description: 'açıklama',
          child: const Scaffold(body: Text('işlemler')),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(started, isEmpty);

    stackIndex = 0; // alt sayfa kapandı
    coordinator.notifyMaybeReady();
    await tester.pumpAndSettle();
    expect(started, [
      [targetKey]
    ]);
  });
}
