import 'package:cunehat/core/shared/widgets/date_range_picker.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/transaction_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/timeline_view.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
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
    // 1. ADIM: Cubit'i burada oluşturuyoruz (Scope: Sadece bu sayfa)
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
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    // 2. ADIM: Artık context.read çalışır çünkü Provider bir üst widget'ta (TransactionsPage)
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
    // update wallet realtime
    context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
  }

  List<TransactionWithBalance> _getFilteredData(
      List<TransactionEntity> allTransactions, CombinedFilter filter) {
    // ✅ Sort transactions by date (newest first)
    List<TransactionEntity> filtered = List.from(allTransactions);

    // 1. Filter by FinanceMode
    if (filter.viewFilter.financeMode == FinanceMode.expense) {
      filtered = filtered.where((element) => element.isExpense).toList();
    } else if (filter.viewFilter.financeMode == FinanceMode.income) {
      filtered = filtered.where((element) => !element.isExpense).toList();
    }

    // 2. Filter by Categories
    if (filter.dataFilter.selectedCategories.isNotEmpty) {
      filtered = filtered
          .where((t) => filter.dataFilter.selectedCategories.contains(t.tag))
          .toList();
    }

    // 3. Filter by PriceRange
    if (filter.dataFilter.priceRange != null) {
      filtered = filtered
          .where((t) => filter.dataFilter.priceRange!.isInRange(t.amount))
          .toList();
    }

    // 4. Sort (Newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    // ✅ Calculate running balance for each transaction
    final transactionsWithBalance = calculateRunningBalance(
      filtered,
      widget.wallet.balance,
    );

    return transactionsWithBalance;
  }

  Future<void> _pickDateRange(
      BuildContext context, CombinedFilter currentFilter) async {
    await showModernDateRangePicker(
      context: context,
      start: currentFilter.viewFilter.startDate,
      end: currentFilter.viewFilter.endDate,
      onApply: (start, end) {
        context.read<TransactionFilterCubit>().updateFilter(
              currentFilter.copyWith(
                viewFilter: currentFilter.viewFilter.copyWith(
                  startDate: start,
                  endDate: end,
                ),
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. ADIM: Doğrudan BlocConsumer kullanabiliriz
    return BlocConsumer<TransactionFilterCubit, CombinedFilter>(
      listenWhen: (previous, current) {
        // Sadece tarih değiştiğinde veri çekme işlemini tetikle
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
              SnackbarHelper.showError(context, state.message);
            } else if (state is TransactionActionSuccess) {
              SnackbarHelper.showSuccess(context, state.message);
              // İşlem başarılı olduğunda listeyi güncelle
              _loadData(filterState.viewFilter);
            }
          },
          builder: (context, state) {
            // Her durumda mevcut veriyi kullan (Loading, Error, Success dahil)
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
                child: Column(
                  children: [
                    // ========== FILTER VIEW ==========
                    FilterView(
                      filter: filterState,
                      isMenuOpen: _isMenuOpen,
                      onMenuToggle: () =>
                          setState(() => _isMenuOpen = !_isMenuOpen),
                      onDateTap: () => _pickDateRange(context, filterState),
                      onFilterChanged: (newFilter) {
                        context
                            .read<TransactionFilterCubit>()
                            .updateFilter(newFilter);
                      },
                    ),

                    // ========== MODERN HEADER ==========
                    TransactionHeader(
                      startDate: filterState.viewFilter.startDate,
                      endDate: filterState.viewFilter.endDate,
                      allTransactions: allTransactions,
                      mode: filterState.viewFilter.financeMode,
                    ),

                    // ========== TRANSACTION LIST ==========
                    Expanded(
                      child: isLoading && isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : filteredData.isEmpty
                              ? _buildEmptyState()
                              : DetailedListView(
                                  transactions: filteredData,
                                  mode: filterState.viewFilter.financeMode,
                                ),
                    ),
                  ],
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
            'işlem bulunmuyor',
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
