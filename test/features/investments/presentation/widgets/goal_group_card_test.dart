import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/goal_progress.dart';
import 'package:cunehat/features/investments/presentation/widgets/goal_group_card.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: const Locale('tr'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  final goal = GoalEntity(
    id: 'g',
    userId: 'u',
    walletId: 'w',
    name: 'Kızımın düğünü için altın birikimi',
    targetAmount: 1250000,
    category: 'dugun',
    color: Colors.teal,
    createdAt: DateTime(2026, 1, 1),
  );

  final member = InvestmentEntity(
    id: 'i',
    userId: 'u',
    walletId: 'w',
    name: 'Düğün Altınları',
    amount: 900000,
    currentValue: 987654.32,
    type: InvestmentType.gold,
    color: Colors.amber,
    dateAdded: DateTime(2026, 1, 1),
    symbol: 'gram-altin',
    quantity: 224.5,
    goalId: 'g',
  );

  Widget card({bool expanded = false, VoidCallback? onAddAsset}) =>
      GoalGroupCard(
        progress: GoalProgress.from(goal, [member]),
        currency: 'TRY',
        expanded: expanded,
        onToggle: () {},
        onMemberTap: (_) {},
        onAddAsset: onAddAsset ?? () {},
        onEdit: () {},
        onDelete: () {},
      );

  testWidgets('uzun ad ve milyonluk tutarlar 360dp ekranda taşmaz',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget(card(expanded: true)));
    await tester.pump();

    // Üye kartı hedefin içinde daha dar bir alana giriyor (204px); serbest
    // sütunlar orada 124px taşıyordu.
    expect(tester.takeException(), isNull);
    expect(find.byType(InvestmentCard), findsOneWidget);
  });

  testWidgets(
      'başlık ilerlemeyi ve üye sayısını gösterir, kapalıyken '
      'üyeleri çizmez', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableWidget(card()));
    await tester.pump();

    expect(find.text('Kızımın düğünü için altın birikimi'), findsOneWidget);
    expect(find.text('987.654,32 ₺ / 1.250.000,00 ₺'), findsOneWidget);
    expect(find.text('%79'), findsOneWidget);
    expect(find.text('1 varlık'), findsOneWidget);
    expect(find.text('Kalan 262.345,68 ₺'), findsOneWidget);
    expect(find.byType(InvestmentCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hedefe ulaşılınca kalan yerine kutlama metni yazar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final reached = GoalProgress.from(
      goal.copyWith(targetAmount: 500000),
      [member],
    );

    await tester.pumpWidget(buildTestableWidget(GoalGroupCard(
      progress: reached,
      currency: 'TRY',
      expanded: false,
      onToggle: () {},
      onMemberTap: (_) {},
      onAddAsset: () {},
      onEdit: () {},
      onDelete: () {},
    )));
    await tester.pump();

    expect(find.text('Hedefe ulaşıldı'), findsOneWidget);
    // Oran 1'de sınırlanır: %197 yazmaz.
    expect(find.text('%100'), findsOneWidget);
  });

  testWidgets('açıkken üye ve "varlık ekle" görünür',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var addTapped = false;
    await tester.pumpWidget(buildTestableWidget(
      card(expanded: true, onAddAsset: () => addTapped = true),
    ));
    await tester.pump();

    expect(find.text('Düğün Altınları'), findsOneWidget);
    await tester.tap(find.text('Bu hedefe varlık ekle'));
    await tester.pump();
    expect(addTapped, isTrue);
  });
}
