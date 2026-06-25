import 'package:cunehat/features/investments/presentation/widgets/goal_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalCategory Model Tests', () {
    test('GoalCategory.byKey resolves correct categories', () {
      expect(GoalCategory.byKey('ev')?.label, 'Ev');
      expect(GoalCategory.byKey('dugun')?.label, 'Düğün');
      expect(GoalCategory.byKey('araba')?.label, 'Araba');
      expect(GoalCategory.byKey('acil_fon')?.label, 'Acil Fon');
      expect(GoalCategory.byKey('egitim')?.label, 'Eğitim');
      expect(GoalCategory.byKey('diger')?.label, 'Diğer');

      expect(GoalCategory.byKey(null), isNull);
      expect(GoalCategory.byKey('unknown_key'), isNull);
    });
  });

  group('GoalCategorySelector Widget Tests', () {
    Widget buildTestableWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('renders all GoalCategory options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          GoalCategorySelector(
            selectedKey: null,
            onChanged: (_) {},
            accentColor: Colors.teal,
          ),
        ),
      );

      // Verify all labels are rendered
      expect(find.text('Ev'), findsOneWidget);
      expect(find.text('Düğün'), findsOneWidget);
      expect(find.text('Araba'), findsOneWidget);
      expect(find.text('Acil Fon'), findsOneWidget);
      expect(find.text('Eğitim'), findsOneWidget);
      expect(find.text('Diğer'), findsOneWidget);

      // Verify chips are present as ChoiceChips
      expect(find.byType(ChoiceChip), findsNWidgets(6));
    });

    testWidgets('calls onChanged with category key when chip is selected',
        (WidgetTester tester) async {
      String? changedKey;
      var called = false;

      await tester.pumpWidget(
        buildTestableWidget(
          GoalCategorySelector(
            selectedKey: null,
            onChanged: (key) {
              changedKey = key;
              called = true;
            },
            accentColor: Colors.teal,
          ),
        ),
      );

      // Tap 'Ev' chip
      await tester.tap(find.text('Ev'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(changedKey, 'ev');
    });

    testWidgets('calls onChanged with null when selected chip is deselected',
        (WidgetTester tester) async {
      String? changedKey;
      var called = false;

      await tester.pumpWidget(
        buildTestableWidget(
          GoalCategorySelector(
            selectedKey: 'ev',
            onChanged: (key) {
              changedKey = key;
              called = true;
            },
            accentColor: Colors.teal,
          ),
        ),
      );

      // Tap the already selected 'Ev' chip to deselect it
      await tester.tap(find.text('Ev'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(changedKey, isNull);
    });
  });
}
