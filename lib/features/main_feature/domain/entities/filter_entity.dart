import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';

class TransactionFilter {
  final FinanceMode financeMode;
  final TransactionViewType viewType;
  final DateTime startDate;
  final DateTime endDate;
  final Set<String> selectedCategories;
  final PriceRangeFilter? priceRange;

  const TransactionFilter({
    required this.financeMode,
    required this.viewType,
    required this.startDate,
    required this.endDate,
    this.selectedCategories = const {},
    this.priceRange,
  });

  TransactionFilter copyWith({
    FinanceMode? financeMode,
    TransactionViewType? viewType,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? selectedCategories,
    PriceRangeFilter? priceRange,
  }) {
    return TransactionFilter(
      financeMode: financeMode ?? this.financeMode,
      viewType: viewType ?? this.viewType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      priceRange: priceRange ?? this.priceRange,
    );
  }

  bool get hasActiveFilters =>
      selectedCategories.isNotEmpty || priceRange != null;

  int get activeFilterCount {
    int count = 0;
    if (selectedCategories.isNotEmpty) count++;
    if (priceRange != null) count++;
    return count;
  }
}

class PriceRangeFilter {
  final double? minPrice;
  final double? maxPrice;

  const PriceRangeFilter({
    this.minPrice,
    this.maxPrice,
  });

  bool isInRange(double price) {
    if (minPrice != null && price < minPrice!) return false;
    if (maxPrice != null && price > maxPrice!) return false;
    return true;
  }

  @override
  String toString() {
    if (minPrice != null && maxPrice != null) {
      return '${minPrice!.toStringAsFixed(0)}₺ - ${maxPrice!.toStringAsFixed(0)}₺';
    } else if (minPrice != null) {
      return '${minPrice!.toStringAsFixed(0)}₺+';
    } else if (maxPrice != null) {
      return '${maxPrice!.toStringAsFixed(0)}₺\'ye kadar';
    }
    return '';
  }
}
