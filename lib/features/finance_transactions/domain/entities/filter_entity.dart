import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:equatable/equatable.dart';

/// Veri filtreleri için temel sınıf
abstract base class BaseFilter extends Equatable {
  const BaseFilter();

  bool get hasActiveFilters;
  int get activeFilterCount;

  @override
  List<Object?> get props => [];
}

/// Fiyat aralığı filtresi
class PriceRangeFilter extends Equatable {
  final double? minPrice;
  final double? maxPrice;

  const PriceRangeFilter({
    this.minPrice,
    this.maxPrice,
  });

  bool get isEmpty => minPrice == null && maxPrice == null;
  bool get isNotEmpty => !isEmpty;

  bool isInRange(double price) {
    if (minPrice != null && price < minPrice!) return false;
    if (maxPrice != null && price > maxPrice!) return false;
    return true;
  }

  @override
  List<Object?> get props => [minPrice, maxPrice];

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

  PriceRangeFilter copyWith({
    double? minPrice,
    double? maxPrice,
  }) {
    return PriceRangeFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

/// Veri filtreleri (transaction listesini filtrelemek için)
base class DataFilter extends BaseFilter {
  final Set<String> selectedCategories;
  final PriceRangeFilter? priceRange;
  final String? searchQuery;

  const DataFilter({
    this.selectedCategories = const {},
    this.priceRange,
    this.searchQuery,
  });

  DataFilter copyWith({
    Set<String>? selectedCategories,
    PriceRangeFilter? priceRange,
    String? searchQuery,
    bool clearCategories = false,
    bool clearPriceRange = false,
    bool clearSearchQuery = false,
  }) {
    return DataFilter(
      selectedCategories: clearCategories
          ? const {}
          : (selectedCategories ?? this.selectedCategories),
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  bool get hasActiveFilters =>
      selectedCategories.isNotEmpty ||
      priceRange != null ||
      (searchQuery?.trim().isNotEmpty ?? false);

  @override
  int get activeFilterCount {
    int count = 0;
    if (selectedCategories.isNotEmpty) count++;
    if (priceRange != null) count++;
    if (searchQuery?.trim().isNotEmpty ?? false) count++;
    return count;
  }

  @override
  List<Object?> get props => [selectedCategories, priceRange, searchQuery];
}

/// Görünüm filtreleri (UI durumunu yönetmek için)
class ViewFilter extends Equatable {
  final FinanceMode financeMode;
  final DateTime startDate;
  final DateTime endDate;

  const ViewFilter({
    required this.financeMode,
    required this.startDate,
    required this.endDate,
  });

  ViewFilter copyWith({
    FinanceMode? financeMode,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ViewFilter(
      financeMode: financeMode ?? this.financeMode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [financeMode, startDate, endDate];
}

/// Tam filtre bileşimi
class CombinedFilter extends Equatable {
  final ViewFilter viewFilter;
  final DataFilter dataFilter;

  const CombinedFilter({
    required this.viewFilter,
    required this.dataFilter,
  });

  CombinedFilter copyWith({
    ViewFilter? viewFilter,
    DataFilter? dataFilter,
  }) {
    return CombinedFilter(
      viewFilter: viewFilter ?? this.viewFilter,
      dataFilter: dataFilter ?? this.dataFilter,
    );
  }

  @override
  List<Object?> get props => [viewFilter, dataFilter];
}
