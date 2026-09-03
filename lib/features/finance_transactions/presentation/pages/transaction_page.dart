import 'dart:async';
import 'dart:math' as math;

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/messaging/deletion_undo_message.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/shared/widgets/app_date_range_picker.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/daily_spending_summary_service.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/presentation/transaction_filtering.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/detailed_list_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_day_rail.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_list_skeleton.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_search_field.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_summary_strip.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_top_bar.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// İşlemler ekranı — uygulamanın açılış yüzü.
///
/// **Tek akış (3 Eyl 2026).** Ekran eskiden Liste ve Takvim diye iki
/// görünümdü ve varsayılanı takvimdi. Ölçüm (360×800, kabuk düşülmüş 630dp)
/// şunu gösterdi: takvim kartı 374dp kaplıyor, bir güne dokununca o günün
/// yalnız 1 işlemi görünüyor, ızgaradaki tek finansal veri 8,5px çiziliyordu.
/// Liste tarafında da ilk satıra kadar 309/630 dp (%49) chrome'a gidiyordu.
/// Yani ekran "hangi gün?" sorusunu cevaplıyordu; kullanıcı ise buraya "ne
/// aldım, param nereye gidiyor" diye bakıyor — üstelik analitiğin ağır işi
/// zaten bir kaydırma ötede (İçgörü + Rapor alt görünümleri).
///
/// Yeni sıra: sabit kontrol çubuğu → arama → dönem özeti → gün şeridi →
/// yapışkan gün başlıklı defter. Takvim ızgarası dönem SEÇİCİ olarak duruyor
/// ([AppDateRangePicker], üst çubuktaki tarihe dokununca).
class TransactionsPage extends StatelessWidget {
  final String userId;
  final WalletEntity wallet;

  const TransactionsPage({
    super.key,
    required this.userId,
    required this.wallet,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionFilterCubit(),
      child: _TransactionsView(
        userId: userId,
        wallet: wallet,
      ),
    );
  }
}

class _TransactionsView extends StatefulWidget {
  final String userId;
  final WalletEntity wallet;

  const _TransactionsView({
    required this.userId,
    required this.wallet,
  });

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  /// Kategori kimliği (tag) → ikon. İşlem kartlarında gerçek kategori glyph'i
  /// için.
  Map<String, IconData> _categoryIcons = {};

  /// `tag` → görünen ad; kart/liste gösterimi ve ARAMA bunu kullanır
  /// (kullanıcı "market" yazınca başlığı "ŞOK 4712" olan satır da gelmeli).
  /// Gruplama ve filtre anahtarı hep `tag` kalır.
  Map<String, String> _categoryLabels = {};

  StreamSubscription<void>? _categoriesSub;

  final ScrollController _scrollController = ScrollController();

  /// Gün şeridinden listeye giden köprü: başlıkların GlobalKey defteri.
  final LedgerDayAnchors _anchors = LedgerDayAnchors();

  /// Şeritte vurgulanan gün. Yalnız gezinme durumu — filtreye yazılmaz,
  /// çünkü bir güne bakmak dönemi daraltmak DEĞİLDİR (eski takvimde bir
  /// sayfa kaydırmak kullanıcının seçtiği yıllık dönemi tek aya düşürüyordu).
  DateTime? _selectedDay;

  /// Defter önbelleği: sıralama + running balance zinciri PAHALI ve yalnız
  /// işlem listesi değişince gerekir. Filtre/arama her tuş vuruşunda
  /// değiştiği için bunu her build'de kurmak listeyi tuş başına yeniden
  /// sıralamak demekti.
  List<TransactionEntity>? _ledgerSource;
  double? _ledgerBalance;
  List<TransactionWithBalance> _ledger = const [];

  /// Gün şeridinin ısı verisi; görünen küme değişmedikçe yeniden kurulmaz.
  static const _summaryService = DailySpendingSummaryService();
  List<TransactionWithBalance>? _summarySource;
  Map<DateTime, DaySummary> _summaries = const {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCategoryIcons();
    _categoriesSub = getIt<CategoriesChangedNotifier>()
        .stream
        .listen((_) => _loadCategoryIcons());
  }

