import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
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

  /// Kredi kartı bağlamında EKSTRE döngüsü; hesapta `null`. Kart kullanıcısı
  /// takvim ayıyla değil ekstreyle düşünür: kart bağlamında varsayılan dönem
  /// içinde bulunulan ekstre, oklar bir ekstre atlar (ay uzunlukları farklı —
  /// "özel aralık" olarak kendi uzunluğu kadar kaymak yanlış olurdu).
  CardCycle? _cycle;

  /// Etkin ekstre döngüsü (kart bağlamı).
  CardCycle? get statementCycle => _cycle;

  static DateTimeRange _toRange(({DateTime start, DateTime end}) p) =>
      DateTimeRange(
        start: p.start,
        end: DateTime(p.end.year, p.end.month, p.end.day, 23, 59, 59),
      );

  /// İçinde bulunulan ekstre dönemi; döngü yoksa `null`.
  DateTimeRange? currentStatementPeriod({DateTime? now}) {
    final cycle = _cycle;
    if (cycle == null) return null;
    return _toRange(cycle.periodContaining(now ?? DateTime.now()));
  }

  /// Seçili dönem [cycle]'ın bir ekstre dönemi mi?
  static bool _isStatementOf(CardCycle? cycle, DateTimeRange range) {
    if (cycle == null) return false;
    final p = cycle.periodContaining(range.start);
    return isSameDayValue(p.start, range.start) &&
        isSameDayValue(p.end, range.end);
  }

  /// Seçili dönem etkin kartın bir ekstre dönemi mi?
  bool get isStatementPeriod => _isStatementOf(_cycle, period);

  /// Süzgecin bağlı olduğu cüzdan (bkz. [bindWallet]).
  String? _walletId;

  /// Süzgeç artık uygulama düzeyinde TEK örnek: İşlemler, İçgörü ve Rapor
  /// aynı dönemi paylaşır (eskiden her sayfa kendi dönemini tutuyordu).
  /// Sayfa-yerel örnek cüzdan değişince sayfayla birlikte yeniden kuruluyor,
  /// arama ve kategori seçimi de kendiliğinden sıfırlanıyordu; tek örnekte bu
  /// açıkça yapılmalı. Kategoriler cüzdana göre görünür olduğundan eski
  /// cüzdanın kategori seçimi yeni cüzdanda sessizce boş liste üretirdi.
  /// Dönem ve mod KORUNUR: kullanıcı Eylül'e bakarken cüzdan değiştirince
  /// yine Eylül'e bakmak ister.
  void bindWallet(String? walletId) {
    if (_walletId == walletId) return;
    final hadWallet = _walletId != null;
    _walletId = walletId;
    if (hadWallet) clearDataFilters();
  }

  /// Bağlam değişti (hesap ↔ kart). Varsayılan dönemdeyken (bu ay ya da
  /// önceki kartın bir ekstresi) yeni bağlamın varsayılanına geçilir;
  /// kullanıcının seçtiği özel bir aralığa DOKUNULMAZ.
  void useStatementCycle(CreditCardInfo? card) {
    final next = card == null ? null : CardCycle(card);
    final wasDefault = isDefaultPeriod || _isStatementOf(_cycle, period);
    _cycle = next;
    if (!wasDefault) return;
    setPeriod(currentStatementPeriod() ?? monthRangeOf(DateTime.now()));
  }

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
    final base = currentStatementPeriod() ?? monthRangeOf(DateTime.now());
    return isSameDayValue(state.viewFilter.startDate, base.start) &&
        isSameDayValue(state.viewFilter.endDate, base.end);
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
  ///
  /// Kart bağlamında ekstre dönemindeyken bir EKSTRE atlar.
  void stepPeriod(int step) {
    final cycle = _cycle;
    if (cycle != null && isStatementPeriod) {
      final closing = cycle.shiftClosing(dayOf(period.end), step);
      setPeriod(_toRange(cycle.periodEndingAt(closing)));
      return;
    }
    setPeriod(shiftPeriod(period, step));
  }

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
    final statement = currentStatementPeriod();
    emit(CombinedFilter(
      viewFilter: defaults.viewFilter.copyWith(
        financeMode: state.viewFilter.financeMode,
        startDate: statement?.start,
        endDate: statement?.end,
      ),
      dataFilter: defaults.dataFilter,
    ));
  }
}
