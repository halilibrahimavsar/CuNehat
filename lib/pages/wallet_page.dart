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

/// **WalletPage**: FINAL FIX
///
/// KEY FIX:
/// - BlocListener ONLY listens to feedback states (CRUD success/error, sync)
/// - BlocListener IGNORES data states (SuccessfullyGetCompareState)
/// - BlocBuilder handles ALL states including data updates
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
  double _currentSliderValue = 0;

  @override
  void initState() {
    super.initState();
    print('🟢 [WALLET] Page initialized');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _controller.addListener(() {
      setState(() {
        _currentSliderValue = _controller.value;
      });
    });

    _updateDateFilter();
    print('🟢 [WALLET] Date filter: $_filterStartDate → $_filterEndDate');

    print('🟢 [WALLET] Calling _fetchData()...');
    _fetchData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(
          '🟢 [WALLET] Post-frame callback, calling _syncPendingOperations()...');
      _syncPendingOperations();
    });
  }

  void _updateDateFilter() {
    _filterEndDate = DateTime.now();
    _filterStartDate = _filterEndDate.subtract(const Duration(days: 30));
  }

  void _fetchData() {
    print('📤 [WALLET] Dispatching GetCompareEvent');
    context.read<DataBloc>().add(
          GetCompareEvent(
            filterStart: _filterStartDate,
            filterEnd: _filterEndDate,
          ),
        );
  }

  Future<void> _syncPendingOperations() async {
    print('🔄 [WALLET] Dispatching SyncDataEvent');
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
    print('🔄 [WALLET] build() called');

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: SharedAppbar(
          currentSliderValue: _currentSliderValue,
        ),
        drawer: const SharedDrawer(),
        body: BlocListener<DataBloc, DataState>(
          // ⚠️ CRITICAL FIX: Only listen to feedback states, NOT data states
          listenWhen: (previous, current) {
            // ONLY listen to these specific states:
            final shouldListen = current is ErrorState ||
                current is SuccessfullyCreatedItemState ||
                current is SuccessfullyDeletedItemState ||
                current is SuccessfullyUpdatedItemState ||
                current is SyncingDataState ||
                current is SyncSuccessState ||
                current is SyncFailedState;

            if (!shouldListen &&
                current is! LoadingDataState &&
                current is! NoDataState) {
              print(
                  '👂 [WALLET LISTENER] IGNORING state: ${current.runtimeType}');
            }

            return shouldListen;
          },
          listener: (context, state) {
            print('👂 [WALLET LISTENER] State received: ${state.runtimeType}');

            // ERROR HANDLING
            if (state is ErrorState) {
              print('   ❌ Error state: ${state.err}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.err),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }

            // CRUD SUCCESS FEEDBACK
            else if (state is SuccessfullyCreatedItemState) {
              print('   ✓ Item created - showing snackbar');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Başarıyla eklendi'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (state is SuccessfullyDeletedItemState) {
              print('   ✓ Item deleted - showing snackbar');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Başarıyla silindi'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (state is SuccessfullyUpdatedItemState) {
              print('   ✓ Item updated - showing snackbar');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Başarıyla güncellendi'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }

            // SYNC STATUS
            else if (state is SyncingDataState) {
              print('   🔄 Syncing...');
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
              print('   ✓ Sync success');
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
              print('   ⚠️  Sync failed');
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
                  // ⚠️ FIX: Builder rebuilds on EVERY state change
                  builder: (context, state) {
                    print(
                        '🏗️  [WALLET BUILDER] Building with state: ${state.runtimeType}');

                    // LOADING STATE
                    if (state is LoadingDataState) {
                      print('   ⏳ Showing loading indicator');
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    // ERROR STATE
                    if (state is ErrorState) {
                      print('   ❌ Showing error view');
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

                    // NO DATA STATE
                    if (state is NoDataState) {
                      print('   ℹ️  Showing no data view');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz veri yok',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gelir veya gider ekleyerek başlayın',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    // DATA EXTRACTION
                    Map<DateTime, List<Income>> incomeData = {};
                    Map<DateTime, List<Expense>> expenseData = {};

                    if (state is SuccessfullyGetCompareState) {
                      print('   📊 Compare state with data');
                      incomeData = state.income;
                      expenseData = state.expense;
                      print(
                          '   Income days: ${incomeData.length}, Expense days: ${expenseData.length}');
                      print(
                          '   Total income items: ${incomeData.values.expand((x) => x).length}');
                      print(
                          '   Total expense items: ${expenseData.values.expand((x) => x).length}');
                    } else if (state is SuccessfullyGetIncomeState) {
                      print('   📊 Income state with data');
                      incomeData = state.data;
                      print('   Income days: ${incomeData.length}');
                    } else if (state is SuccessfullyGetExpenseState) {
                      print('   📊 Expense state with data');
                      expenseData = state.data;
                      print('   Expense days: ${expenseData.length}');
                    } else if (state is SuccessfullyCreatedItemState ||
                        state is SuccessfullyDeletedItemState ||
                        state is SuccessfullyUpdatedItemState) {
                      // ⚠️ CRITICAL: These states appear BEFORE silent refresh completes
                      // Show previous data (will be updated when SuccessfullyGetCompareState arrives)
                      print(
                          '   ⚠️  CRUD state - keeping previous data, waiting for refresh');
                      // Return empty for now, silent refresh will update soon
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else {
                      print(
                          '   ⚠️  Unhandled state type: ${state.runtimeType}');
                    }

                    // BUILD VIEWS
                    print('   🏗️  Building cube animation view');
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

              // VIEW SLIDER
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SliderButtonExpenseIncome(
                  controller: _controller,
                  onValueChanged: (double value) {
                    // Optional
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
