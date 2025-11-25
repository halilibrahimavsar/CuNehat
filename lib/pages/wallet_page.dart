import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/data_bloc/data_bloc.dart';
import 'package:cunehat/repository/data_bloc/data_event.dart';
import 'package:cunehat/repository/data_bloc/data_state.dart';
import 'package:cunehat/pages/expense_pages/expense_page.dart';
import 'package:cunehat/pages/income_pages/income_page.dart';
import 'package:cunehat/pages/summary_pages/compare_view.dart';
import 'package:cunehat/shared/animations/cube_animation_view.dart';
import 'package:cunehat/shared/animations/slider_button_view.dart';
import 'package:cunehat/shared/widgets/finance_entry_widget.dart';
import 'package:cunehat/shared/widgets/build_drawer.dart';
import 'package:cunehat/shared/widgets/date_rang_pck.dart';
import 'package:cunehat/shared/widgets/shared_appbar.dart';
import 'package:cunehat/utilities/date_range_helper.dart';
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

  DateTime _startDate =
      DateRangeHelper.getMonthRange(DateTime.now())['firstDate']!;
  DateTime _endDate =
      DateRangeHelper.getMonthRange(DateTime.now())['lastDate']!;
  double _currentSliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _fetchData();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      value:
          0.5, // (0=expense, 0.5=compare 1=income). We wanna show compareview on startup
    )..addListener(() {
        setState(() {
          _currentSliderValue = _controller.value;
        });
      });
  }

  void _fetchData() {
    context.read<DataBloc>().add(
          GetCompareEvent(filterStart: _startDate, filterEnd: _endDate),
        );
  }

  Future<void> _showDateRangePicker() async {
    final result = await showDateRangePickerDialog(
      context: context,
      initialStartDate: _startDate,
      initialEndDate: _endDate,
    );

    if (result != null && mounted) {
      setState(() {
        _startDate = result['firstDate']!;
        _endDate = result['lastDate']!;
      });
      _fetchData(); // Yeni tarih aralığıyla verileri yeniden yükle
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: SharedAppbar(
          currentSliderValue: _currentSliderValue,
          onDateRangePressed: _showDateRangePicker, // Yeni callback
        ),
        drawer: const SharedDrawer(),
        body: BlocListener<DataBloc, DataState>(
          listener: (context, state) => _routeStateEvents(context, state),
          child: Column(
            children: [
              // Tarih Aralığı Göstergesi
              _buildDateRangeIndicator(),

              // Ana İçerik
              Expanded(
                child: BlocBuilder<DataBloc, DataState>(
                  buildWhen: (prev, curr) =>
                      curr is LoadingDataState ||
                      curr is SuccessfullyGetCompareState ||
                      curr is NoDataState ||
                      curr is ErrorState ||
                      curr is SuccessfullyCreatedItemState ||
                      curr is SuccessfullyDeletedItemState ||
                      curr is SuccessfullyUpdatedItemState,
                  builder: (context, state) {
                    switch (state) {
                      case LoadingDataState():
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      case SuccessfullyGetCompareState():
                        return CubeAnimationView(
                          controller: _controller,
                          firstView: ExpenseView(expenseData: state.expense),
                          secondView: IncomeView(incomeData: state.income),
                          thirdView: CompareView(
                            incomeData: state.income,
                            expenseData: state.expense,
                          ),
                        );
                      case NoDataState():
                        return _buildNoDataView();
                      case ErrorState():
                        return _buildErrorView(state.err);
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SliderButtonEnhanced(
                  controller: _controller,
                  onTap: (value) {
                    switch (value) {
                      case SliderState.compare:
                        context.read<DataBloc>().add(GetCompareEvent(
                            filterStart: _startDate, filterEnd: _endDate));
                        break;
                      case SliderState.expense:
                        showModalBottomSheet(
                          isScrollControlled: true,
                          enableDrag: true,
                          backgroundColor: Colors.transparent, // Eklendi
                          context: context,
                          builder: (sheetContext) {
                            return FinanceEntryWidget(
                              isExpense: true,
                              onSave: (item) {
                                context
                                    .read<DataBloc>()
                                    .add(AddExpenseEvent(expense: item));
                              },
                              onCancel: () => Navigator.pop(sheetContext),
                            );
                          },
                        );
                        break;
                      case SliderState.income:
                        showModalBottomSheet(
                          isScrollControlled: true,
                          enableDrag: true,
                          backgroundColor: Colors.transparent, // Eklendi
                          context: context,
                          builder: (sheetContext) {
                            return FinanceEntryWidget(
                              isExpense: false,
                              onSave: (item) {
                                context
                                    .read<DataBloc>()
                                    .add(AddIncomeEvent(income: item));
                              },
                              onCancel: () => Navigator.pop(sheetContext),
                            );
                          },
                        );
                        break;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STATE EVENT ROUTER  (Tüm Snackbar / Error / Sync olayları)
  // -------------------------------------------------------------

  Widget _buildDateRangeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tarih Aralığı:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: _showDateRangePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Text(
                    '${AppFormatters.dateShort.format(_startDate)} - ${AppFormatters.dateShort.format(_endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _routeStateEvents(BuildContext context, DataState state) {
    switch (state) {
      // CRUD -----------------------------------------------------------------
      case SuccessfullyCreatedItemState():
        _snackbar("✓ Başarıyla eklendi", Colors.green);
        break;
      case SuccessfullyDeletedItemState():
        _snackbar("✓ Başarıyla silindi", Colors.green);
        break;
      case SuccessfullyUpdatedItemState():
        _snackbar("✓ Başarıyla güncellendi", Colors.green);
        break;
      // SYNC ----------------------------------------------------------------

      case SyncingDataState():
        _snackbar("Senkronizasyon yapılıyor...", Colors.blueGrey,
            loading: true);
      case SyncSuccessState():
        _snackbar("✓ Senkronizasyon tamamlandı", Colors.green);
        break;

      case SyncFailedState():
        _snackbar("✗ Senkronizasyon başarısız", Colors.orange);
        break;

      // ERROR ----------------------------------------------------------------
      case ErrorState():
        _snackbar(state.err, Colors.red);
        break;

      default:
    }
  }

  void _snackbar(String text, Color color, {bool loading = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            if (loading)
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            if (loading) const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // EMPTY & ERROR UI
  // -------------------------------------------------------------

  Widget _buildErrorView(String err) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 58, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text("Veriler yüklenemedi",
              style: TextStyle(color: Colors.red.shade700)),
          const SizedBox(height: 4),
          Text(err,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            label: const Text("Tekrar Dene"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("Henüz veri yok", style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text("Gelir veya gider ekleyerek başlayın",
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
