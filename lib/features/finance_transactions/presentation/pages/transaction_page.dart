import 'package:cunehat/core/shared/widgets/date_range_picker.dart';
import 'package:cunehat/core/utilities/date_range_helper.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/transaction_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/detailed_list_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/timeline_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_view_type.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionsPage extends StatefulWidget {
  final String userId;
  final WalletEntity wallet;

  const TransactionsPage({
    super.key,
    required this.userId,
    required this.wallet,
  });

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late TransactionFilter _filter;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    // DateRangeHelper ile bu ayın tam aralığını alıyoruz (Başlangıç 00:00, Bitiş 23:59)
    final monthRange = DateRangeHelper.getMonthRange(DateTime.now());
    // Default filter: Current month, Compare mode, Daily view
    _filter = TransactionFilter(
      financeMode: FinanceMode.compare,
      viewType: TransactionViewType.timeline,
      startDate: monthRange.start,
      endDate: monthRange.end,
    );

    // Initial Data Load
    _loadData();
  }

  @override
  void didUpdateWidget(covariant TransactionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallet.id != widget.wallet.id) {
      _loadData();
    }
  }

  void _loadData() {
    context.read<TransactionBloc>().add(GetTransactionsEvent(
          userId: widget.userId,
          walletId: widget.wallet.id ?? '',
          startDate: _filter.startDate,
          endDate: _filter.endDate,
        ));
    // update wallet realtime
    context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
  }

  void _onFilterChanged(TransactionFilter newFilter) {
    final dateChanged = newFilter.startDate != _filter.startDate ||
        newFilter.endDate != _filter.endDate;

    setState(() {
      _filter = newFilter;
    });

    if (dateChanged) {
      _loadData();
    }
  }

  List<TransactionWithBalance> _getFilteredData(
      List<TransactionEntity> allTransactions) {
    // ✅ Sort transactions by date (newest first)
    List<TransactionEntity> filtered = List.from(allTransactions);

    // 1. Filter by FinanceMode
    if (_filter.financeMode == FinanceMode.expense) {
      filtered = filtered.where((element) => element.isExpense).toList();
    } else if (_filter.financeMode == FinanceMode.income) {
      filtered = filtered.where((element) => !element.isExpense).toList();
    }

    // 2. Filter by Categories
    if (_filter.selectedCategories.isNotEmpty) {
      filtered = filtered
          .where((t) => _filter.selectedCategories.contains(t.tag))
          .toList();
    }

    // 3. Filter by PriceRange
    if (_filter.priceRange != null) {
      filtered = filtered
          .where((t) => _filter.priceRange!.isInRange(t.amount))
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

  Future<void> _pickDateRange() async {
    await showModernDateRangePicker(
      context: context,
      start: _filter.startDate,
      end: _filter.endDate,
      onApply: (start, end) {
        _onFilterChanged(_filter.copyWith(
          startDate: start,
          endDate: end,
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionError) {
          SnackbarHelper.showError(context, state.message);
        } else if (state is TransactionActionSuccess) {
          SnackbarHelper.showSuccess(context, state.message);
          // İşlem başarılı olduğunda listeyi güncelle
          _loadData();
        }
      },
      builder: (context, state) {
        // Her durumda mevcut veriyi kullan (Loading, Error, Success dahil)
        final List<TransactionEntity> allTransactions =
            state.currentTransactions;
        final isLoading = state is TransactionLoading;
        final isEmpty = allTransactions.isEmpty;

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
                  filter: _filter,
                  isMenuOpen: _isMenuOpen,
                  onMenuToggle: () =>
                      setState(() => _isMenuOpen = !_isMenuOpen),
                  onDateTap: _pickDateRange,
                  onFilterChanged: _onFilterChanged,
                ),

                // ========== MODERN HEADER ==========
                TransactionHeader(
                  startDate: _filter.startDate,
                  endDate: _filter.endDate,
                  allTransactions: allTransactions,
                  mode: _filter.financeMode,
                ),

                // ========== TRANSACTION LIST ==========
                Expanded(
                  child: isLoading && isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _getFilteredData(allTransactions).isEmpty
                          ? _buildEmptyState()
                          : _filter.viewType == TransactionViewType.list
                              ? DetailedListView(
                                  transactions:
                                      _getFilteredData(allTransactions),
                                  mode: _filter.financeMode,
                                )
                              : TimelineView(
                                  transactions:
                                      _getFilteredData(allTransactions),
                                  mode: _filter.financeMode,
                                ),
                ),
              ],
            ),
          ),
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
