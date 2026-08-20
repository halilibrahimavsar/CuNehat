import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_widgets/category_filter_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryEntity _cat(String id, String name,
        {String? parentId, bool isExpense = true, int sortOrder = 0}) =>
    CategoryEntity(
      id: id,
      name: name,
      iconName: 'shopping_cart',
      isExpense: isExpense,
      parentId: parentId,
      sortOrder: sortOrder,
    );

// Ağaç sırası: kök, hemen ardından çocukları (flattenTree ile aynı).
final _expense = [
  _cat('market', 'Market', sortOrder: 0),
  _cat('manav', 'Manav', parentId: 'market', sortOrder: 0),
  _cat('kasap', 'Kasap', parentId: 'market', sortOrder: 1),
  _cat('fatura', 'Fatura', sortOrder: 1),
  _cat('internet', 'İnternet', parentId: 'fatura', sortOrder: 0),
  _cat('kira', 'Kira', sortOrder: 2),
];

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  Widget tree({
    Set<String> selected = const {},
    required ValueChanged<Set<String>> onChanged,
  }) =>
      CategoryFilterTree(
        incomeCategories: const [],
        expenseCategories: _expense,
        selected: selected,
        isLoading: false,
        onChanged: onChanged,
        showTypeHeaders: false,
        accent: Colors.blue,
      );

  testWidgets('kökler görünür, alt kategoriler kapalı başlar', (tester) async {
    await tester.pumpWidget(wrap(tree(onChanged: (_) {})));

    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Fatura'), findsOneWidget);
    expect(find.text('Kira'), findsOneWidget);
    // 43 kategorilik bir listede duvar oluşmaması için çocuklar gizli.
    expect(find.text('Manav'), findsNothing);
    expect(find.text('İnternet'), findsNothing);
  });

  testWidgets('gruba dokunmak alt kategorileri açar', (tester) async {
    await tester.pumpWidget(wrap(tree(onChanged: (_) {})));

    await tester.tap(find.text('Market'));
    await tester.pump();

    expect(find.text('Manav'), findsOneWidget);
    expect(find.text('Kasap'), findsOneWidget);
    expect(find.text('İnternet'), findsNothing);
  });

  testWidgets('kök kutusu tüm alt ağacı seçer', (tester) async {
    Set<String>? emitted;
    await tester.pumpWidget(wrap(tree(onChanged: (s) => emitted = s)));

    // Market satırının kutusu (ilk Checkbox).
    await tester.tap(find.byType(Checkbox).first);
    expect(emitted, {'market', 'manav', 'kasap'});
  });

  testWidgets('alt ağacın tamamı seçiliyken kök kutusu hepsini kaldırır',
      (tester) async {
    Set<String>? emitted;
    await tester.pumpWidget(wrap(tree(
      selected: const {'market', 'manav', 'kasap', 'kira'},
      onChanged: (s) => emitted = s,
    )));

    await tester.tap(find.byType(Checkbox).first);
    expect(emitted, {'kira'});
  });

  testWidgets('yalnız bir çocuk seçiliyken kök kutusu belirsiz (null) durur',
      (tester) async {
    await tester.pumpWidget(wrap(tree(
      selected: const {'manav'},
      onChanged: (_) {},
    )));

    final marketCheckbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
    expect(marketCheckbox.value, isNull,
        reason: 'kısmi seçim üç durumlu kutuda belirsiz görünmeli');
  });

  testWidgets('kısmi seçili kök kutusu alt ağacın TAMAMINI seçer',
      (tester) async {
    Set<String>? emitted;
    await tester.pumpWidget(wrap(tree(
      selected: const {'manav'},
      onChanged: (s) => emitted = s,
    )));

    await tester.tap(find.byType(Checkbox).first);
    expect(emitted, {'manav', 'market', 'kasap'});
  });

  testWidgets('çocuk seçimi yalnız kendisini ekler', (tester) async {
    Set<String>? emitted;
    await tester.pumpWidget(wrap(tree(onChanged: (s) => emitted = s)));

    await tester.tap(find.text('Market'));
    await tester.pump();
    await tester.tap(find.text('Manav'));

    expect(emitted, {'manav'});
  });

  group('arama', () {
    testWidgets('eşleşen çocuk grubu otomatik açar', (tester) async {
      await tester.pumpWidget(wrap(tree(onChanged: (_) {})));

      await tester.enterText(find.byType(TextField), 'manav');
      await tester.pump();

      expect(find.text('Manav'), findsOneWidget);
      expect(find.text('Market'), findsOneWidget,
          reason: 'ana kategori bağlam');
      expect(find.text('Kira'), findsNothing);
      expect(find.text('Kasap'), findsNothing,
          reason: 'eşleşmeyen kardeş gizlenmeli');
    });

    testWidgets('Türkçe büyük İ ile arama küçük harfli kategoriyi bulur',
        (tester) async {
      // Düz toLowerCase() ile "İNTERNET" → "i̇nternet" olur ve eşleşmez.
      await tester.pumpWidget(wrap(tree(onChanged: (_) {})));

      await tester.enterText(find.byType(TextField), 'İNTERNET');
      await tester.pump();

      expect(find.text('İnternet'), findsOneWidget);
    });

    testWidgets('eşleşme yoksa açıklama gösterilir', (tester) async {
      await tester.pumpWidget(wrap(tree(onChanged: (_) {})));

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();

      expect(find.text('Eşleşen kategori yok'), findsOneWidget);
    });

    testWidgets('ana kategori eşleşirse çocuklarıyla birlikte kalır',
        (tester) async {
      await tester.pumpWidget(wrap(tree(onChanged: (_) {})));

      await tester.enterText(find.byType(TextField), 'market');
      await tester.pump();

      expect(find.text('Manav'), findsOneWidget);
      expect(find.text('Kasap'), findsOneWidget);
    });
  });

  testWidgets('temizle düğmesi tüm seçimi boşaltır', (tester) async {
    Set<String>? emitted;
    await tester.pumpWidget(wrap(tree(
      selected: const {'market', 'kira'},
      onChanged: (s) => emitted = s,
    )));

    await tester.tap(find.text('Temizle'));
    expect(emitted, isEmpty);
  });

  testWidgets('kategori yoksa bilgi notu çıkar', (tester) async {
    await tester.pumpWidget(wrap(CategoryFilterTree(
      incomeCategories: const [],
      expenseCategories: const [],
      selected: const {},
      isLoading: false,
      onChanged: (_) {},
      showTypeHeaders: false,
      accent: Colors.blue,
    )));

    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });
}
