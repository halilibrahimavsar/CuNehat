import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_bloc.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_event.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_state.dart';
import 'package:cunehat/pages/expense_pages/expense_page.dart';
import 'package:cunehat/pages/income_pages/income_page.dart';
import 'package:cunehat/pages/summary_pages/compare_view.dart';
import 'package:cunehat/shared/animations/cube_animation_view.dart';
import 'package:cunehat/shared/animations/slider_button_view.dart';
import 'package:cunehat/shared/widgets/build_drawer.dart';
import 'package:cunehat/shared/widgets/shared_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// **WalletPage**: Main page displaying income/expense data with sync support
///
/// Features:
/// - Three-way view switching (Income/Compare/Expense)
/// - Auto-refresh after CRUD operations
/// - Sync status monitoring
/// - Date range filtering
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late DateTime _filterStartDate;
  late DateTime _filterEndDate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _updateDateFilter();
    _fetchData();

    // Auto-sync on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPendingOperations();
    });
  }

  /// Updates date filter to last 30 days
  void _updateDateFilter() {
    _filterEndDate = DateTime.now();
    _filterStartDate = _filterEndDate.subtract(const Duration(days: 30));
  }

  /// Fetches data for current date range
  void _fetchData() {
    context.read<DataBloc>().add(
          GetCompareEvent(
            filterStart: _filterStartDate,
            filterEnd: _filterEndDate,
          ),
        );
  }

  /// Syncs pending operations and shows status
  Future<void> _syncPendingOperations() async {
    context.read<DataBloc>().add(
          SyncDataEvent(
            dateRange: {
              'start': _filterStartDate,
              'end': _filterEndDate,
            },
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: const SharedAppbar(),
        drawer: const SharedDrawer(),
        body: BlocListener<DataBloc, DataState>(
          listener: (context, state) {
            // ============ ERROR HANDLING ============
            if (state is ErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.err),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }

            // ============ CRUD SUCCESS - AUTO REFRESH ============
            else if (state is SuccessfullyCreatedItemState ||
                state is SuccessfullyDeletedItemState ||
                state is SuccessfullyUpdatedItemState) {
              // Auto-refresh data after any CRUD operation
              _fetchData();

              // Show success feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state is SuccessfullyCreatedItemState
                        ? '✓ Başarıyla eklendi'
                        : state is SuccessfullyDeletedItemState
                            ? '✓ Başarıyla silindi'
                            : '✓ Başarıyla güncellendi',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }

            // ============ SYNC STATUS ============
            else if (state is SyncingDataState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Senkronizasyon yapılıyor...'),
                    ],
                  ),
                  duration: Duration(seconds: 30),
                ),
              );
            } else if (state is SyncSuccessState) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('✓ Senkronizasyon tamamlandı'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (state is SyncFailedState) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text('✗ Senkronizasyon başarısız'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<DataBloc, DataState>(
                  buildWhen: (previous, current) {
                    // Only rebuild for these specific states
                    return current is LoadingDataState ||
                        current is SuccessfullyGetCompareState ||
                        current is NoDataState ||
                        current is ErrorState;
                  },
                  builder: (context, state) {
                    // ============ LOADING STATE ============
                    if (state is LoadingDataState) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    // ============ ERROR STATE ============
                    if (state is ErrorState) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Veriler yüklenemedi',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                state.err,
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _fetchData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      );
                    }

                    // ============ DATA STATE ============
                    Map<DateTime, List<Income>> incomeData = {};
                    Map<DateTime, List<Expense>> expenseData = {};

                    if (state is SuccessfullyGetCompareState) {
                      incomeData = state.income;
                      expenseData = state.expense;
                    }

                    return CubeAnimationView(
                      controller: _controller,
                      firstView: ExpenseView(expenseData: expenseData),
                      secondView: IncomeView(incomeData: incomeData),
                      thirdView: CompareView(
                        incomeData: incomeData,
                        expenseData: expenseData,
                      ),
                    );
                  },
                ),
              ),

              // ============ VIEW SLIDER ============
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SliderButtonExpenseIncome(controller: _controller),
              ),
            ],
          ),
        ),

        // ============ SYNC BUTTON ============
        // floatingActionButton: FloatingActionButton(
        //   onPressed: _syncPendingOperations,
        //   tooltip: 'Senkronize Et',
        //   child: const Icon(Icons.sync),
        // ),
      ),
    );
  }
}
