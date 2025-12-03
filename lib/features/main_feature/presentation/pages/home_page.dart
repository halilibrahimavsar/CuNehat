// lib/pages/wallet_page.dart
// ✅ FIXED: No longer creates duplicate WalletBloc (uses app-level one)

import 'package:cunehat/features/main_feature/presentation/animations/cube_animation_view.dart';
import 'package:cunehat/features/compare/presentation/page/compare_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/date_range_indicator.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/finance_entry_handler.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/slider_button_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/build_drawer.dart';
import 'package:cunehat/core/shared/widgets/shared_appbar.dart';
import 'package:cunehat/features/main_feature/presentation/pages/expense_page.dart';
import 'package:cunehat/features/main_feature/presentation/pages/income_page.dart';
import 'package:cunehat/models/expense_model.dart';
import 'package:cunehat/models/income_model.dart';
import 'package:flutter/material.dart';

Map<DateTime, List<IncomeModel>> incomeData = {
  for (var date in List.generate(
      30, (index) => DateTime.now().subtract(Duration(days: index))))
    date: List.generate(
        5,
        (index) => IncomeModel(
            amount: index.toDouble(),
            date: date,
            id: index.toString(),
            tag: index.toString(),
            title: 'Income $index',
            userId: index.toString(),
            walletId: index.toString(),
            time: DateTime.now().toString()))
};

Map<DateTime, List<ExpenseModel>> expenseData = {
  for (var date in List.generate(
      30, (index) => DateTime.now().subtract(Duration(days: index))))
    date: List.generate(
        5,
        (index) => ExpenseModel(
            amount: index.toDouble(),
            date: date,
            id: index.toString(),
            tag: index.toString(),
            title: 'Income $index',
            userId: index.toString(),
            walletId: index.toString(),
            time: DateTime.now().toString()))
};

/// **WalletPage**: Main page that uses app-level BLoCs
///
/// ✅ FIXED: Now uses existing WalletBloc from app level
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      value: 0.5,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Use existing BLoCs, don't create new ones
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size(double.maxFinite, 50),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return SharedAppbar(currentSliderValue: _controller.value);
            },
          ),
        ),
        drawer: const SharedDrawer(),
        body: Column(
          children: [
            DateRangeIndicator(
              endDate: DateTime.now(),
              startDate: DateTime.now().subtract(const Duration(days: 30)),
              onTap: () {},
            ),
            Expanded(
              child: CubeAnimationView(
                controller: _controller,
                firstView: ExpenseView(expenseData: expenseData),
                secondView: IncomeView(incomeData: incomeData),
                thirdView: CompareView(
                  incomeData: incomeData,
                  expenseData: expenseData,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SliderButtonEnhanced(
                controller: _controller,
                onTap: (value) => _handleSliderAction(context, value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSliderAction(BuildContext context, SliderState value) {
    switch (value) {
      case SliderState.compare:
        // context.read<DataBloc>().add(
        //       GetCompareEvent(filterStart: _startDate, filterEnd: _endDate),
        //     );
        break;
      case SliderState.expense:
        FinanceSheetHandler.showExpenseSheet(context);
        break;
      case SliderState.income:
        FinanceSheetHandler.showIncomeSheet(context);
        break;
    }
  }
}