  /// Kategori ikon+ad indeksini yükler ve kategoriler değiştikçe TAZELER.
  ///
  /// Harita eskiden yalnız initState'te kuruluyordu: sayfa route yığınında
  /// dururken yapılan bir yeniden adlandırma ancak sayfa yeniden kurulduğunda
  /// görünüyordu.
  Future<void> _loadCategoryIcons() async {
    final categories = await fetchAllCategories(getIt<CategoryRepository>());
    if (!mounted) return;
    final index = buildCategoryDisplayIndex(categories);
    setState(() {
      _categoryIcons = index.icons;
      _categoryLabels = index.labels;
    });
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TransactionsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallet.id != widget.wallet.id) {
      _loadData();
    }
  }

  /// Her zaman cüzdanın TAM geçmişini çeker; dönem dahil tüm filtreler
  /// bellekte uygulanır. Böylece running balance çapası (güncel bakiye)
  /// hiçbir aralıkta yanlış düşmez.
  void _loadData() {
    context.read<TransactionBloc>().add(GetTransactionsEvent(
          userId: widget.userId,
          walletId: widget.wallet.id ?? '',
        ));
  }

  /// Cüzdana ait defteri (bakiye zinciriyle) döndürür; kaynak liste ve bakiye
  /// değişmediyse önbellekten.
  List<TransactionWithBalance> _ledgerFor(List<TransactionEntity> all) {
    // Cüzdan geçişi sırasında bloc state'i kısa süre ESKİ cüzdanın listesini
    // taşıyabilir (TransactionLoading.previousTransactions); yabancı cüzdan
    // satırları yeni bakiyeye çapalanmasın.
    final walletTransactions =
        all.where((t) => t.walletId == widget.wallet.id).toList();
    final balance = widget.wallet.balance;

    if (_ledgerBalance == balance &&
        _ledgerSource != null &&
        _sameList(_ledgerSource!, walletTransactions)) {
      return _ledger;
    }

    _ledgerSource = walletTransactions;
    _ledgerBalance = balance;
    _ledger = buildLedger(
      transactions: walletTransactions,
      currentBalance: balance,
    );
    return _ledger;
  }

  static bool _sameList(List<TransactionEntity> a, List<TransactionEntity> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Gün özetleri; görünen küme değişmedikçe yeniden hesaplanmaz. Filtre her
  /// tuş vuruşunda değişip build tetiklediği için bu önemli.
  Map<DateTime, DaySummary> _summariesFor(
      List<TransactionWithBalance> visible) {
    final cached = _summarySource;
    if (cached != null &&
        cached.length == visible.length &&
        (cached.isEmpty ||
            (identical(cached.first, visible.first) &&
                identical(cached.last, visible.last)))) {
      return _summaries;
    }
    _summarySource = visible;
    _summaries = _summaryService
        .buildDailySummaries(visible.map((e) => e.transaction).toList());
    return _summaries;
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final cubit = context.read<TransactionFilterCubit>();

    final dateRange = await AppDateRangePicker.pick(
      context,
      initialDateRange: cubit.period,
      quickOptions: DateRangeHelper.buildDateRangeQuickOptions(context.l10n),
    );

    if (dateRange != null) cubit.setPeriod(dateRange);
  }

  void _showFilterSheet(BuildContext parentContext) {
    final cubit = parentContext.read<TransactionFilterCubit>();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<TransactionFilterCubit, CombinedFilter>(
            builder: (builderContext, state) {
              // Material (renkli Container değil): panel InkWell, Checkbox ve
              // TextButton kullanıyor; opak bir DecoratedBox araya girerse
              // mürekkep dalgası ARKASINA boyanır ve görünmez olur.
              // Klavye açıldığında sheet DARALIR, altına itilmez: panelde iki
              // metin alanı var (tutar + kategori araması) ve sabit yükseklik
              // "N işlemi göster" düğmesini klavyenin ardında bırakıyordu.
              final screenHeight = MediaQuery.sizeOf(builderContext).height;
              final keyboard = MediaQuery.viewInsetsOf(builderContext).bottom;
              final height =
                  math.min(screenHeight * 0.85, screenHeight - keyboard - 24);

              return Padding(
                padding: EdgeInsets.only(bottom: keyboard),
                child: Material(
                  color: Theme.of(builderContext).colorScheme.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SizedBox(
                    height: height,
                    child: FilterView(
                      filter: state,
                      // Panel canlı; düğme kaç işlemin kalacağını ÖNCEDEN
                      // söyler.
                      resultCount: filterLedger(
                        ledger: _ledger,
                        filter: state,
                        categoryLabels: _categoryLabels,
                      ).length,
                      onFilterChanged: cubit.updateFilter,
                      onDateTap: () => _pickDateRange(builderContext),
                      onPeriodStep: cubit.stepPeriod,
                      onClearAll: cubit.clearAll,
                      onClose: () => Navigator.pop(builderContext),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Şeritten seçilen günün başlığını listenin tepesine getirir.
  ///
  /// Başlık tembel listede henüz KURULMAMIŞ olabilir; `ensureVisible` o zaman
  /// çalışmaz. O yüzden önce doğru yönde ekran ekran yaklaşılır (her adım bir
  /// kare sürer ve yeni satırlar kurulur), hedef kurulunca kesin hizalama
  /// yapılır. Adım sayısı sınırlı: hedef bir sebeple hiç kurulmazsa döngü
  /// kilitlenmesin.
  Future<void> _scrollToDay(
    DateTime day,
    List<TransactionWithBalance> visible,
    FinanceMode mode,
  ) async {
    setState(() => _selectedDay = day);

    final groups = groupLedgerByDay(visible, mode);
    final targetIndex = groups.indexWhere((g) => isSameDayValue(g.day, day));
    if (targetIndex < 0) return; // O gün hiç işlem yok; şerit vurgusu yeter.

    for (var attempt = 0; attempt < 24; attempt++) {
      if (!mounted) return;
      final ctx = _anchors.contextFor(day);
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      if (!_scrollController.hasClients) return;

      // Yön: kurulmuş başlıkların hangi tarafında kaldık? Defter yeniden
      // eskiye sıralı, yani daha ESKİ bir gün listede daha AŞAĞIDADIR.
      var direction = 1;
      for (var i = 0; i < groups.length; i++) {
        if (_anchors.contextFor(groups[i].day) != null) {
          direction = targetIndex > i ? 1 : -1;
          break;
        }
      }

      final position = _scrollController.position;
      final next = (position.pixels + direction * position.viewportDimension)
          .clamp(0.0, position.maxScrollExtent);
      if (next == position.pixels) return;
      _scrollController.jumpTo(next);
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  /// Aramanın/filtrenin dönem dışında da eşleşme bulup bulmadığı.
  int _matchesOutsidePeriod(
      List<TransactionWithBalance> ledger, CombinedFilter filter) {
    return filterLedger(
      ledger: ledger,
      filter: filter,
      categoryLabels: _categoryLabels,
      applyDateWindow: false,
    ).length;
  }

  /// Dönemi verinin tamamına genişletir ("tüm geçmişte ara").
  void _widenToAllHistory(
      TransactionFilterCubit cubit, List<TransactionWithBalance> ledger) {
    if (ledger.isEmpty) return;
    final today = dayOf(DateTime.now());
    // Defter yeniden eskiye sıralı: ilk eleman en yeni, son eleman en eski.
    var earliest = dayOf(ledger.last.transaction.date);
    var latest = dayOf(ledger.first.transaction.date);
    if (today.isBefore(earliest)) earliest = today;
    if (today.isAfter(latest)) latest = today;
    cubit.setPeriod(DateTimeRange(
      start: earliest,
      end: DateTime(latest.year, latest.month, latest.day, 23, 59, 59),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionFilterCubit, CombinedFilter>(
      builder: (context, filterState) {
        final cubit = context.read<TransactionFilterCubit>();

        return BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionError) {
              AppMessenger.error(state.message);
            } else if (state is TransactionActionSuccess) {
              if (state.warning != null) {
                AppMessenger.error(state.warning!);
              } else {
                showDeletionMessage(context,
                    message: state.message, undo: state.undo);
              }
              _loadData();
              _loadCategoryIcons();
            }
          },
          builder: (context, state) {
            final ledger = _ledgerFor(state.currentTransactions);
            final isLoading = state is TransactionLoading;
            final walletIsEmpty = ledger.isEmpty;
            final mode = filterState.viewFilter.financeMode;

            final visible = filterLedger(
              ledger: ledger,
              filter: filterState,
              categoryLabels: _categoryLabels,
            );

            final period = DateTimeRange(
              start: filterState.viewFilter.startDate,
              end: filterState.viewFilter.endDate,
            );
            final periodHasToday = isDayInRange(DateTime.now(), period);

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  TransactionTopBar(
                    filter: filterState,
                    categoryLabels: _categoryLabels,
                    onModeChanged: cubit.setFinanceMode,
                    onPeriodStep: cubit.stepPeriod,
                    onPeriodPick: () => _pickDateRange(context),
                    onFilterTap: () => _showFilterSheet(context),
                    onClearCategories: () => cubit.setCategories(const {}),
                    onClearPriceRange: () => cubit.setPriceRange(null),
                    onClearSearch: () => cubit.setSearchQuery(null),
                    onClearAllFilters: cubit.clearDataFilters,
                  ),
                  Expanded(
                    child: isLoading && walletIsEmpty
                        ? const TransactionListSkeleton()
                        : CustomScrollView(
                            controller: _scrollController,
                            slivers: _buildSlivers(
                              context: context,
                              cubit: cubit,
                              filterState: filterState,
                              ledger: ledger,
                              visible: visible,
                              mode: mode,
                              period: period,
                              periodHasToday: periodHasToday,
                              walletIsEmpty: walletIsEmpty,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildSlivers({
    required BuildContext context,
    required TransactionFilterCubit cubit,
    required CombinedFilter filterState,
    required List<TransactionWithBalance> ledger,
    required List<TransactionWithBalance> visible,
    required FinanceMode mode,
    required DateTimeRange period,
    required bool periodHasToday,
    required bool walletIsEmpty,
  }) {
    final searchSliver = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: TransactionSearchField(
          value: filterState.dataFilter.searchQuery,
          onChanged: cubit.setSearchQuery,
        ),
      ),
    );

    if (visible.isEmpty) {
      return [
        searchSliver,
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            mode: mode,
            // Cüzdanda hiç kayıt yoksa sorun filtre değildir; "filtreleri
            // temizle" önermek kullanıcıyı yanlış yere gönderir.
            isFiltered: !walletIsEmpty,
            query: filterState.dataFilter.searchQuery,
            // Dönem penceresi artık HER ZAMAN uygulanıyor (eski takvim
            // görünümü onu yok sayıyordu). Bu yüzden "bu ayda yok ama
            // geçmişte var" durumunun bir çıkış yolu olmalı.
            outsidePeriodMatches:
                walletIsEmpty ? 0 : _matchesOutsidePeriod(ledger, filterState),
            onWidenPeriod: () => _widenToAllHistory(cubit, ledger),
            onClearFilters: cubit.clearAll,
          ),
        ),
      ];
    }

    return [
      searchSliver,
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: TransactionSummaryStrip(
            transactions: visible.map((e) => e.transaction).toList(),
            mode: mode,
            filter: filterState,
            periodLabel: periodLabel(period, context.l10n),
            onToday: periodHasToday
                ? null
                : () => cubit.setPeriod(currentPeriodLike(period)),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TransactionDayRail(
            range: period,
            summaries: _summariesFor(visible),
            // Dönem dışına düşen seçim BAYATTIR: kullanıcı bir gün seçip
            // sonra ayı değiştirdiğinde o vurgu artık hiçbir şeyi
            // göstermiyor, üstelik şeridin kendini ortalamasını da
            // engelliyordu.
            selectedDay:
                _selectedDay != null && isDayInRange(_selectedDay!, period)
                    ? _selectedDay
                    : null,
            onDaySelected: (day) => _scrollToDay(day, visible, mode),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
        sliver: TransactionLedgerSliver(
          transactions: visible,
          mode: mode,
          categoryIcons: _categoryIcons,
          categoryLabels: _categoryLabels,
          anchors: _anchors,
        ),
      ),
    ];
  }
}

/// Liste boş kaldığında gösterilen ekran.
///
/// Üç ayrı durum: cüzdan hiç kayıt taşımıyor · filtre/arama bu dönemde
/// eşleşme bırakmadı · bu dönemde yok ama GEÇMİŞTE var. Sonuncusu tek
/// görünüme geçişle birlikte doğdu: takvim modu tarih penceresini yok
/// sayıyordu, artık dönem her zaman uygulanıyor, o yüzden "geçen ay almıştım"
/// diyen kullanıcının çıkış yolu ekranda yazılı olmalı.
class _EmptyState extends StatelessWidget {
  final FinanceMode mode;
  final bool isFiltered;
  final String? query;
  final int outsidePeriodMatches;
  final VoidCallback onWidenPeriod;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.mode,
    required this.isFiltered,
    required this.query,
    required this.outsidePeriodMatches,
    required this.onWidenPeriod,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final accent = mode.primaryColor;
    final hasQuery = query != null && query!.trim().isNotEmpty;
    final hasElsewhere = isFiltered && outsidePeriodMatches > 0;

    final title = !isFiltered
        ? l10n.henuzIslemYok
        : hasElsewhere
            ? l10n.txSearchWidenTitle
            : hasQuery
                ? l10n.txSearchNoResultTitle(query!.trim())
                : l10n.txEmptyFilteredTitle;
    final body = !isFiltered
        ? l10n.buDonemIcinKayit
        : hasElsewhere
            ? l10n.txSearchWidenBody(outsidePeriodMatches)
            : l10n.txEmptyFilteredBody;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.04),
                ],
              ),
              border:
                  Border.all(color: accent.withValues(alpha: 0.25), width: 1),
            ),
            child: Icon(
              !isFiltered
                  ? Icons.receipt_long_rounded
                  : hasElsewhere
                      ? Icons.history_rounded
                      : Icons.filter_alt_off_rounded,
              size: 42,
              color: accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 20),
            if (hasElsewhere)
              FilledButton.tonalIcon(
                onPressed: onWidenPeriod,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(l10n.txSearchWidenAction),
              ),
            if (hasElsewhere) const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: Text(l10n.txEmptyClearFilters),
            ),
          ],
        ],
      ),
    );
  }
}
