import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/detailed_list_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_calendar_view.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_filter_bar.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_list_skeleton.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_header.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

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
  /// Kategori adı (tag) → ikon. İşlem kartlarında gerçek kategori glyph'i için.
  Map<String, IconData> _categoryIcons = {};

  /// Liste ↔ Takvim görünüm modu (saf sunum; filtre cubit'ine taşımaya gerek yok).
  _ViewMode _viewMode = _ViewMode.list;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCategoryIcons();
  }

  Future<void> _loadCategoryIcons() async {
    final service = getIt<CategoryRepository>();
    final results = await Future.wait([
      service.getExpenseCategories(),
      service.getIncomeCategories(),
    ]);
    if (!mounted) return;
    final map = <String, IconData>{};
    for (final list in results) {
      for (final c in list) {
        map[c.id] = AppIcons.getIconData(c.iconName);
      }
    }
    setState(() => _categoryIcons = map);
  }

  @override
  void didUpdateWidget(covariant _TransactionsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallet.id != widget.wallet.id) {
      _loadData();
    }
  }

  /// Her zaman cüzdanın TAM geçmişini çeker; tarih aralığı dahil tüm
  /// filtreler bellekte uygulanır. Böylece running balance çapası
  /// (güncel bakiye) hiçbir aralıkta yanlış düşmez.
  void _loadData() {
    context.read<TransactionBloc>().add(GetTransactionsEvent(
          userId: widget.userId,
          walletId: widget.wallet.id ?? '',
        ));
  }

  List<TransactionWithBalance> _getFilteredData(
      List<TransactionEntity> allTransactions, CombinedFilter filter,
      {bool applyDateWindow = true}) {
    // 0. Guard: cüzdan geçişi sırasında bloc state'i kısa süre ESKİ cüzdanın
    //    listesini taşıyabilir (TransactionLoading.previousTransactions).
    //    Yabancı cüzdan satırları yeni bakiyeye çapalanmasın.
    final walletTransactions =
        allTransactions.where((t) => t.walletId == widget.wallet.id).toList();

    // 1. Tam geçmiş üzerinde running balance + tarih penceresi.
    final withBalance = buildLedgerView(
      allTransactions: walletTransactions,
      currentBalance: widget.wallet.balance,
      start: applyDateWindow ? filter.viewFilter.startDate : null,
      end: applyDateWindow ? filter.viewFilter.endDate : null,
    );

    // 2. Görüntü filtrelerini TransactionWithBalance listesine uygula.
    Iterable<TransactionWithBalance> filtered = withBalance;

    // FinanceMode
    if (filter.viewFilter.financeMode == FinanceMode.expense) {
      filtered = filtered.where((e) => e.transaction.isExpense);
    } else if (filter.viewFilter.financeMode == FinanceMode.income) {
      filtered = filtered.where((e) => !e.transaction.isExpense);
    }

    // Kategoriler
    if (filter.dataFilter.selectedCategories.isNotEmpty) {
      filtered = filtered.where((e) =>
          filter.dataFilter.selectedCategories.contains(e.transaction.tag));
    }

    // Fiyat aralığı
    if (filter.dataFilter.priceRange != null) {
      filtered = filtered.where(
          (e) => filter.dataFilter.priceRange!.isInRange(e.transaction.amount));
    }

    return filtered.toList();
  }

  Future<void> _pickDateRange(
      BuildContext context, CombinedFilter currentFilter) async {
    final cubit = context.read<TransactionFilterCubit>();

    final dateRange = await IboDateRangePicker.pickDateRange(
      context,
      initialDateRange: DateTimeRange(
        start: currentFilter.viewFilter.startDate,
        end: currentFilter.viewFilter.endDate,
      ),
      quickOptions: DateRangeHelper.buildDateRangeQuickOptions(),
    );

    if (dateRange != null) {
      cubit.updateFilter(
        currentFilter.copyWith(
          viewFilter: currentFilter.viewFilter.copyWith(
            startDate: dateRange.start,
            endDate: dateRange.end,
          ),
        ),
      );
    }
  }

  void _showFilterSheet(
      BuildContext parentContext, TransactionFilterCubit cubit) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<TransactionFilterCubit, CombinedFilter>(
            builder: (sheetBuilderContext, state) {
              return Container(
                height: MediaQuery.of(sheetBuilderContext).size.height * 0.85,
                decoration: BoxDecoration(
                  color: Theme.of(sheetBuilderContext).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: FilterView(
                  filter: state,
                  isMenuOpen: true,
                  onMenuToggle: () => Navigator.pop(sheetBuilderContext),
                  onDateTap: () {
                    _pickDateRange(sheetBuilderContext, state);
                  },
                  onFilterChanged: (newFilter) {
                    cubit.updateFilter(newFilter);
                  },
                  useFixedMenuHeight: false,
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
    // Tarih aralığı bellekte filtrelendiği için tarih değişiminde yeniden
    // veri çekmeye gerek yok; rebuild yeterli.
    return BlocBuilder<TransactionFilterCubit, CombinedFilter>(
      builder: (context, filterState) {
        return BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionError) {
              IboSnackbar.showError(context, state.message);
            } else if (state is TransactionActionSuccess) {
              if (state.warning != null) {
                IboSnackbar.showError(context, state.warning!);
              } else {
                IboSnackbar.showSuccess(context, state.message);
              }
              _loadData();
              _loadCategoryIcons();
            }
          },
          builder: (context, state) {
            final List<TransactionEntity> allTransactions =
                state.currentTransactions;
            final isLoading = state is TransactionLoading;
            final isEmpty = allTransactions.isEmpty;

            final filteredData = _getFilteredData(allTransactions, filterState);

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    // 1. İnce sticky kontrol çubuğu (mod + tarih + filtre)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _FilterBarDelegate(
                        child: Row(
                          children: [
                            Expanded(
                              child: TransactionFilterBar(
                                currentMode: filterState.viewFilter.financeMode,
                                startDate: filterState.viewFilter.startDate,
                                endDate: filterState.viewFilter.endDate,
                                dataFilter: filterState.dataFilter,
                                onModeChanged: (mode) {
                                  context
                                      .read<TransactionFilterCubit>()
                                      .updateFilter(
                                        filterState.copyWith(
                                          viewFilter: filterState.viewFilter
                                              .copyWith(financeMode: mode),
                                          dataFilter: filterState.dataFilter
                                              .copyWith(clearCategories: true),
                                        ),
                                      );
                                },
                                onDateTap: () =>
                                    _pickDateRange(context, filterState),
                                onFilterTap: () => _showFilterSheet(
                                  context,
                                  context.read<TransactionFilterCubit>(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ViewModeToggle(
                              mode: _viewMode,
                              onChanged: (m) => setState(() => _viewMode = m),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 2. Salt-veri özet kartı (yalnız liste modunda)
                    if (_viewMode == _ViewMode.list)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: TransactionHeader(
                            // Liste ile aynı süzülmüş veriden besle: kategori/fiyat
                            // filtreleri de kart toplamlarına yansısın.
                            allTransactions:
                                filteredData.map((e) => e.transaction).toList(),
                            mode: filterState.viewFilter.financeMode,
                            currentFilter: filterState,
                          ),
                        ),
                      ),
                  ];
                },
                // 3. Ana gövde: liste ya da takvim görünümü
                body: isLoading && isEmpty
                    ? const TransactionListSkeleton()
                    : _viewMode == _ViewMode.calendar
                        ? TransactionCalendarView(
                            transactions: _getFilteredData(
                                allTransactions, filterState,
                                applyDateWindow: false),
                            categoryIcons: _categoryIcons,
                          )
                        : filteredData.isEmpty
                            ? _buildEmptyState(
                                filterState.viewFilter.financeMode)
                            : DetailedListView(
                                transactions: filteredData,
                                mode: filterState.viewFilter.financeMode,
                                categoryIcons: _categoryIcons,
                              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(FinanceMode mode) {
    final accent = mode.primaryColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scheme = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                  child:
                      Icon(Icons.receipt_long_rounded, size: 42, color: accent),
                ),
                const SizedBox(height: 20),
                Text(
                  context.l10n.henuzIslemYok,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.buDonemIcinKayit,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sticky filtre çubuğunu sabit yükseklikte pinned tutan delegate.
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterBarDelegate({required this.child});

  static const double _height = 56;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: _height,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) =>
      oldDelegate.child != child;
}

/// İşlemler ekranının ana gövde modu.
enum _ViewMode { list, calendar }

/// Filtre çubuğunun sağındaki kompakt Liste ↔ Takvim geçişi.
class _ViewModeToggle extends StatelessWidget {
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;

  const _ViewModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(context, _ViewMode.list, Icons.view_agenda_rounded,
              context.l10n.gorunumListe),
          _segment(context, _ViewMode.calendar, Icons.calendar_month_rounded,
              context.l10n.gorunumTakvim),
        ],
      ),
    );
  }

  Widget _segment(
      BuildContext context, _ViewMode m, IconData icon, String tooltip) {
    final scheme = Theme.of(context).colorScheme;
    final selected = mode == m;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onChanged(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppGradients.transactions : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected
                ? Colors.white
                : scheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
