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
import 'package:cunehat/shared/widgets/shared_appbar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _syncPendingOperations() async {
    final repository = context.read<DataRepository>();
    final result = await repository.syncNow();

    if (result && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bekleyen işlemler senkronize edildi"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      _fetchData(); // Verileri yeniden çek
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
        drawer: Drawer(
          elevation: 1,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'CuNehat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Finansal Yönetim',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  final repo = context.watch<DataRepository>();
                  final count = repo.getPendingSyncCount();

                  return ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text("Şimdi Senkronize Et"),
                    trailing: count > 0
                        ? Badge(
                            label: Text('$count'),
                            child: const Icon(Icons.cloud_upload),
                          )
                        : const Icon(Icons.cloud_done),
                    onTap: () {
                      Navigator.pop(context);
                      _syncPendingOperations();
                    },
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text("Debug: Yerel Verileri Göster"),
                onTap: () async {
                  Navigator.pop(context);
                  final repo = context.read<DataRepository>();
                  final allIncomes = await repo.getAllIncomes();
                  final allExpenses = await repo.getAllExpenses();
                  final mode = repo.getStorageMode();

                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Debug Bilgisi"),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Mod: ${mode.name}"),
                              const Divider(),
                              Text("Gelir Sayısı: ${allIncomes.length}"),
                              ...allIncomes.take(3).map(
                                  (i) => Text("- ${i.title}: ${i.amount}₺")),
                              const Divider(),
                              Text("Gider Sayısı: ${allExpenses.length}"),
                              ...allExpenses.take(3).map(
                                  (e) => Text("- ${e.title}: ${e.amount}₺")),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Kapat"),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Ayarlar"),
                onTap: () {
                  Navigator.pop(context);
                  context.push("/settings");
                },
              ),
            ],
          ),
        ),
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
