import 'package:cunehat/core/shared/animations/unified_cube_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CubeDirection', () {
    test('values exist', () {
      expect(CubeDirection.values.length, 4);
      expect(CubeDirection.left.index, 0);
      expect(CubeDirection.right.index, 1);
      expect(CubeDirection.up.index, 2);
      expect(CubeDirection.down.index, 3);
    });
  });

  group('UnifiedCubeTransition', () {
    late AnimationController controller;

    setUp(() {
      controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 100),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders both outgoing and incoming views at midpoint',
        (tester) async {
      final outgoing = const Text('Outgoing');
      final incoming = const Text('Incoming');

      controller.value = 0.5; // midpoint to show both

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedCubeTransition(
              controller: controller,
              outgoingView: outgoing,
              incomingView: incoming,
              direction: CubeDirection.left,
            ),
          ),
        ),
      );

      expect(find.text('Outgoing'), findsOneWidget);
      expect(find.text('Incoming'), findsOneWidget);
    });

    testWidgets('respects useFade parameter at midpoint', (tester) async {
      final outgoing = const Text('Outgoing');
      final incoming = const Text('Incoming');

      controller.value = 0.5; // midpoint to show both

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedCubeTransition(
              controller: controller,
              outgoingView: outgoing,
              incomingView: incoming,
              direction: CubeDirection.right,
              useFade: false,
            ),
          ),
        ),
      );

      expect(find.text('Outgoing'), findsOneWidget);
      expect(find.text('Incoming'), findsOneWidget);
    });

    testWidgets(
        'hides outgoing view and shows incoming view when animation is at 1.0',
        (tester) async {
      final outgoing = const Text('Outgoing');
      final incoming = const Text('Incoming');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedCubeTransition(
              controller: controller,
              outgoingView: outgoing,
              incomingView: incoming,
              direction: CubeDirection.up,
            ),
          ),
        ),
      );

      controller.value = 1.0;
      await tester.pump();

      expect(find.text('Outgoing'), findsNothing);
      expect(find.text('Incoming'), findsOneWidget);
    });

    testWidgets(
        'shows outgoing view and hides incoming view when animation is at 0.0',
        (tester) async {
      final outgoing = const Text('Outgoing');
      final incoming = const Text('Incoming');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedCubeTransition(
              controller: controller,
              outgoingView: outgoing,
              incomingView: incoming,
              direction: CubeDirection.down,
            ),
          ),
        ),
      );

      controller.value = 0.0;
      await tester.pump();

      expect(find.text('Outgoing'), findsOneWidget);
      expect(find.text('Incoming'), findsNothing);
    });
  });

  group('VerticalListTransitionManager', () {
    testWidgets('initial state', (tester) async {
      final manager = VerticalListTransitionManager(const TestVSync());
      expect(manager.isTransitioning, isFalse);
      expect(manager.isAtMainView, isTrue);
      expect(manager.currentIndex, 0);
      expect(manager.views, isEmpty);
      manager.dispose();
    });

    testWidgets('setViews updates views', (tester) async {
      final manager = VerticalListTransitionManager(const TestVSync());
      final view1 = const Text('View 1');
      final view2 = const Text('View 2');
      manager.setViews([view1, view2]);

      expect(manager.views.length, 2);
      expect(manager.currentIndex, 0);
      manager.dispose();
    });

    testWidgets('setViews resets index if it goes out of bounds',
        (tester) async {
      final manager = VerticalListTransitionManager(const TestVSync());
      manager.setViews([const Text('View 1')]);
      manager.setViews([]);
      expect(manager.currentIndex, 0);
      manager.dispose();
    });

    testWidgets('navigateTo changes index and starts transitioning',
        (tester) async {
      final manager = VerticalListTransitionManager(const TestVSync());
      final view1 = const Text('View 1');
      final view2 = const Text('View 2');
      manager.setViews([view1, view2]);

      bool listenerCalled = false;
      manager.addListener(() {
        listenerCalled = true;
      });

      final future = manager.navigateTo(1);
      expect(manager.isTransitioning, isTrue);
      expect(manager.currentIndex, 1);
      expect(manager.isAtMainView, isFalse);
      expect(listenerCalled, isTrue);

      await tester.pumpAndSettle();
      await future;
      expect(manager.isTransitioning, isFalse);
      manager.dispose();
    });

    testWidgets('navigateTo ignores invalid or same index', (tester) async {
      final manager = VerticalListTransitionManager(const TestVSync());
      manager.setViews([const Text('View 1'), const Text('View 2')]);

      // Same index
      await manager.navigateTo(0);
      expect(manager.isTransitioning, isFalse);

      // Negative index
      await manager.navigateTo(-1);
      expect(manager.isTransitioning, isFalse);

      // Out of bounds
      await manager.navigateTo(5);
      expect(manager.isTransitioning, isFalse);
      manager.dispose();
    });

    testWidgets('queues navigateTo if called while transitioning',
        (tester) async {
      final manager = VerticalListTransitionManager(const TestVSync());
      manager.setViews([
        const Text('View 1'),
        const Text('View 2'),
        const Text('View 3'),
      ]);

      // Start transition 0 -> 1
      final f1 = manager.navigateTo(1);
      expect(manager.isTransitioning, isTrue);
      expect(manager.currentIndex, 1);

      // Request transition 1 -> 2 while transitioning
      final f2 = manager.navigateTo(2);

      // Settle everything
      await tester.pumpAndSettle();
      await f1;
      await f2;

      // Both transitions should have completed, ending at index 2
      expect(manager.isTransitioning, isFalse);
      expect(manager.currentIndex, 2);

      manager.dispose();
    });

    testWidgets('queues setViews if called while transitioning',
        (tester) async {
      final manager = VerticalListTransitionManager(const TestVSync());
      manager.setViews([const Text('View 1'), const Text('View 2')]);

      final f = manager.navigateTo(1);
      expect(manager.isTransitioning, isTrue);

      // Update views during transition
      manager.setViews(
          [const Text('View 1'), const Text('View 2'), const Text('View 3')]);
      expect(manager.views.length, 2); // Still old views

      await tester.pumpAndSettle();
      await f;
      expect(manager.views.length, 3); // Updated after transition completed
      manager.dispose();
    });

    testWidgets('buildTransition renders correctly', (tester) async {
      final manager = VerticalListTransitionManager(const TestVSync());
      final view1 = const Text('View 1');
      final view2 = const Text('View 2');
      manager.setViews([view1, view2]);

      // Not transitioning
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedBuilder(
              animation: manager,
              builder: (context, _) => manager.buildTransition(),
            ),
          ),
        ),
      );
      expect(find.text('View 1'), findsOneWidget);
      expect(find.text('View 2'), findsNothing);

      // Start transition
      final f = manager.navigateTo(1);

      // Pump a frame to start the animation
      await tester.pump();
      // Tick the animation to 50% completion (duration is 500ms by default, so 250ms)
      await tester.pump(const Duration(milliseconds: 250));

      // Should render transition stack containing both views at 50%
      expect(find.text('View 1'), findsOneWidget);
      expect(find.text('View 2'), findsOneWidget);

      await tester.pumpAndSettle();
      await f;

      // Transition complete, should render only current view
      expect(find.text('View 1'), findsNothing);
      expect(find.text('View 2'), findsOneWidget);

      manager.dispose();
    });

    testWidgets('buildTransition returns SizedBox.shrink if views empty',
        (tester) async {
      final manager = VerticalListTransitionManager(const TestVSync());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedBuilder(
              animation: manager,
              builder: (context, _) => manager.buildTransition(),
            ),
          ),
        ),
      );
      expect(find.byType(SizedBox), findsOneWidget);
      manager.dispose();
    });
  });
}
