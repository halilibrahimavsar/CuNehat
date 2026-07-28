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
    request(OnboardingFlow.budgets, keys: [keyA]);
    expect(started, isEmpty, reason: 'değerlendirme kare sonuna ertelenir');

    await tester.pump();
    expect(started, [
      [keyA]
    ]);
  });

  testWidgets('hazır olmayan istek beklemede kalır, düşürülmez',
      (tester) async {
    var ready = false;
    request(OnboardingFlow.budgets, keys: [keyA], isReady: () => ready);

    await tester.pump();
    await tester.pump();
    expect(started, isEmpty);
    expect(coordinator.isSeen(OnboardingFlow.budgets), isFalse,
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
    request(OnboardingFlow.budgets, keys: [keyA]);
    request(OnboardingFlow.budgets, keys: [keyA]);
    await tester.pump();
    expect(started.length, 1);

    // Tur oynarken gelen üçüncü istek de yutulur.
    request(OnboardingFlow.budgets, keys: [keyA]);
    await tester.pump();
    expect(started.length, 1);

    coordinator.handleShowcaseIdle();
    request(OnboardingFlow.budgets, keys: [keyA]);
    await tester.pump();
    expect(started.length, 1, reason: 'bayrak tur BAŞLARKEN yazılır');
  });

  testWidgets('görüldü bayrağı tur başlarken kalıcılaşır', (tester) async {
    request(OnboardingFlow.budgets, keys: [keyA]);
    await tester.pump();

    expect(coordinator.isSeen(OnboardingFlow.budgets), isTrue);
    expect(prefs.getBool('onboarding_budgets_seen'), isTrue);
  });

  testWidgets('sahibi ağaçtan kalkan istek düşer', (tester) async {
    var alive = true;
    request(
      OnboardingFlow.budgets,
      keys: [keyA],
      isAlive: () => alive,
      isReady: () => true,
    );
    alive = false;

    await tester.pump();
    expect(started, isEmpty);
    expect(coordinator.isPending(OnboardingFlow.budgets), isFalse);
    expect(coordinator.isSeen(OnboardingFlow.budgets), isFalse);
  });

  testWidgets('aynı anda tek tur oynar, sırası bildirim sırasıdır',
      (tester) async {
    request(OnboardingFlow.recurringTemplates, keys: [keyB]);
    request(OnboardingFlow.budgets, keys: [keyA]);

    await tester.pump();
    // budgets, enum'da recurringTemplates'ten önce bildirilmiştir.
    expect(started, [
      [keyA]
    ]);
    expect(coordinator.runningFlow, OnboardingFlow.budgets);

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
    request(OnboardingFlow.budgets, keys: [keyA], owner: oldOwner);
    // Yeniden mount: yeni sahip isteği devralır, ardından eski sahip dispose
    // olur — yeni istek silinmemeli.
    request(OnboardingFlow.budgets, keys: [keyB], owner: newOwner);
    coordinator.cancelTour(OnboardingFlow.budgets, oldOwner);

    await tester.pump();
    expect(started, [
      [keyB]
    ]);
  });

  group('isHomeSlotSettled', () {
    OnboardingShellStatus status({
      double slider = 0.5,
      int stack = 0,
      bool animating = false,
      bool transformed = false,
    }) =>
        OnboardingShellStatus(
          sliderValue: slider,
          stackIndex: stack,
          isAnimating: animating,
          isTransformed: transformed,
        );

    test('kabuk yokken hiçbir yuva hazır değildir', () {
      expect(
        coordinator.isHomeSlotSettled(OnboardingHomeSlot.chrome),
        isFalse,
      );
    });

    test('doğru kaydırıcı ve yığın konumunda hazırdır', () {
      coordinator.shellStatusProvider = status;
      expect(
        coordinator.isHomeSlotSettled(
          OnboardingFlow.transactions.homeSlot!,
        ),
        isTrue,
      );
    });

    test('başka ekrandayken hazır değildir', () {
      coordinator.shellStatusProvider = () => status(slider: 0.0);
      expect(
        coordinator.isHomeSlotSettled(OnboardingFlow.transactions.homeSlot!),
        isFalse,
      );
      expect(
        coordinator.isHomeSlotSettled(OnboardingFlow.investment.homeSlot!),
        isTrue,
      );
    });

    test('alt sayfa açıkken ana ekran turu hazır değildir', () {
      coordinator.shellStatusProvider = () => status(stack: 1);
      expect(
        coordinator.isHomeSlotSettled(OnboardingFlow.transactions.homeSlot!),
        isFalse,
      );
      expect(
        coordinator.isHomeSlotSettled(
          OnboardingFlow.transactionsInsights.homeSlot!,
        ),
        isTrue,
      );
    });

    test('geçiş sürerken ya da drawer/cüzdan açıkken hazır değildir', () {
      coordinator.shellStatusProvider = () => status(animating: true);
      expect(
        coordinator.isHomeSlotSettled(OnboardingHomeSlot.chrome),
        isFalse,
      );
      coordinator.shellStatusProvider = () => status(transformed: true);
      expect(
        coordinator.isHomeSlotSettled(OnboardingHomeSlot.chrome),
        isFalse,
      );
    });
  });

  test('resetAndReplay bayrağı siler ve dinleyicileri uyarır', () async {
    await coordinator.markSeen(OnboardingFlow.transactions);
    var notified = 0;
    coordinator.addListener(() => notified++);

    await coordinator.resetAndReplay(OnboardingFlow.transactions);

    expect(coordinator.isSeen(OnboardingFlow.transactions), isFalse);
    expect(coordinator.pendingFlow, OnboardingFlow.transactions);
    expect(notified, 1);
  });

  test('resetAll tüm bayrakları siler ve dinleyicileri uyarır', () async {
    await coordinator.markSeen(OnboardingFlow.appBar);
    await coordinator.markSeen(OnboardingFlow.budgets);
    var notified = 0;
    coordinator.addListener(() => notified++);

    await coordinator.resetAll();

    for (final flow in OnboardingFlow.values) {
      expect(coordinator.isSeen(flow), isFalse, reason: flow.name);
    }
    expect(notified, 1);
  });

  test('her akışın yüzey tanımı vardır', () {
    // homeSlot null ise yüzeyin kendi route'u olmalı; ana ekranların yuvası
    // SubViewFactory sıralamasıyla tutarlı olmalı.
    expect(OnboardingFlow.transactionsReport.homeSlot?.stackIndex, 2);
    expect(OnboardingFlow.transactionsInsights.homeSlot?.stackIndex, 1);
    expect(OnboardingFlow.debtHistory.homeSlot?.sliderValue, 1.0);
    expect(OnboardingFlow.walletManagement.homeSlot, isNull);
    expect(OnboardingFlow.appBar.homeSlot?.sliderValue, isNull);
  });
}
