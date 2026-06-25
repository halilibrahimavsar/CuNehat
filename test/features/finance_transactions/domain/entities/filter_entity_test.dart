import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter_test/flutter_test.dart';

base class MockBaseFilter extends BaseFilter {
  const MockBaseFilter();
  @override
  bool get hasActiveFilters => false;
  @override
  int get activeFilterCount => 0;
}

void main() {
  group('BaseFilter', () {
    test('props returns empty list', () {
      expect(const MockBaseFilter().props, isEmpty);
    });
  });

  group('PriceRangeFilter', () {
    test('supports value comparisons (Equatable)', () {
      expect(
        const PriceRangeFilter(minPrice: 100, maxPrice: 500),
        const PriceRangeFilter(minPrice: 100, maxPrice: 500),
      );
    });

    test('isEmpty returns true when both min and max are null', () {
      expect(const PriceRangeFilter().isEmpty, true);
      expect(const PriceRangeFilter().isNotEmpty, false);
    });

    test('isEmpty returns false when either min or max is not null', () {
      expect(const PriceRangeFilter(minPrice: 100).isEmpty, false);
      expect(const PriceRangeFilter(minPrice: 100).isNotEmpty, true);
      expect(const PriceRangeFilter(maxPrice: 500).isEmpty, false);
      expect(const PriceRangeFilter(maxPrice: 500).isNotEmpty, true);
    });

    test('props returns correct properties', () {
      expect(const PriceRangeFilter(minPrice: 100.0, maxPrice: 500.0).props,
          [100.0, 500.0]);
    });

    test('isInRange filters correctly', () {
      const filter = PriceRangeFilter(minPrice: 100.0, maxPrice: 500.0);
      expect(filter.isInRange(50.0), false);
      expect(filter.isInRange(100.0), true);
      expect(filter.isInRange(300.0), true);
      expect(filter.isInRange(500.0), true);
      expect(filter.isInRange(550.0), false);
    });

    test('toString formats correctly', () {
      expect(
          const PriceRangeFilter(minPrice: 100.0, maxPrice: 500.0).toString(),
          '100₺ - 500₺');
      expect(const PriceRangeFilter(minPrice: 100.0).toString(), '100₺+');
      expect(
          const PriceRangeFilter(maxPrice: 500.0).toString(), '500₺\'ye kadar');
      expect(const PriceRangeFilter().toString(), '');
    });

    test('copyWith returns updated object', () {
      const filter = PriceRangeFilter(minPrice: 100.0, maxPrice: 500.0);
      final updated = filter.copyWith(minPrice: 200.0, maxPrice: 600.0);
      expect(updated.minPrice, 200.0);
      expect(updated.maxPrice, 600.0);

      final copied = filter.copyWith();
      expect(copied.minPrice, 100.0);
      expect(copied.maxPrice, 500.0);
    });
  });

  group('DataFilter', () {
    test('hasActiveFilters and activeFilterCount return correct values', () {
      const emptyFilter = DataFilter();
      expect(emptyFilter.hasActiveFilters, false);
      expect(emptyFilter.activeFilterCount, 0);

      final withCategories = const DataFilter(selectedCategories: {'Food'});
      expect(withCategories.hasActiveFilters, true);
      expect(withCategories.activeFilterCount, 1);

      final withAll = const DataFilter(
        selectedCategories: {'Food'},
        priceRange: PriceRangeFilter(minPrice: 100),
        searchQuery: 'Lunch',
      );
      expect(withAll.hasActiveFilters, true);
      expect(withAll.activeFilterCount, 3);
    });

    test('copyWith updates and clears properties correctly', () {
      const filter = DataFilter(
        selectedCategories: {'Food'},
        priceRange: PriceRangeFilter(minPrice: 100),
        searchQuery: 'Lunch',
      );

      final updated = filter.copyWith(searchQuery: 'Dinner');
      expect(updated.searchQuery, 'Dinner');
      expect(updated.selectedCategories, const {'Food'});

      final cleared = filter.copyWith(
        clearCategories: true,
        clearPriceRange: true,
        clearSearchQuery: true,
      );
      expect(cleared.selectedCategories.isEmpty, true);
      expect(cleared.priceRange, null);
      expect(cleared.searchQuery, null);

      final copied = filter.copyWith();
      expect(copied.selectedCategories, const {'Food'});
      expect(copied.priceRange, const PriceRangeFilter(minPrice: 100));
      expect(copied.searchQuery, 'Lunch');
    });
  });

  group('ViewFilter', () {
    final start = DateTime(2026, 6, 1);
    final end = DateTime(2026, 6, 30);
    final filter = ViewFilter(
      financeMode: FinanceMode.expense,
      startDate: start,
      endDate: end,
    );

    test('copyWith returns updated object', () {
      final updated = filter.copyWith(
        financeMode: FinanceMode.income,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      expect(updated.financeMode, FinanceMode.income);
      expect(updated.startDate, DateTime(2026, 7, 1));
      expect(updated.endDate, DateTime(2026, 7, 31));

      final copied = filter.copyWith();
      expect(copied.financeMode, FinanceMode.expense);
      expect(copied.startDate, start);
      expect(copied.endDate, end);
    });
  });

  group('CombinedFilter', () {
    final view = ViewFilter(
      financeMode: FinanceMode.expense,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
    );
    const data = DataFilter(selectedCategories: {'Food'});
    final combined = CombinedFilter(viewFilter: view, dataFilter: data);

    test('copyWith returns updated object', () {
      final newView = view.copyWith(financeMode: FinanceMode.income);
      const newData = DataFilter(selectedCategories: {'Drinks'});
      final updated =
          combined.copyWith(viewFilter: newView, dataFilter: newData);

      expect(updated.viewFilter, newView);
      expect(updated.dataFilter, newData);

      final copied = combined.copyWith();
      expect(copied.viewFilter, view);
      expect(copied.dataFilter, data);
    });
  });
}
