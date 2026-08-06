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
    request(OnboardingFlow.walletManagement, keys: [keyA]);
    expect(started, isEmpty, reason: 'değerlendirme kare sonuna ertelenir');

    await tester.pump();
    expect(started, [
      [keyA]
    ]);
  });

  testWidgets('hazır olmayan istek beklemede kalır, düşürülmez',
      (tester) async {
    var ready = false;
    request(OnboardingFlow.walletManagement,
        keys: [keyA], isReady: () => ready);

    await tester.pump();
    await tester.pump();
    expect(started, isEmpty);
    expect(coordinator.isSeen(OnboardingFlow.walletManagement), isFalse,
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
    request(OnboardingFlow.walletManagement, keys: [keyA]);
    request(OnboardingFlow.walletManagement, keys: [keyA]);
    await tester.pump();
    expect(started.length, 1);

    // Tur oynarken gelen üçüncü istek de yutulur.
    request(OnboardingFlow.walletManagement, keys: [keyA]);
    await tester.pump();
    expect(started.length, 1);

    coordinator.handleShowcaseIdle();
    request(OnboardingFlow.walletManagement, keys: [keyA]);
    await tester.pump();
    expect(started.length, 1, reason: 'bayrak tur BAŞLARKEN yazılır');
  });

  testWidgets('görüldü bayrağı tur başlarken kalıcılaşır', (tester) async {
    request(OnboardingFlow.walletManagement, keys: [keyA]);
    await tester.pump();

    expect(coordinator.isSeen(OnboardingFlow.walletManagement), isTrue);
    expect(prefs.getBool('onboarding_walletManagement_seen'), isTrue);
  });

  testWidgets('sahibi ağaçtan kalkan istek düşer', (tester) async {
    var alive = true;
    request(
      OnboardingFlow.walletManagement,
      keys: [keyA],
      isAlive: () => alive,
      isReady: () => true,
    );
    alive = false;

    await tester.pump();
    expect(started, isEmpty);
    expect(coordinator.isPending(OnboardingFlow.walletManagement), isFalse);
    expect(coordinator.isSeen(OnboardingFlow.walletManagement), isFalse);
  });

  testWidgets('aynı anda tek tur oynar, sırası bildirim sırasıdır',
      (tester) async {
    request(OnboardingFlow.investmentAdd, keys: [keyB]);
    request(OnboardingFlow.walletManagement, keys: [keyA]);

    await tester.pump();
    // walletManagement, enum'da investmentAdd'ten önce bildirilmiştir.
    expect(started, [
      [keyA]
    ]);
    expect(coordinator.runningFlow, OnboardingFlow.walletManagement);

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
    request(OnboardingFlow.walletManagement, keys: [keyA], owner: oldOwner);
    // Yeniden mount: yeni sahip isteği devralır, ardından eski sahip dispose
    // olur — yeni istek silinmemeli.
    request(OnboardingFlow.walletManagement, keys: [keyB], owner: newOwner);
    coordinator.cancelTour(OnboardingFlow.walletManagement, oldOwner);

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
    await coordinator.markSeen(OnboardingFlow.walletManagement);
    var notified = 0;
    coordinator.addListener(() => notified++);

    await coordinator.resetAll();

    for (final flow in OnboardingFlow.values) {
      expect(coordinator.isSeen(flow), isFalse, reason: flow.name);
    }
    expect(notified, 1);
  });

  test('kabuk kapısını yalnız shell akışı ister', () {
    // Kalan turların hepsinin kendi route'u var (sheet); kabuğun konumu
    // onları hiç ilgilendirmez.
    for (final flow in OnboardingFlow.values) {
      expect(
        flow.requiresHomeShellAtRoot,
        flow == OnboardingFlow.shell,
        reason: flow.name,
      );
    }
  });
}
