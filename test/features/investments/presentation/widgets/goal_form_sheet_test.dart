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

  group('özel kategori', () {
    /// Hedef kategorisi altı hazır seçeneğe kilitliydi; kullanıcı "Tekne"
    /// diye kendi kategorisini yazamıyordu. `GoalEntity.category` zaten
    /// serbest `String` olduğu için ŞEMA DEĞİŞMEDİ — açılan tek şey arayüz.
    testWidgets('yazılan metin kategori olarak kaydedilir', (tester) async {
      GoalEntity? saved;
      await tester.pumpWidget(buildTestableWidget(GoalFormSheet(
        userId: 'u',
        walletId: 'w',
        walletCurrency: 'TRY',
        onSave: (g) => saved = g,
      )));

      await tester.enterText(find.byType(TextField).first, 'Tekne fonu');
      await tester.enterText(find.byType(TextField).last, '250.000');

      await tester.tap(find.text('Özel'));
      await tester.pumpAndSettle();

      // Özel kip açılınca metin alanı belirir (hint'iyle bulunur).
      final customField = find.byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.hintText == 'Kendi kategorin (ör. Tekne)');
      expect(customField, findsOneWidget);
      await tester.enterText(customField, 'Tekne');

      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.category, 'Tekne');
    });

    testWidgets('özel kip açıkken boş metin reddedilir', (tester) async {
      GoalEntity? saved;
      await tester.pumpWidget(buildTestableWidget(GoalFormSheet(
        userId: 'u',
        walletId: 'w',
        walletCurrency: 'TRY',
        onSave: (g) => saved = g,
      )));

      await tester.enterText(find.byType(TextField).first, 'Bir hedef');
      await tester.enterText(find.byType(TextField).last, '1.000');
      await tester.tap(find.text('Özel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      // Sessizce boş kategori kaydedilseydi kart bayrak ikonuna düşer,
      // kullanıcı sebebini hiç anlamazdı.
      expect(find.text('Özel kategori adı boş olamaz'), findsOneWidget);
      expect(saved, isNull);
    });

    testWidgets('düzenlemede özel kategori geri yüklenir', (tester) async {
      final existing = GoalEntity(
        id: 'goal_1',
        userId: 'u',
        walletId: 'w',
        name: 'Tekne',
        targetAmount: 100000,
        category: 'Yelkenli',
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

      // Alan önceden dolu gelmeli: gelmezse kullanıcı her düzenlemede
      // kategorisini yeniden yazmak zorunda kalır.
      final customField = find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'Yelkenli');
      expect(customField, findsOneWidget);

      await tester.tap(find.text('Güncelle'));
      await tester.pumpAndSettle();
      expect(saved!.category, 'Yelkenli');
    });

    testWidgets('özelden hazır seçeneğe dönülebilir', (tester) async {
      final existing = GoalEntity(
        id: 'goal_1',
        userId: 'u',
        walletId: 'w',
        name: 'Tekne',
        targetAmount: 100000,
        category: 'Yelkenli',
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

      await tester.tap(find.text('Araba'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Güncelle'));
      await tester.pumpAndSettle();

      expect(saved!.category, 'araba');
    });
  });
}
