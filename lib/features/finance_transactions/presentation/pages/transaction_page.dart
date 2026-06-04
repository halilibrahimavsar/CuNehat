import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode_selector.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/detailed_list_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_header.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    final filterCubit = context.read<TransactionFilterCubit>();
    _loadData(filterCubit.state.viewFilter);
  }

  @override
  void didUpdateWidget(covariant _TransactionsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallet.id != widget.wallet.id) {
      _loadData(context.read<TransactionFilterCubit>().state.viewFilter);
    }
  }

  void _loadData(ViewFilter viewFilter) {
    context.read<TransactionBloc>().add(GetTransactionsEvent(
          userId: widget.userId,
          walletId: widget.wallet.id ?? '',
          startDate: viewFilter.startDate,
          endDate: viewFilter.endDate,
        ));
  }

  List<TransactionWithBalance> _getFilteredData(
      List<TransactionEntity> allTransactions, CombinedFilter filter) {
    // 1. Önce TAM liste üzerinde (yeni→eski) running balance hesapla.
    //    Böylece "işlem sonrası bakiye" gerçek geçmişe göre doğru kalır;
    //    filtreler yalnızca hangi satırların görüneceğini belirler.
    final allSorted = List<TransactionEntity>.from(allTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final withBalance = calculateRunningBalance(
      allSorted,
      widget.wallet.balance,
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
      quickOptions: _buildDateRangeQuickOptions(),
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

  List<IboDateRangeQuickOption> _buildDateRangeQuickOptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = (now.month == 12)
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    final endOfMonth = startOfNextMonth.subtract(const Duration(days: 1));
    final startOfLastMonth = (now.month == 1)
        ? DateTime(now.year - 1, 12, 1)
        : DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = startOfMonth.subtract(const Duration(days: 1));

    return [
      IboDateRangeQuickOption(
        label: 'Son 7 Gün',
        range: DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        ),
      ),
      IboDateRangeQuickOption(
        label: 'Bu Ay',
        range: DateTimeRange(start: startOfMonth, end: endOfMonth),
      ),
      IboDateRangeQuickOption(
        label: 'Geçen Ay',
        range: DateTimeRange(start: startOfLastMonth, end: endOfLastMonth),
      ),
    ];
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
    return BlocConsumer<TransactionFilterCubit, CombinedFilter>(
      listenWhen: (previous, current) {
        return previous.viewFilter.startDate != current.viewFilter.startDate ||
            previous.viewFilter.endDate != current.viewFilter.endDate;
      },
      listener: (context, filterState) {
        _loadData(filterState.viewFilter);
      },
      builder: (context, filterState) {
        return BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionError) {
              IboSnackbar.showError(context, state.message);
            } else if (state is TransactionActionSuccess) {
              IboSnackbar.showSuccess(context, state.message);
              _loadData(filterState.viewFilter);
            }
          },
          builder: (context, state) {
            final List<TransactionEntity> allTransactions =
                state.currentTransactions;
            final isLoading = state is TransactionLoading;
            final isEmpty = allTransactions.isEmpty;

            final filteredData = _getFilteredData(allTransactions, filterState);

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[50]!.withValues(alpha: 0.3),
                    Colors.purple[50]!.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      // 1. Finance Mode Selector (Kaydırılabilir Alan)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: FinanceModeSelector(
                            currentMode: filterState.viewFilter.financeMode,
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
                          ),
                        ),
                      ),
                      // 2. Modern Header (Kaydırılabilir Alan)
                      SliverToBoxAdapter(
                        child: TransactionHeader(
                          startDate: filterState.viewFilter.startDate,
                          endDate: filterState.viewFilter.endDate,
                          allTransactions: allTransactions,
                          mode: filterState.viewFilter.financeMode,
                          currentFilter: filterState,
                          onFilterTap: () => _showFilterSheet(
                            context,
                            context.read<TransactionFilterCubit>(),
                          ),
                          onDateTap: () => _pickDateRange(context, filterState),
                        ),
                      ),
                    ];
                  },
                  // 3. Transaction List (Ana Gövde)
                  body: isLoading && isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : filteredData.isEmpty
                          ? _buildEmptyState()
                          : DetailedListView(
                              transactions: filteredData,
                              mode: filterState.viewFilter.financeMode,
                            ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: Colors.blue[300]),
          const SizedBox(height: 16),
          Text(
            'İşlem bulunmuyor',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'İşlem eklemek için Sürgü buttonuna tıklayın',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
