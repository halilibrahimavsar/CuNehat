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
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_calendar_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_list_skeleton.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_top_bar.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  /// Liste ↔ Takvim görünüm modu (saf sunum; filtre cubit'ine taşımaya gerek
  /// yok). Varsayılan Takvim: uygulama açılışta İşlemler (orta) görünümüne
  /// geldiğinden kullanıcı doğrudan takvimi görür.
  bool _isCalendarView = true;

  StreamSubscription<void>? _categoriesSub;

  /// Defter önbelleği: sıralama + running balance zinciri PAHALI ve yalnız
  /// işlem listesi değişince gerekir. Filtre/arama her tuş vuruşunda
  /// değiştiği için bunu her build'de kurmak listeyi tuş başına yeniden
  /// sıralamak demekti.
  List<TransactionEntity>? _ledgerSource;
  double? _ledgerBalance;
  List<TransactionWithBalance> _ledger = const [];

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
              // Material (renkli Container değil): panel artık InkWell,
              // Checkbox ve TextButton kullanıyor; opak bir DecoratedBox
              // araya girerse mürekkep dalgası ARKASINA boyanır ve görünmez
              // olur (Flutter debug'da da uyarır).
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

            // Takvim dönemi kendi çizer (kullanıcı dönem dışına da
            // gezinebilmeli); liste dönem penceresini uygular.
            final visible = filterLedger(
              ledger: ledger,
              filter: filterState,
              categoryLabels: _categoryLabels,
              applyDateWindow: !_isCalendarView,
            );

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TopBarDelegate(
                        height:
                            TransactionTopBar.heightFor(filterState.dataFilter),
                        child: TransactionTopBar(
                          filter: filterState,
                          isCalendarView: _isCalendarView,
                          categoryLabels: _categoryLabels,
                          onViewModeChanged: (isCalendar) =>
                              setState(() => _isCalendarView = isCalendar),
                          onModeChanged: cubit.setFinanceMode,
                          onSearchChanged: cubit.setSearchQuery,
                          onPeriodStep: cubit.stepPeriod,
                          onPeriodPick: () => _pickDateRange(context),
                          onFilterTap: () => _showFilterSheet(context),
                          onClearCategories: () =>
                              cubit.setCategories(const {}),
                          onClearPriceRange: () => cubit.setPriceRange(null),
                          onClearAllFilters: cubit.clearDataFilters,
                        ),
                      ),
                    ),
                    // Salt-veri özet kartı (yalnız liste modunda; takvimin
                    // kendi dönem özeti var).
                    if (!_isCalendarView)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: TransactionHeader(
                            allTransactions:
                                visible.map((e) => e.transaction).toList(),
                            mode: filterState.viewFilter.financeMode,
                            currentFilter: filterState,
                          ),
                        ),
                      ),
                  ];
                },
                body: isLoading && walletIsEmpty
                    ? const TransactionListSkeleton()
                    // Boş durum HER İKİ görünümde de gösterilir: takvim
                    // modunda dönem penceresi uygulanmadığı için boş sonuç
                    // "tüm geçmişte hiçbir şey eşleşmedi" demektir ve ızgarayı
                    // çizmek kullanıcıya çıkışsız bir boşluk bırakıyordu.
                    : visible.isEmpty
                        ? _EmptyState(
                            mode: filterState.viewFilter.financeMode,
                            // Cüzdanda hiç kayıt yoksa sorun filtre değildir;
                            // "filtreleri temizle" önermek kullanıcıyı yanlış
                            // yere gönderir.
                            isFiltered: !walletIsEmpty,
                            query: filterState.dataFilter.searchQuery,
                            onClearFilters: cubit.clearAll,
                          )
                        : _isCalendarView
                            ? TransactionCalendarView(
                                transactions: visible,
                                categoryIcons: _categoryIcons,
                                categoryLabels: _categoryLabels,
                                range: cubit.period,
                                onRangeChanged: cubit.setPeriod,
                              )
                            : DetailedListView(
                                transactions: visible,
                                mode: filterState.viewFilter.financeMode,
                                categoryIcons: _categoryIcons,
                                categoryLabels: _categoryLabels,
                              ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Sabit (pinned) kontrol çubuğunu taşıyan delegate.
///
/// Yükseklik değişkendir: aktif filtre çipi şeridi yalnız gerektiğinde yer
/// kaplar, o yüzden [height] delegate'in kimliğinin parçasıdır.
class _TopBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _TopBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Material: çubuktaki dönem okları ve filtre düğmesi InkWell/InkResponse
    // kullanıyor; renkli bir Container mürekkebi yutar.
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TopBarDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

/// Liste boş kaldığında gösterilen ekran.
///
/// Eskiden tek bir metin vardı ("Henüz işlem yok") ve filtre yüzünden boşalan
/// liste de aynı şeyi söylüyordu: kullanıcı ne olduğunu anlamıyor, çıkış yolu
/// da bulamıyordu. Artık iki ayrı durum var ve filtreli durumda tek dokunuşla
/// temizleme sunuluyor.
class _EmptyState extends StatelessWidget {
  final FinanceMode mode;
  final bool isFiltered;
  final String? query;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.mode,
    required this.isFiltered,
    required this.query,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final accent = mode.primaryColor;
    final hasQuery = query != null && query!.trim().isNotEmpty;

    final title = !isFiltered
        ? l10n.henuzIslemYok
        : hasQuery
            ? l10n.txSearchNoResultTitle(query!.trim())
            : l10n.txEmptyFilteredTitle;
    final body = isFiltered ? l10n.txEmptyFilteredBody : l10n.buDonemIcinKayit;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                      border: Border.all(
                          color: accent.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Icon(
                      isFiltered
                          ? Icons.filter_alt_off_rounded
                          : Icons.receipt_long_rounded,
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
                    FilledButton.tonalIcon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: Text(l10n.txEmptyClearFilters),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
