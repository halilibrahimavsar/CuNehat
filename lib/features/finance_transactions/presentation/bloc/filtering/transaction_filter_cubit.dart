import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// İşlemler ekranının filtre durumu.
///
/// Mutasyonlar NİYET adlarıyla sunulur (`stepPeriod`, `toggleCategory`, …).
/// Eskiden her çağıran `copyWith(viewFilter: ..., dataFilter: ...)` zincirini
/// elle kuruyordu; "mod değişince kategorileri temizle" gibi kurallar da
/// widget'ın içinde tek tek yazılıydı ve test edilemiyordu.
@injectable
class TransactionFilterCubit extends Cubit<CombinedFilter> {
  TransactionFilterCubit() : super(createDefaultFilter());

  /// Varsayılan görünüm: içinde bulunulan ay, karşılaştırma modu, filtresiz.
  static CombinedFilter createDefaultFilter({DateTime? now}) {
    final month = monthRangeOf(now ?? DateTime.now());
    return CombinedFilter(
      viewFilter: ViewFilter(
        financeMode: FinanceMode.compare,
        startDate: month.start,
        endDate: month.end,
      ),
      dataFilter: const DataFilter(),
    );
  }

  DateTimeRange get period => DateTimeRange(
        start: state.viewFilter.startDate,
        end: state.viewFilter.endDate,
      );

  /// Dönem varsayılandan (bu ay) sapmış mı? "Filtreleri temizle" düğmesinin
  /// görünürlüğü buna da bakar; yoksa yalnız tarihi değiştiren kullanıcının
  /// geri dönüş yolu kalmıyordu.
  bool get isDefaultPeriod {
    final month = monthRangeOf(DateTime.now());
    return isSameDayValue(state.viewFilter.startDate, month.start) &&
        isSameDayValue(state.viewFilter.endDate, month.end);
  }

  /// Herhangi bir filtre ya da varsayılan dışı dönem etkin mi?
  bool get hasAnyActiveFilter =>
      state.dataFilter.hasActiveFilters || !isDefaultPeriod;

  void updateFilter(CombinedFilter newFilter) => emit(newFilter);

  /// Gelir / Karşılaştırma / Gider.
  ///
  /// Kategori seçimi TÜRE bağlıdır (gider kategorisi gelir modunda hiçbir
  /// satırla eşleşmez ve liste sessizce boşalır), bu yüzden mod değişince
  /// temizlenir. Fiyat aralığı ve arama tür-bağımsızdır, korunur.
  void setFinanceMode(FinanceMode mode) {
    if (state.viewFilter.financeMode == mode) return;
    emit(state.copyWith(
      viewFilter: state.viewFilter.copyWith(financeMode: mode),
      dataFilter: state.dataFilter.copyWith(clearCategories: true),
    ));
  }

  void setPeriod(DateTimeRange range) {
    if (isSameDayValue(state.viewFilter.startDate, range.start) &&
        isSameDayValue(state.viewFilter.endDate, range.end)) {
      return;
    }
    emit(state.copyWith(
      viewFilter: state.viewFilter.copyWith(
        startDate: range.start,
        endDate: range.end,
      ),
    ));
  }

  /// Dönemi kendi doğasına göre bir adım ileri/geri kaydırır (bkz.
  /// [shiftPeriod]).
  void stepPeriod(int step) => setPeriod(shiftPeriod(period, step));

  /// Boş/boşluk sorgu `null`'a iner: "arama etkin mi" sorusunun tek yanıtı
  /// olsun, `''` ile `null` iki ayrı "kapalı" durum üretmesin.
  void setSearchQuery(String? query) {
    final trimmed = query?.trim();
    final next = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (state.dataFilter.searchQuery == next) return;
    emit(state.copyWith(
      dataFilter: next == null
          ? state.dataFilter.copyWith(clearSearchQuery: true)
          : state.dataFilter.copyWith(searchQuery: next),
    ));
  }

  void setCategories(Set<String> categories) {
    emit(state.copyWith(
      dataFilter: categories.isEmpty
          ? state.dataFilter.copyWith(clearCategories: true)
          : state.dataFilter.copyWith(selectedCategories: categories),
    ));
  }

  void setPriceRange(PriceRangeFilter? range) {
    final next = (range == null || range.isEmpty) ? null : range;
    if (state.dataFilter.priceRange == next) return;
    emit(state.copyWith(
      dataFilter: next == null
          ? state.dataFilter.copyWith(clearPriceRange: true)
          : state.dataFilter.copyWith(priceRange: next),
    ));
  }

  /// Yalnız veri filtreleri (kategori + fiyat + arama). Dönem ve mod kalır.
  void clearDataFilters() {
    if (!state.dataFilter.hasActiveFilters) return;
    emit(state.copyWith(
      dataFilter: state.dataFilter.copyWith(
        clearCategories: true,
        clearPriceRange: true,
        clearSearchQuery: true,
      ),
    ));
  }

  /// Veri filtreleri + dönem varsayılana döner. Mod korunur: kullanıcının
  /// "şu an giderlere bakıyorum" bağlamı bir temizleme eylemiyle kaybolmamalı.
  void clearAll() {
    final defaults = createDefaultFilter();
    emit(CombinedFilter(
      viewFilter: defaults.viewFilter
          .copyWith(financeMode: state.viewFilter.financeMode),
      dataFilter: defaults.dataFilter,
    ));
  }
}
