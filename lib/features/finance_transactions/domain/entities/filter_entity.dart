import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
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

  /// Rozet/çip etiketi; cüzdan kapsamlı görünümler aktif birim kodunu geçer.
  ///
  /// Çip dar olduğu için kuruş YAZILMAZ (`decimals: 0`) — burası tam tutar
  /// değil aralık göstergesi. Biçim yine de [formatMoney]'den gelir, yani
  /// binlik ayracı ve sembol yerleşimi uygulamanın geri kalanıyla aynıdır.
  ///
  /// Tek yönlü sınırlar `≥`/`≤` ile yazılır: eskiden "500 ₺'ye kadar" diye
  /// sabit bir Türkçe ek vardı ve İngilizce arayüzde de öyle görünüyordu.
  /// Simge hem dilden bağımsız hem de dar çipte kısa.
  String label({String currency = kDefaultCurrency}) {
    String money(double v) => formatMoney(v, decimals: 0, currency: currency);

    if (minPrice != null && maxPrice != null) {
      if (minPrice == maxPrice) {
        return money(minPrice!);
      }
      return '${money(minPrice!)} - ${money(maxPrice!)}';
    } else if (minPrice != null) {
      return '≥ ${money(minPrice!)}';
    } else if (maxPrice != null) {
      return '≤ ${money(maxPrice!)}';
    }
    return '';
  }

  @override
  String toString() => label();

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
/// Para taşıma hareketlerinin (transfer, borç, yatırım, kart ödemesi —
/// `isSystem`) listede nasıl ele alınacağı.
///
/// Defter bunları HER ZAMAN gösteriyordu ve gizlemenin/yalnız onlara bakmanın
/// bir yolu yoktu: kartla harcayan kullanıcının defteri kart ödemeleriyle,
/// yatırım yapanınki alım/satımlarla doluyordu.
enum MovedMoneyFilter {
  /// Varsayılan: defter olduğu gibi (bakiye zinciri bunlara dayanır).
  show,

  /// Yalnız gelir–gider satırları.
  hide,

  /// Yalnız para taşıma hareketleri.
  only,
}

base class DataFilter extends BaseFilter {
  final Set<String> selectedCategories;
  final PriceRangeFilter? priceRange;
  final String? searchQuery;
  final MovedMoneyFilter movedMoney;

  /// Yalnız fiş/fotoğraf eklenmiş işlemler.
  final bool onlyWithReceipt;

  /// Yalnız banka ekstresinden gelenler. Ölçüt kesin kanıtlardan biri:
  /// banka referansı, içe aktarım kimliği ya da `origin == import`
  /// (bkz. [isFromBankStatement]). `origin` alanı eski kayıtlarda boş olduğu
  /// için "elle girilenler" filtresi BİLEREK yok — o ayrım eski kayıtlarda
  /// tahmin olurdu.
  final bool onlyImported;

  const DataFilter({
    this.selectedCategories = const {},
    this.priceRange,
    this.searchQuery,
    this.movedMoney = MovedMoneyFilter.show,
    this.onlyWithReceipt = false,
    this.onlyImported = false,
  });

  DataFilter copyWith({
    Set<String>? selectedCategories,
    PriceRangeFilter? priceRange,
    String? searchQuery,
    MovedMoneyFilter? movedMoney,
    bool? onlyWithReceipt,
    bool? onlyImported,
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
      movedMoney: movedMoney ?? this.movedMoney,
      onlyWithReceipt: onlyWithReceipt ?? this.onlyWithReceipt,
      onlyImported: onlyImported ?? this.onlyImported,
    );
  }

  /// Aramadan ve kategori/tutar süzgecinden bağımsız "ek" filtreler etkin mi?
  bool get hasExtraFilters =>
      movedMoney != MovedMoneyFilter.show || onlyWithReceipt || onlyImported;

  @override
  bool get hasActiveFilters =>
      selectedCategories.isNotEmpty ||
      (priceRange != null && priceRange!.isNotEmpty) ||
      (searchQuery?.trim().isNotEmpty ?? false) ||
      hasExtraFilters;

  @override
  int get activeFilterCount {
    int count = 0;
    if (selectedCategories.isNotEmpty) count++;
    if (priceRange != null && priceRange!.isNotEmpty) count++;
    if (searchQuery?.trim().isNotEmpty ?? false) count++;
    if (movedMoney != MovedMoneyFilter.show) count++;
    if (onlyWithReceipt) count++;
    if (onlyImported) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        selectedCategories,
        priceRange,
        searchQuery,
        movedMoney,
        onlyWithReceipt,
        onlyImported,
      ];
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
