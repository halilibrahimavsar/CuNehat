import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late OnboardingCoordinator coordinator;
  late List<List<GlobalKey>> started;

  final keyA = GlobalKey(debugLabel: 'a');
  final keyB = GlobalKey(debugLabel: 'b');

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    coordinator = OnboardingCoordinator(prefs);
    started = [];
    coordinator.startShowcaseOverride = started.add;
  });

  tearDown(() => coordinator.dispose());

  /// Kabuğa bağlı olmayan (kendi route'u olan) bir yüzey turu isteği.
  void request(
    OnboardingFlow flow, {
    required List<GlobalKey> keys,
    bool Function()? isReady,
    bool Function()? isAlive,
    Object? owner,
  }) {
    coordinator.requestTour(
      flow,
      owner: owner ?? Object(),
      keys: keys,
      isAlive: isAlive ?? () => true,
      isReady: isReady ?? () => true,
    );
  }

  testWidgets('hazır olan istek kare sonunda başlar', (tester) async {
    request(OnboardingFlow.shell, keys: [keyA]);
    expect(started, isEmpty, reason: 'değerlendirme kare sonuna ertelenir');

    await tester.pump();
    expect(started, [
      [keyA]
    ]);
  });

  testWidgets('hazır olmayan istek beklemede kalır, düşürülmez',
      (tester) async {
    var ready = false;
    request(OnboardingFlow.shell, keys: [keyA], isReady: () => ready);

    await tester.pump();
    await tester.pump();
    expect(started, isEmpty);
    expect(coordinator.isSeen(OnboardingFlow.shell), isFalse,
        reason: 'oynatılamayan tur "görüldü" sayılmamalı');

    // Yüzey görünür hale gelince (ör. üstteki sayfa kapandı) oynar.
    ready = true;
    coordinator.notifyMaybeReady();
    await tester.pump();
    expect(started, [
      [keyA]
    ]);
  });

  testWidgets('aynı akış iki kez istenirse tur bir kez oynar', (tester) async {
    // Küp geçişinde sayfa iki kez mount olsa bile ikinci istek birincinin
    // üzerine yazılır; tur tekrar etmez.
    request(OnboardingFlow.shell, keys: [keyA]);
    request(OnboardingFlow.shell, keys: [keyA]);
    await tester.pump();
    expect(started.length, 1);

    // Tur oynarken gelen üçüncü istek de yutulur.
    request(OnboardingFlow.shell, keys: [keyA]);
    await tester.pump();
    expect(started.length, 1);

    coordinator.handleShowcaseIdle();
    request(OnboardingFlow.shell, keys: [keyA]);
    await tester.pump();
    expect(started.length, 1, reason: 'bayrak tur BAŞLARKEN yazılır');
  });

  testWidgets('görüldü bayrağı tur başlarken kalıcılaşır', (tester) async {
    request(OnboardingFlow.shell, keys: [keyA]);
    await tester.pump();

    expect(coordinator.isSeen(OnboardingFlow.shell), isTrue);
    expect(prefs.getBool('onboarding_shell_seen'), isTrue);
  });

  testWidgets('sahibi ağaçtan kalkan istek düşer', (tester) async {
    var alive = true;
    request(
      OnboardingFlow.shell,
      keys: [keyA],
      isAlive: () => alive,
      isReady: () => true,
    );
    alive = false;

    await tester.pump();
    expect(started, isEmpty);
    expect(coordinator.isPending(OnboardingFlow.shell), isFalse);
    expect(coordinator.isSeen(OnboardingFlow.shell), isFalse);
  });

  testWidgets('aynı anda tek tur oynar, sırası bildirim sırasıdır',
      (tester) async {
    request(OnboardingFlow.cardRail, keys: [keyB]);
    request(OnboardingFlow.shell, keys: [keyA]);

    await tester.pump();
    // shell, enum'da cardRail'den önce bildirilmiştir.
    expect(started, [
      [keyA]
    ]);
    expect(coordinator.runningFlow, OnboardingFlow.shell);

    coordinator.handleShowcaseIdle();
    await tester.pump();
    expect(started, [
      [keyA],
      [keyB]
    ]);
  });

  testWidgets('cancelTour yalnız kendi isteğini geri çeker', (tester) async {
    final oldOwner = Object();
    final newOwner = Object();
    request(OnboardingFlow.shell, keys: [keyA], owner: oldOwner);
    // Yeniden mount: yeni sahip isteği devralır, ardından eski sahip dispose
    // olur — yeni istek silinmemeli.
    request(OnboardingFlow.shell, keys: [keyB], owner: newOwner);
    coordinator.cancelTour(OnboardingFlow.shell, oldOwner);

    await tester.pump();
    expect(started, [
      [keyB]
    ]);
  });

  group('isHomeShellAtRoot', () {
    OnboardingShellStatus status({
      int stack = 0,
      bool animating = false,
      bool transformed = false,
    }) =>
        OnboardingShellStatus(
          stackIndex: stack,
          isAnimating: animating,
          isTransformed: transformed,
        );

    test('kabuk kurulmamışken hazır değildir', () {
      expect(coordinator.isHomeShellAtRoot(), isFalse);
    });

    test('kök görünümde ve dururken hazırdır', () {
      coordinator.shellStatusProvider = status;
      expect(coordinator.isHomeShellAtRoot(), isTrue);
    });

    test('alt sayfa açıkken hazır değildir', () {
      coordinator.shellStatusProvider = () => status(stack: 1);
      expect(coordinator.isHomeShellAtRoot(), isFalse);
    });

    test('geçiş sürerken ya da drawer/cüzdan açıkken hazır değildir', () {
      coordinator.shellStatusProvider = () => status(animating: true);
      expect(coordinator.isHomeShellAtRoot(), isFalse);
      coordinator.shellStatusProvider = () => status(transformed: true);
      expect(coordinator.isHomeShellAtRoot(), isFalse);
    });
  });

  test('resetAndReplay bayrağı siler ve dinleyicileri uyarır', () async {
    await coordinator.markSeen(OnboardingFlow.shell);
    var notified = 0;
    coordinator.addListener(() => notified++);

    await coordinator.resetAndReplay(OnboardingFlow.shell);

    expect(coordinator.isSeen(OnboardingFlow.shell), isFalse);
    expect(notified, 1);
  });

  test('resetAll tüm bayrakları siler ve dinleyicileri uyarır', () async {
    await coordinator.markSeen(OnboardingFlow.shell);
    await coordinator.markSeen(OnboardingFlow.cardRail);
    var notified = 0;
    coordinator.addListener(() => notified++);

    await coordinator.resetAll();

    for (final flow in OnboardingFlow.values) {
      expect(coordinator.isSeen(flow), isFalse, reason: flow.name);
    }
    expect(notified, 1);
  });

  test('kalan turların hepsi kabuktadır: kabuk kökte ve dururken oynarlar', () {
    // Form ve cüzdan sayfası turları kaldırıldı (alan açıklamaları alanın
    // altında duruyor). Kalan iki turun hedefi kabuğun kendisinde: alttaki
    // kaydırıcı ve üst çubuktaki kart düğmesi.
    expect(
        OnboardingFlow.values, [OnboardingFlow.shell, OnboardingFlow.cardRail]);
    for (final flow in OnboardingFlow.values) {
      expect(flow.requiresHomeShellAtRoot, isTrue, reason: flow.name);
    }
  });

  // Bayrak anahtarı akışın ADINDAN türer; ad değişirse turu görmüş herkese
  // yeniden oynar.
  test('kalan turların bayrak anahtarları değişmedi', () async {
    await coordinator.markSeen(OnboardingFlow.shell);
    await coordinator.markSeen(OnboardingFlow.cardRail);

    expect(prefs.getBool('onboarding_shell_seen'), isTrue);
    expect(prefs.getBool('onboarding_cardRail_seen'), isTrue);
  });
}
