import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/goal_form_sheet.dart';
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
      home: Scaffold(body: child),
    );
  }

  testWidgets('adsız ya da sıfır hedefli kayıt reddedilir',
      (WidgetTester tester) async {
    GoalEntity? saved;
    await tester.pumpWidget(buildTestableWidget(GoalFormSheet(
      userId: 'u',
      walletId: 'w',
      walletCurrency: 'TRY',
      onSave: (g) => saved = g,
    )));

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Hedef adı girin'), findsOneWidget);
    expect(saved, isNull);

    await tester.enterText(find.byType(TextField).first, 'Ev peşinatı');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Geçerli bir hedef tutar girin'), findsOneWidget);
    expect(saved, isNull);
  });

  testWidgets('yeni hedef kaydedilir', (WidgetTester tester) async {
    GoalEntity? saved;
    await tester.pumpWidget(buildTestableWidget(GoalFormSheet(
      userId: 'u',
      walletId: 'w',
      walletCurrency: 'TRY',
      onSave: (g) => saved = g,
    )));

    await tester.enterText(find.byType(TextField).first, 'Ev peşinatı');
    await tester.enterText(find.byType(TextField).last, '600.000');
    await tester.tap(find.text('Düğün'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.name, 'Ev peşinatı');
    expect(saved!.targetAmount, 600000.0);
    expect(saved!.category, 'dugun');
    expect(saved!.userId, 'u');
    expect(saved!.walletId, 'w');
  });

  testWidgets('düzenlemede kimlik ve oluşturma tarihi korunur',
      (WidgetTester tester) async {
    final existing = GoalEntity(
      id: 'goal_1',
      userId: 'u',
      walletId: 'w',
      name: 'Ev',
      targetAmount: 100000,
      category: 'ev',
      color: Colors.teal,
      createdAt: DateTime(2026, 1, 1),
    );
    GoalEntity? saved;

    await tester.pumpWidget(buildTestableWidget(GoalFormSheet(
      userId: 'u',
      walletId: 'w',
      walletCurrency: 'TRY',
      goalToEdit: existing,
      onSave: (g) => saved = g,
    )));

    expect(find.text('Hedefi düzenle'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Ev peşinatı');
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();

    expect(saved!.id, 'goal_1');
    expect(saved!.createdAt, DateTime(2026, 1, 1));
    expect(saved!.name, 'Ev peşinatı');
    expect(saved!.targetAmount, 100000);
  });
}
