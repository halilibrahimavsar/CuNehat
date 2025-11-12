import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_bloc.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_event.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_state.dart';
import 'package:cunehat/pages/expense_pages/expense_page.dart';
import 'package:cunehat/pages/income_pages/income_page.dart';
import 'package:cunehat/pages/summary_pages/summary_page.dart';
import 'package:cunehat/shared/animations/cube_animation_view.dart';
import 'package:cunehat/shared/animations/slider_button_view.dart';
import 'package:cunehat/shared/widgets/shared_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// YENİ: Gelir ve Giderleri bir arada tutmak için bir yardımcı sınıf.
class CombinedTransaction {
  final DateTime date;
  final dynamic item; // Income veya Expense olabilir

  CombinedTransaction({required this.date, required this.item});
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Tarih aralığını burada, yani üst widget'ta tanımlıyoruz
  late DateTime _filterStartDate;
  late DateTime _filterEndDate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      // Controller'ın varsayılan değeri artık 0.5 (Compare) olabilir
      // veya 0.0 (Income) olarak kalabilir.
      // value: 0.5,
    );

    // Tarih aralığını ayarla ve veriyi çek
    _updateDateFilter();
    _fetchData();
  }

  void _updateDateFilter() {
    _filterEndDate = DateTime.now();
    _filterStartDate = _filterEndDate.subtract(const Duration(days: 30));
  }

  // Veri çekme işlemini artık WalletPage yapıyor
  void _fetchData() {
    context.read<DataBloc>().add(
          GetCompareEvent(
            filterStart: _filterStartDate,
            filterEnd: _filterEndDate,
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
        appBar: SharedAppbar(),
        drawer: Drawer(
          elevation: 1,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'Menü',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
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
                    backgroundColor: Colors.red),
              );
            } else if (state is SuccessfullyCreatedItemState ||
                state is SuccessfullyDeletedItemState ||
                state is SuccessfullyUpdatedItemState) {
              _fetchData();
            }
          },
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
                centerWidget = const Center(child: CircularProgressIndicator());
              } else if (state is ErrorState) {
                centerWidget = Center(
                    child: Text("Veriler yüklenemedi: ${state.err}",
                        style: const TextStyle(color: Colors.red)));
              } else if (state is NoDataState) {
                // Veri yok
              } else if (state is SuccessfullyGetCompareState) {
                incomeData = state.income;
                expenseData = state.expense;
              }

              if (centerWidget != null) {
                return centerWidget;
              }

              // DEĞİŞİKLİK: 'compareView' artık yer tutucu SummaryView() değil,
              // oluşturduğumuz yeni CompareView widget'ını kullanıyor.
              final compareView = CompareView(
                incomeData: incomeData,
                expenseData: expenseData,
              );

              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: CubeAnimationView(
                        controller: _controller,
                        firstView: ExpenseView(expenseData: expenseData),
                        secondView: IncomeView(incomeData: incomeData),
                        // Verileri alan yeni widget'ı buraya ekliyoruz
                        thirdView: compareView,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SliderButtonExpenseIncome(controller: _controller),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
