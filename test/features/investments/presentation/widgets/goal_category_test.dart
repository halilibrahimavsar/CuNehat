import 'package:cunehat/features/investments/presentation/widgets/goal_category.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalCategory Model Tests', () {
    test('GoalCategory.byKey resolves correct categories', () {
      // Etiket artık sabit metin değil; anahtar → ikon eşlemesi burada,
      // metin l10n'da (widget testinde doğrulanıyor).
      expect(GoalCategory.byKey('ev')?.icon, Icons.home_rounded);
      expect(GoalCategory.byKey('dugun')?.icon, Icons.favorite_rounded);
      expect(GoalCategory.byKey('araba')?.icon, Icons.directions_car_rounded);
      expect(GoalCategory.byKey('acil_fon')?.icon,
          Icons.health_and_safety_rounded);
      expect(GoalCategory.byKey('egitim')?.icon, Icons.school_rounded);
      expect(GoalCategory.byKey('diger')?.icon, Icons.flag_rounded);

      expect(GoalCategory.byKey(null), isNull);
      expect(GoalCategory.byKey('unknown_key'), isNull);
    });
  });

  group('GoalCategorySelector Widget Tests', () {
    Widget buildTestableWidget(Widget child) {
      return MaterialApp(
        // Kategori etiketleri artık l10n'dan geliyor; delege olmadan
        // context.l10n çözülmez.
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
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
