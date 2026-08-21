import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/main_feature/utils/slider_peek_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dikey navigasyon tanıtımı ile interaktif tur AYNI YÜZEYİ anlatıyor ve tur
/// tam ekran overlay çiziyor. Kapı olmadan tanıtım overlay'in arkasında
/// oynayıp kalıcı bayrağını yazıyor, yani bir daha hiç görünmüyordu.
void main() {
  late OnboardingCoordinator coordinator;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    coordinator = OnboardingCoordinator(await SharedPreferences.getInstance());
    coordinator.shellStatusProvider = () => const OnboardingShellStatus(
          stackIndex: 0,
          isAnimating: false,
          isTransformed: false,
        );
  });

  tearDown(() => coordinator.dispose());

  testWidgets('tur hiç istenmemişse kapı açıktır', (tester) async {
    expect(isSliderPeekAllowed(coordinator), isTrue);
  });

  testWidgets('tur BEKLERKEN kapı kapalıdır', (tester) async {
    coordinator.requestTour(
      OnboardingFlow.shell,
      owner: Object(),
      keys: [GlobalKey()],
      isAlive: () => true,
      isReady: () => false, // henüz hazır değil: beklemede kalır
    );

    expect(coordinator.isPending(OnboardingFlow.shell), isTrue);
    expect(isSliderPeekAllowed(coordinator), isFalse);
  });

  testWidgets('tur OYNARKEN kapı kapalıdır', (tester) async {
    var started = false;
    coordinator.startShowcaseOverride = (_) => started = true;
    coordinator.requestTour(
      OnboardingFlow.shell,
      owner: Object(),
      keys: [GlobalKey()],
      isAlive: () => true,
      isReady: () => true,
    );
    await tester.pump();

    expect(started, isTrue);
    expect(coordinator.runningFlow, OnboardingFlow.shell);
    expect(coordinator.isPending(OnboardingFlow.shell), isFalse,
        reason: 'Başlayan tur beklemeden düşer');
    expect(isSliderPeekAllowed(coordinator), isFalse,
        reason: 'Kapı yalnız "bekliyor"a bakıyor, "oynuyor"u kaçırıyor');
  });

  testWidgets('tur bitince kapı açılır', (tester) async {
    coordinator.startShowcaseOverride = (_) {};
    coordinator.requestTour(
      OnboardingFlow.shell,
      owner: Object(),
      keys: [GlobalKey()],
      isAlive: () => true,
      isReady: () => true,
    );
    await tester.pump();
    expect(isSliderPeekAllowed(coordinator), isFalse);

    coordinator.handleShowcaseIdle();
    await tester.pump();

    expect(isSliderPeekAllowed(coordinator), isTrue);
  });

  testWidgets('tur zaten görülmüşse kapı baştan açıktır', (tester) async {
    await coordinator.markSeen(OnboardingFlow.shell);
    coordinator.requestTour(
      OnboardingFlow.shell,
      owner: Object(),
      keys: [GlobalKey()],
      isAlive: () => true,
      isReady: () => false,
    );

    expect(coordinator.isPending(OnboardingFlow.shell), isFalse,
        reason: 'Görülmüş tur hiç istenmez');
    expect(isSliderPeekAllowed(coordinator), isTrue);
  });

  testWidgets('kabuk turu dışındaki bir tur kapıyı KİLİTLEMEZ', (tester) async {
    // Form turları kaydırıcının üstünü örtmüyor; yalnız oynarken bloklanır.
    coordinator.requestTour(
      OnboardingFlow.transactionsAdd,
      owner: Object(),
      keys: [GlobalKey()],
      isAlive: () => true,
      isReady: () => false,
    );

    expect(coordinator.isPending(OnboardingFlow.transactionsAdd), isTrue);
    expect(isSliderPeekAllowed(coordinator), isTrue);
  });
}
