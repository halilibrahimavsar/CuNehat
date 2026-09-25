import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/core/shared/motion/period_transition.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(DateTime start, {bool reduce = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Builder(
            builder: (context) => PeriodTransition(
              periodStart: start,
              child: Text('dönem ${start.month}'),
            ),
          ),
        ),
      );

  group('PeriodTransition', () {
    testWidgets('dönem değişince eski ve yeni içerik bir süre BİRLİKTE geçer',
        (tester) async {
      await tester.pumpWidget(host(DateTime(2026, 9)));
      await tester.pumpWidget(host(DateTime(2026, 8)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('dönem 9'), findsOneWidget);
      expect(find.text('dönem 8'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('dönem 9'), findsNothing);
      expect(find.text('dönem 8'), findsOneWidget);
    });

    testWidgets('azaltılmış harekette içerik ANINDA değişir', (tester) async {
      await tester.pumpWidget(host(DateTime(2026, 9), reduce: true));
      await tester.pumpWidget(host(DateTime(2026, 8), reduce: true));
      await tester.pump();
      expect(find.text('dönem 9'), findsNothing);
      expect(find.text('dönem 8'), findsOneWidget);
    });

    testWidgets('geri giden dönem SOLDAN, ileri giden SAĞDAN gelir',
        (tester) async {
      Future<double> incomingDx(DateTime from, DateTime to) async {
        await tester.pumpWidget(host(from));
        await tester.pumpWidget(host(to));
        await tester.pump(const Duration(milliseconds: 60));
        final slide = tester.widget<SlideTransition>(find
            .ancestor(
                of: find.text('dönem ${to.month}'),
                matching: find.byType(SlideTransition))
            .first);
        final dx = slide.position.value.dx;
        await tester.pumpAndSettle();
        return dx;
      }

      expect(await incomingDx(DateTime(2026, 9), DateTime(2026, 8)),
          lessThan(0));
      expect(await incomingDx(DateTime(2026, 8), DateTime(2026, 10)),
          greaterThan(0));
    });
  });

  test('AppMotion.d azaltılmış harekette sıfırdır', () {
    expect(const AppMotion(reduced: true).d(AppMotion.medium), Duration.zero);
    expect(const AppMotion(reduced: false).d(AppMotion.medium),
        AppMotion.medium);
  });

  test('kabuk: azaltılmış harekette küp geçişleri anında olur', () {
    final nav = HomeNavigationController(const TestVSync());
    addTearDown(nav.dispose);
    expect(nav.viewStack.controller.duration, kSubViewTransitionDuration);

    nav.reduceMotion = true;
    expect(nav.viewStack.controller.duration, Duration.zero);
    expect(nav.horizontalController.duration, Duration.zero);

    nav.reduceMotion = false;
    expect(nav.viewStack.controller.duration, kSubViewTransitionDuration);
  });
}
