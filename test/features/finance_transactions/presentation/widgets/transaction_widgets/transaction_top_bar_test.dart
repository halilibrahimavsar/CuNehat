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
    Map<String, String> labels = const {},
  }) {
    return TransactionTopBar(
      filter: filter,
      categoryLabels: labels,
      onModeChanged: (_) {},
      onPeriodStep: onPeriodStep ?? (_) {},
      onPeriodPick: () {},
      onFilterTap: () {},
      onClearCategories: onClearCategories ?? () {},
      onClearPriceRange: onClearPriceRange ?? () {},
      onClearSearch: onClearSearch ?? () {},
      onClearAllFilters: () {},
    );
  }

  group('yerleşim', () {
    // Çubuk üç kontrolü (dönem + mod segmenti + filtre) tek satırda taşıyor;
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

    testWidgets('320dp: dönem çubuğu + segment + filtre satıra sığar',
        (tester) async {
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

  group('yükseklik', () {
    test('çip yokken çip şeridi yer kaplamaz', () {
      const empty = DataFilter();
      const withChips = DataFilter(selectedCategories: {'a'});
      expect(
        TransactionTopBar.heightFor(withChips) -
            TransactionTopBar.heightFor(empty),
        ActiveFilterChips.height + 8,
      );
    });

    test('arama da çip şeridi açar', () {
      // Arama alanı artık sabit çubukta değil, içerikle kayıp gidiyor.
      // Kullanıcı listeyi aşağı kaydırdığında "neden yalnız üç satır
      // görüyorum" sorusunun yanıtı çubukta kalmalı.
      const searchOnly = DataFilter(searchQuery: 'market');
      expect(
        TransactionTopBar.heightFor(searchOnly) -
            TransactionTopBar.heightFor(const DataFilter()),
        ActiveFilterChips.height + 8,
      );
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
}
