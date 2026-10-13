import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_search_field.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/active_filter_chips.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

CombinedFilter _filter({
  DateTimeRange? range,
  Set<String> categories = const {},
  PriceRangeFilter? priceRange,
  String? search,
  FinanceMode mode = FinanceMode.compare,
  MovedMoneyFilter moved = MovedMoneyFilter.show,
  bool onlyWithReceipt = false,
  bool onlyImported = false,
}) {
  final r = range ?? monthRangeOf(DateTime(2026, 8, 1));
  return CombinedFilter(
    viewFilter: ViewFilter(
      financeMode: mode,
      startDate: r.start,
      endDate: r.end,
    ),
    dataFilter: DataFilter(
      selectedCategories: categories,
      priceRange: priceRange,
      searchQuery: search,
      movedMoney: moved,
      onlyWithReceipt: onlyWithReceipt,
      onlyImported: onlyImported,
    ),
  );
}

void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  Widget wrap(Widget child, {double width = 360}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: const Locale('tr'),
      // Yatay padding EKLENMEZ: çubuk artık kendi 16dp'sini taşıyor (sliver
      // delegate'i kaldırıldı). İki kat padding gerçekte olmayan bir 6px
      // taşma uyduruyordu.
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );
  }

  TransactionTopBar bar(
    CombinedFilter filter, {
    void Function(int)? onPeriodStep,
    VoidCallback? onClearCategories,
    VoidCallback? onClearPriceRange,
    VoidCallback? onClearSearch,
    ValueChanged<String>? onSearchChanged,
    ValueChanged<DataFilter>? onDataFilterChanged,
    Map<String, String> labels = const {},
    bool showTools = true,
  }) {
    return TransactionTopBar(
      filter: filter,
      showTools: showTools,
      categoryLabels: labels,
      onModeChanged: (_) {},
      onPeriodStep: onPeriodStep ?? (_) {},
      onPeriodPick: () {},
      onFilterTap: () {},
      onClearCategories: onClearCategories ?? () {},
      onClearPriceRange: onClearPriceRange ?? () {},
      onClearSearch: onClearSearch ?? () {},
      onClearAllFilters: () {},
      onSearchChanged: onSearchChanged ?? (_) {},
      onDataFilterChanged: onDataFilterChanged ?? (_) {},
    );
  }

  group('arama ve süzgeç yalnız aranacak bir şey varken', () {
    final search = find.byKey(const ValueKey('tx-search-open'));
    final filterButton = find.byKey(const ValueKey('tx-filter-open'));
    final period = find.byKey(const ValueKey('tx-period-bar'));

    testWidgets('kaydı olan cüzdanda ikisi de durur (varsayılan)',
        (tester) async {
      await tester.pumpWidget(wrap(bar(_filter())));
      await tester.pumpAndSettle();

      expect(search, findsOneWidget);
      expect(filterButton, findsOneWidget);
    });

    testWidgets('boş cüzdanda ikisi de yok; dönem çubuğu satırı doldurur',
        (tester) async {
      await tester.pumpWidget(wrap(bar(_filter())));
      await tester.pumpAndSettle();
      final withTools = tester.getSize(period).width;

      await tester.pumpWidget(wrap(bar(_filter(), showTools: false)));
      await tester.pumpAndSettle();

      expect(search, findsNothing);
      expect(filterButton, findsNothing);
      expect(period, findsOneWidget);
      expect(tester.getSize(period).width, greaterThan(withTools));
    });

    testWidgets('ilk kayıtla birlikte yerlerine gelirler', (tester) async {
      await tester.pumpWidget(wrap(bar(_filter(), showTools: false)));
      await tester.pumpAndSettle();

      await tester.pumpWidget(wrap(bar(_filter())));
      await tester.pumpAndSettle();

      expect(search, findsOneWidget);
      expect(filterButton, findsOneWidget);
    });
  });

  group('yerleşim', () {
    // Çubuk iki kontrolü (dönem + filtre) tek satırda taşıyor;
    // en dar yaygın Android genişliğinde (320dp) taşmamalı.
    for (final width in [320.0, 360.0, 411.0]) {
      testWidgets('${width.toInt()}dp genişlikte taşma yok', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(wrap(
          bar(_filter(
            categories: {'a', 'b'},
            priceRange: const PriceRangeFilter(minPrice: 100),
          )),
          width: width,
        ));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('320dp: dönem çubuğu + filtre satıra sığar', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(bar(_filter()), width: 320));
      await tester.pump();

      // 320 - 32 (çubuğun kendi yatay padding'i) = 288 kullanılabilir.
      final periodWidth =
          tester.getSize(find.byType(TransactionPeriodBar)).width;
      expect(periodWidth, greaterThan(60),
          reason: 'dönem etiketi okunacak kadar yer bulmalı');
    });
  });

  group('çip şeridi görünürlüğü', () {
    test('çip yokken çip şeridi yer kaplamaz', () {
      expect(
          ActiveFilterChips.hasChipsFor(
              const DataFilter(), FinanceMode.compare),
          isFalse);
      expect(
          ActiveFilterChips.hasChipsFor(
              const DataFilter(selectedCategories: {'a'}), FinanceMode.compare),
          isTrue);
    });

    test('arama da çip şeridi açar', () {
      // Arama alanı artık sabit çubukta değil, içerikle kayıp gidiyor.
      // Kullanıcı listeyi aşağı kaydırdığında "neden yalnız üç satır
      // görüyorum" sorusunun yanıtı çubukta kalmalı.
      expect(
          ActiveFilterChips.hasChipsFor(
              const DataFilter(searchQuery: 'market'), FinanceMode.compare),
          isTrue);
    });

    test('tek türe daralmak (yalnız gider) çip şeridi açar', () {
      expect(
          ActiveFilterChips.hasChipsFor(
              const DataFilter(), FinanceMode.expense),
          isTrue);
    });
  });

  group('tür çipi', () {
    testWidgets(
        'mod seçicisi YOK; tek tür etkinken adıyla çip görünür, × tümüne döner',
        (tester) async {
      FinanceMode? changed;
      await tester.pumpWidget(wrap(TransactionTopBar(
        filter: _filter(mode: FinanceMode.expense),
        categoryLabels: const {},
        onModeChanged: (m) => changed = m,
        onPeriodStep: (_) {},
        onPeriodPick: () {},
        onFilterTap: () {},
        onClearCategories: () {},
        onClearPriceRange: () {},
        onClearSearch: () {},
        onClearAllFilters: () {},
        onSearchChanged: (_) {},
        onDataFilterChanged: (_) {},
      )));
      await tester.pump();

      // İkon-yalnız segment kalktı.
      expect(find.byIcon(Icons.compare_arrows_rounded), findsNothing);
      expect(find.text('Giderler'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(ActiveFilterChips),
        matching: find.byIcon(Icons.close_rounded),
      ));
      expect(changed, FinanceMode.compare);
    });
  });

  group('arama çipi', () {
    testWidgets('etkin sorgu çip olarak görünür ve × onu kaldırır',
        (tester) async {
      var cleared = 0;
      await tester.pumpWidget(wrap(bar(
        _filter(search: 'market'),
        onClearSearch: () => cleared++,
      )));
      await tester.pump();

      expect(find.textContaining('market'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(ActiveFilterChips),
        matching: find.byIcon(Icons.close_rounded),
      ));
      expect(cleared, 1);
    });
  });

  group('dönem', () {
    testWidgets('etiket ay adını yazar', (tester) async {
      await tester.pumpWidget(wrap(bar(_filter())));
      expect(find.text('Ağustos 2026'), findsOneWidget);
    });

    testWidgets('oklar adım yönünü iletir', (tester) async {
      final steps = <int>[];
      await tester.pumpWidget(wrap(bar(_filter(), onPeriodStep: steps.add)));

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      expect(steps, [-1, 1]);
    });
  });

  group('aktif filtre çipleri', () {
    testWidgets('tek kategori seçiliyken SAYI değil AD gösterilir',
        (tester) async {
      await tester.pumpWidget(wrap(bar(
        _filter(categories: {'cat-market'}),
        labels: const {'cat-market': 'Market'},
      )));

      expect(find.text('Market'), findsOneWidget);
      expect(find.text('1 kategori'), findsNothing);
    });

    testWidgets('birden çok kategoride sayı gösterilir', (tester) async {
      await tester.pumpWidget(wrap(bar(
        _filter(categories: {'a', 'b', 'c'}),
        labels: const {'a': 'Market'},
      )));

      expect(find.textContaining('3'), findsOneWidget);
    });

    testWidgets('× yalnız kendi filtresini kaldırır', (tester) async {
      var clearedCategories = 0;
      var clearedPrice = 0;

      await tester.pumpWidget(wrap(bar(
        _filter(
          categories: {'cat-market'},
          priceRange: const PriceRangeFilter(minPrice: 100),
        ),
        labels: const {'cat-market': 'Market'},
        onClearCategories: () => clearedCategories++,
        onClearPriceRange: () => clearedPrice++,
      )));
      await tester.pump();

      // İlk çip kategori, ikincisi tutar aralığı.
      final closeButtons = find.descendant(
        of: find.byType(ActiveFilterChips),
        matching: find.byIcon(Icons.close_rounded),
      );
      expect(closeButtons, findsNWidgets(2));

      await tester.tap(closeButtons.first);
      expect(clearedCategories, 1);
      expect(clearedPrice, 0);
    });
  });

  group('arama ikonu', () {
    testWidgets(
        'dönem ile filtre ARASINDA; dokununca alan dönemin yerinde açılır, × kapatır',
        (tester) async {
      final typed = <String>[];
      await tester.pumpWidget(wrap(bar(_filter(), onSearchChanged: typed.add)));
      await tester.pump();

      final search = find.byKey(const ValueKey('tx-search-open'));
      final period = tester.getRect(find.byType(TransactionPeriodBar));
      final filterBtn = tester.getRect(find.byIcon(Icons.tune_rounded));
      final searchRect = tester.getRect(search);
      expect(searchRect.left, greaterThan(period.right));
      expect(searchRect.right, lessThan(filterBtn.left));
      // İçerikte kalıcı bir arama alanı YOK.
      expect(find.byType(TransactionSearchField), findsNothing);

      await tester.tap(search);
      await tester.pumpAndSettle();
      expect(find.byType(TransactionSearchField), findsOneWidget);
      expect(find.byType(TransactionPeriodBar), findsNothing);

      await tester.enterText(find.byType(TextField), 'market');
      expect(typed.last, 'market');

      // Boşken × aramayı kapatır, dönem geri gelir.
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tx-search-close')));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionSearchField), findsNothing);
      expect(find.byType(TransactionPeriodBar), findsOneWidget);
    });

    testWidgets(
        'kapalıyken sorgu etkinse ikon işaretlidir, filtre noktası DEĞİL',
        (tester) async {
      await tester.pumpWidget(wrap(bar(_filter(search: 'market'))));
      await tester.pump();
      Color border(Finder f) => ((tester
                  .widget<Container>(find
                      .descendant(of: f, matching: find.byType(Container))
                      .first)
                  .decoration as BoxDecoration)
              .border as Border)
          .top
          .color;
      final searchBorder = border(find.byKey(const ValueKey('tx-search-open')));
      final filterBorder = border(find
          .ancestor(
              of: find.byIcon(Icons.tune_rounded),
              matching: find.byType(InkWell))
          .first);
      expect(searchBorder, isNot(filterBorder));
    });
  });

  group('ek filtre çipleri', () {
    testWidgets('para taşıma / fişli / ekstreden çipleri görünür ve × kaldırır',
        (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final changes = <DataFilter>[];
      await tester.pumpWidget(wrap(
          bar(
            _filter(
              moved: MovedMoneyFilter.hide,
              onlyWithReceipt: true,
              onlyImported: true,
            ),
            onDataFilterChanged: changes.add,
          ),
          width: 800));
      await tester.pump();

      // Çip satırı yatay kayar; üçü birden ancak geniş ekranda kurulur.
      expect(find.text('Para taşıma gizli'), findsOneWidget);
      expect(find.text('Fişli'), findsOneWidget);
      expect(find.text('Ekstreden'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find
            .ancestor(
                of: find.text('Para taşıma gizli'),
                matching: find.byType(Container))
            .first,
        matching: find.byIcon(Icons.close_rounded),
      ));
      expect(changes.single.movedMoney, MovedMoneyFilter.show);
      expect(changes.single.onlyWithReceipt, isTrue);
    });
  });
}
