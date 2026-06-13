import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionFilterCubit', () {
    late TransactionFilterCubit cubit;

    setUp(() {
      cubit = TransactionFilterCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has correct default values for current month range', () {
      final now = DateTime.now();
      final expectedStart = DateTime(now.year, now.month, 1);
      final expectedEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final state = cubit.state;

      expect(state.viewFilter.financeMode, FinanceMode.compare);
      expect(state.viewFilter.startDate, expectedStart);
      expect(state.viewFilter.endDate, expectedEnd);
      expect(state.dataFilter.selectedCategories, isEmpty);
      expect(state.dataFilter.priceRange, isNull);
      expect(state.dataFilter.searchQuery, isNull);
    });

    blocTest<TransactionFilterCubit, CombinedFilter>(
      'emits new filter state when updateFilter is called',
      build: () => cubit,
      act: (cubit) {
        final newFilter = CombinedFilter(
          viewFilter: ViewFilter(
            financeMode: FinanceMode.expense,
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 31),
          ),
          dataFilter: const DataFilter(
            selectedCategories: {'Food', 'Bills'},
            priceRange: PriceRangeFilter(minPrice: 100, maxPrice: 500),
            searchQuery: 'Grocery',
          ),
        );
        cubit.updateFilter(newFilter);
      },
      expect: () => [
        CombinedFilter(
          viewFilter: ViewFilter(
            financeMode: FinanceMode.expense,
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 31),
          ),
          dataFilter: const DataFilter(
            selectedCategories: {'Food', 'Bills'},
            priceRange: PriceRangeFilter(minPrice: 100, maxPrice: 500),
            searchQuery: 'Grocery',
          ),
        ),
      ],
    );
  });
}
