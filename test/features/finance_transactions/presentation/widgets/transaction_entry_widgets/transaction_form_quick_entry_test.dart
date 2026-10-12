import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_fields.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../../support/wallet_category_stub.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

/// Hızlı giriş turu (11 Eki 2026): formun içinden tür değiştirme, "Kaydet ve
/// yeni", Bugün/Dün kısayolu, son kullanılan kategoriler ve "Yeniden ekle".
void main() {
  late _MockCategoryRepository categories;
  late AppLocalizations l10n;

  CategoryEntity cat(String id, {bool isExpense = true}) => CategoryEntity(
        id: id,
        name: id,
        iconName: 'fastfood',
        isExpense: isExpense,
      );

  // Şerit `sortOrder` → ada göre sıralı ve TEMBEL: 400dp'lik yüzeyde yalnız
  // ilk dört kök (Fatura, Giyim, Kira, Market) kurulur; testler onlara dokunur.
  final expenseCats = [
    for (final id in ['Market', 'Yemek', 'Ulaşım', 'Fatura', 'Kira', 'Giyim'])
      cat(id),
  ];
  final incomeCats = [cat('Maaş', isExpense: false)];

  setUpAll(() async {
    getIt.allowReassignment = true;
    ShowcaseView.register();
    l10n = await AppLocalizations.delegate.load(const Locale('tr'));
  });

  setUp(() {
    categories = _MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(categories);
    registerUncuratedWalletCategories(categories);
    when(() => categories.getCategories(true))
        .thenAnswer((_) async => expenseCats);
    when(() => categories.getCategories(false))
        .thenAnswer((_) async => incomeCats);
  });

  tearDown(getIt.reset);

  final amountField = find.byWidgetPredicate(
      (w) => w is TextField && w.keyboardType.decimal == true);

  Future<void> pumpForm(
    WidgetTester tester, {
    bool isExpense = true,
    TransactionEntity? initial,
    TransactionEntity? prefill,
    DateTime? initialDate,
    void Function(TransactionEntity, RecurringFrequency?)? onSave,
    void Function(List<TransactionEntity>, RecurringFrequency?)? onSaveAndNew,
  }) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: TransactionFormSheet(
              isExpense: isExpense,
              walletId: 'w1',
              userId: 'u1',
              initialTransaction: initial,
              prefill: prefill,
              initialDate: initialDate,
              onSave: onSave ?? (_, __) {},
              onSaveAndNew: onSaveAndNew,
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TransactionEntity existing({
    TransactionTypeModel type = TransactionTypeModel.expense,
    String tag = 'Market',
  }) =>
      TransactionEntity(
        id: 'tx-1',
        userId: 'u1',
        walletId: 'w1',
        title: 'Haftalık alışveriş',
        tag: tag,
        amount: 480.5,
        date: DateTime(2026, 9, 5, 18, 30),
        type: type,
      );

  group('tür formun içinden değişir', () {
    testWidgets('Gelir seçilince kategori listesi gelire döner ve kayıt gelir',
        (tester) async {
      TransactionEntity? saved;
      await pumpForm(tester, onSave: (t, _) => saved = t);

      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Maaş'), findsNothing);

      await tester.tap(find.text(l10n.menuIncome));
      await tester.pumpAndSettle();

      expect(find.text('Maaş'), findsOneWidget);
      expect(find.text('Market'), findsNothing);

      await tester.enterText(amountField, '1000');
      await tester.tap(find.text('Maaş'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.kaydet));
      await tester.pump(const Duration(milliseconds: 100));

      expect(saved!.type, TransactionTypeModel.income);
      expect(saved!.tag, 'Maaş');
    });

    testWidgets('tür değişince seçili kategori SIFIRLANIR', (tester) async {
      var saveCalled = false;
      await pumpForm(tester, onSave: (_, __) => saveCalled = true);

      await tester.enterText(amountField, '50');
      await tester.tap(find.text('Market'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.menuIncome));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.kaydet));
      await tester.pumpAndSettle();

      expect(saveCalled, isFalse,
          reason: 'gider kategorisi gelir kaydına taşınmamalı');
      expect(find.text(l10n.kategoriSecmeUyarisi), findsOneWidget);
    });

    testWidgets('DÜZENLEMEDE de tür değişir; kayıt kimliğini korur',
        (tester) async {
      TransactionEntity? saved;
      await pumpForm(tester, initial: existing(), onSave: (t, _) => saved = t);

      await tester.tap(find.text(l10n.menuIncome));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maaş'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.guncelle));
      await tester.pump(const Duration(milliseconds: 100));

      expect(saved!.id, 'tx-1');
      expect(saved!.type, TransactionTypeModel.income);
      expect(saved!.amount, 480.5);
    });
  });

  group('Kaydet ve yeni', () {
    testWidgets('kaydı yazar, sayfayı açık bırakır ve formu sıfırlar',
        (tester) async {
      final rows = <TransactionEntity>[];
      var closed = false;
      await pumpForm(
        tester,
        onSave: (_, __) => closed = true,
        onSaveAndNew: (r, _) => rows.addAll(r),
      );

      await tester.enterText(amountField, '120');
      await tester.tap(find.text('Market'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.kaydetVeYeni));
      await tester.pumpAndSettle();

      expect(rows, hasLength(1));
      expect(rows.single.amount, 120);
      expect(closed, isFalse, reason: 'kapatan yol çağrılmamalı');

      // Form bir sonraki kayda hazır.
      expect(tester.widget<TextField>(amountField).controller!.text, isEmpty);
      expect(find.textContaining('Market ·'), findsOneWidget,
          reason: 'az önceki kaydın onayı görünmeli');

      // Kategori taşınmaz: seçmeden ikinci kayıt reddedilir.
      await tester.enterText(amountField, '75');
      await tester.pumpAndSettle();
      expect(find.textContaining('Market ·'), findsNothing,
          reason: 'yeni tutar yazılınca onay çekilir');
      await tester.tap(find.text(l10n.kaydetVeYeni));
      await tester.pumpAndSettle();
      expect(rows, hasLength(1));
      expect(find.text(l10n.kategoriSecmeUyarisi), findsOneWidget);

      await tester.tap(find.text('Kira'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.kaydetVeYeni));
      await tester.pumpAndSettle();
      expect(rows.map((t) => t.tag), ['Market', 'Kira']);
    });

    testWidgets('seçilen tarih bir sonraki kayıtta KALIR', (tester) async {
      final rows = <TransactionEntity>[];
      await pumpForm(tester, onSaveAndNew: (r, _) => rows.addAll(r));

      await tester.tap(find.byKey(const ValueKey('tx-day-yesterday')));
      await tester.pumpAndSettle();

      for (final tag in ['Market', 'Kira']) {
        await tester.enterText(amountField, '10');
        await tester.tap(find.text(tag));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.kaydetVeYeni));
        await tester.pumpAndSettle();
      }

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(rows.map((t) => t.date.day), everyElement(yesterday.day));
    });

    testWidgets('düzenlemede düğme YOK', (tester) async {
      await pumpForm(tester, initial: existing(), onSaveAndNew: (_, __) {});
      expect(find.text(l10n.kaydetVeYeni), findsNothing);
    });

    testWidgets('geri çağrı verilmezse düğme YOK', (tester) async {
      await pumpForm(tester);
      expect(find.text(l10n.kaydetVeYeni), findsNothing);
    });
  });

  group('Bugün · Dün', () {
    testWidgets('Dün tek dokunuş; saat korunur', (tester) async {
      TransactionEntity? saved;
      await pumpForm(tester, onSave: (t, _) => saved = t);

      final before = DateTime.now();
      await tester.tap(find.byKey(const ValueKey('tx-day-yesterday')));
      await tester.pumpAndSettle();

      await tester.enterText(amountField, '10');
      await tester.tap(find.text('Market'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.kaydet));
      await tester.pump(const Duration(milliseconds: 100));

      final yesterday = before.subtract(const Duration(days: 1));
      expect(saved!.date.year, yesterday.year);
      expect(saved!.date.month, yesterday.month);
      expect(saved!.date.day, yesterday.day);
      expect(saved!.date.hour, before.hour);
    });

    testWidgets('Bugün geri döndürür', (tester) async {
      TransactionEntity? saved;
      await pumpForm(tester, onSave: (t, _) => saved = t);

      await tester.tap(find.byKey(const ValueKey('tx-day-yesterday')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tx-day-today')));
      await tester.pumpAndSettle();

      await tester.enterText(amountField, '10');
      await tester.tap(find.text('Market'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.kaydet));
      await tester.pump(const Duration(milliseconds: 100));

      expect(saved!.date.day, DateTime.now().day);
    });
  });

  group('son kullanılanlar', () {
    late _MockTransactionsRepository ledger;

    TransactionEntity past(String tag, int day) => TransactionEntity(
          id: 'p-$tag-$day',
          userId: 'u1',
          walletId: 'w1',
          title: tag,
          tag: tag,
          amount: 10,
          date: DateTime(2026, 9, day),
          type: TransactionTypeModel.expense,
        );

    setUp(() {
      ledger = _MockTransactionsRepository();
      getIt.registerSingleton<TransactionsRepository>(ledger);
    });

    final recents = find.byKey(const ValueKey('tx-recent-categories'));

    testWidgets('en son kullanılan kategoriler şeridin önünde, seçilebilir',
        (tester) async {
      // Yemek ve Ulaşım şeridin ilk ekranında YOK (5. ve 6. kök): satırın
      // var olma sebebi tam da bunlar.
      when(() => ledger.getTransactions(userId: 'u1', walletId: 'w1'))
          .thenAnswer((_) async => Right([
                past('Ulaşım', 1),
                past('Yemek', 20),
                past('Fatura', 12),
              ]));
      TransactionEntity? saved;
      await pumpForm(tester, onSave: (t, _) => saved = t);

      expect(recents, findsOneWidget);
      final labels = tester
          .widgetList<Text>(
              find.descendant(of: recents, matching: find.byType(Text)))
          .map((t) => t.data)
          .toList();
      expect(labels, ['Yemek', 'Fatura', 'Ulaşım']);

      await tester.enterText(amountField, '900');
      await tester
          .tap(find.descendant(of: recents, matching: find.text('Yemek')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.kaydet));
      await tester.pump(const Duration(milliseconds: 100));

      expect(saved!.tag, 'Yemek');
    });

    testWidgets('hepsi şeridin ilk ekranında zaten duruyorsa satır YOK',
        (tester) async {
      when(() => ledger.getTransactions(userId: 'u1', walletId: 'w1'))
          .thenAnswer((_) async => Right([
                past('Kira', 1),
                past('Giyim', 20),
                past('Fatura', 12),
              ]));
      await pumpForm(tester);
      expect(recents, findsNothing);
    });

    testWidgets('defter boşsa satır yer kaplamaz', (tester) async {
      when(() => ledger.getTransactions(userId: 'u1', walletId: 'w1'))
          .thenAnswer((_) async => const Right([]));
      await pumpForm(tester);
      expect(recents, findsNothing);
    });

    testWidgets('kategori sayısı şeride sığıyorsa satır gösterilmez',
        (tester) async {
      when(() => categories.getCategories(true))
          .thenAnswer((_) async => [cat('Market'), cat('Yemek')]);
      when(() => ledger.getTransactions(userId: 'u1', walletId: 'w1'))
          .thenAnswer((_) async => Right([past('Market', 1)]));
      await pumpForm(tester);
      expect(recents, findsNothing);
    });
  });

  group('yeniden ekle', () {
    testWidgets('içerik dolu gelir; YENİ kayıt, bugünün tarihiyle',
        (tester) async {
      TransactionEntity? saved;
      await pumpForm(tester, prefill: existing(), onSave: (t, _) => saved = t);

      expect(find.text(l10n.kaydet), findsOneWidget,
          reason: 'düzenleme değil, yeni kayıt');

      await tester.tap(find.text(l10n.kaydet));
      await tester.pump(const Duration(milliseconds: 100));

      expect(saved!.id, isNull);
      expect(saved!.title, 'Haftalık alışveriş');
      expect(saved!.amount, 480.5);
      expect(saved!.tag, 'Market');
      expect(saved!.date.day, DateTime.now().day);
      expect(saved!.origin, TransactionOrigin.manual);
    });
  });

  group('tarihe hızlı giriş (gün başlığındaki "+")', () {
    testWidgets('form verilen GÜNE açılır; "Kaydet ve yeni" günü korur',
        (tester) async {
      final rows = <TransactionEntity>[];
      await pumpForm(
        tester,
        initialDate: DateTime(2026, 9, 3),
        onSaveAndNew: (r, _) => rows.addAll(r),
      );

      for (final (amount, category) in [('120', 'Market'), ('75', 'Kira')]) {
        await tester.enterText(amountField, amount);
        await tester.tap(find.text(category));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.kaydetVeYeni));
        await tester.pumpAndSettle();
      }

      // Aynı güne art arda kayıt: ikinci kayıt bugüne dönmez.
      expect(rows, hasLength(2));
      for (final row in rows) {
        expect(DateTime(row.date.year, row.date.month, row.date.day),
            DateTime(2026, 9, 3));
      }
    });

    testWidgets('düzenlemede yok sayılır: kaydın kendi tarihi korunur',
        (tester) async {
      TransactionEntity? saved;
      await pumpForm(
        tester,
        initial: existing(),
        initialDate: DateTime(2026, 1, 1),
        onSave: (t, _) => saved = t,
      );

      await tester.tap(find.text(l10n.guncelle));
      // Kayıttan sonra düğme dönen göstergeye geçer; sayfayı çağıran kapatır.
      await tester.pump(const Duration(milliseconds: 100));

      expect(saved!.date, DateTime(2026, 9, 5, 18, 30));
    });
  });
}
