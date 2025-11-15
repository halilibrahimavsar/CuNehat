import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_bloc.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_event.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_state.dart';
import 'package:cunehat/data_layer/data_repository.dart';
import 'package:cunehat/pages/expense_pages/expense_page.dart';
import 'package:cunehat/pages/income_pages/income_page.dart';
import 'package:cunehat/pages/summary_pages/compare_view.dart';
import 'package:cunehat/shared/animations/cube_animation_view.dart';
import 'package:cunehat/shared/animations/slider_button_view.dart';
import 'package:cunehat/shared/widgets/build_drawer.dart';
import 'package:cunehat/shared/widgets/shared_appbar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    // Sayfa açıldığında bekleyen işlemleri senkronize et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPendingOperations();
    });
  }

  void _updateDateFilter() {
    _filterEndDate = DateTime.now();
    _filterStartDate = _filterEndDate.subtract(const Duration(days: 30));
  }

  void _fetchData() {
    context.read<DataBloc>().add(
          GetCompareEvent(
            filterStart: _filterStartDate,
            filterEnd: _filterEndDate,
          ),
        );
  }

// wallet_page.dart - Senkronizasyon durumunu göster:
  Future<void> _syncPendingOperations() async {
    final repository = context.read<DataRepository>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 10),
            Text("Senkronizasyon yapılıyor..."),
          ],
        ),
        duration: Duration(seconds: 5),
      ),
    );

    final result = await repository.syncNow();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Senkronizasyon başarılı"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Senkronizasyon başarısız"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        drawer: SharedDrawer(),
        body: BlocListener<DataBloc, DataState>(
          listener: (context, state) {
            if (state is ErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Hata: ${state.err}"),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is SuccessfullyCreatedItemState ||
                state is SuccessfullyDeletedItemState ||
                state is SuccessfullyUpdatedItemState) {
              _fetchData();
            }
          },
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<DataBloc, DataState>(
                  buildWhen: (previous, current) {
                    return current is LoadingDataState ||
                        current is SuccessfullyGetCompareState ||
                        current is NoDataState ||
                        current is ErrorState;
                  },
                  builder: (context, state) {
                    Map<DateTime, List<Income>> incomeData = {};
                    Map<DateTime, List<Expense>> expenseData = {};
                    Widget? centerWidget;

                    if (state is LoadingDataState) {
                      centerWidget = const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (state is ErrorState) {
                      centerWidget = Center(
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
                              "Veriler yüklenemedi",
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.err,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else if (state is NoDataState) {
                      // Veri yok
                    } else if (state is SuccessfullyGetCompareState) {
                      incomeData = state.income;
                      expenseData = state.expense;
                    }

                    if (centerWidget != null) {
                      return centerWidget;
                    }

                    return Center(
                      child: CubeAnimationView(
                        controller: _controller,
                        firstView: ExpenseView(expenseData: expenseData),
                        secondView: IncomeView(incomeData: incomeData),
                        thirdView: CompareView(
                          incomeData: incomeData,
                          expenseData: expenseData,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // SLIDER BUTTON
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SliderButtonExpenseIncome(controller: _controller),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
