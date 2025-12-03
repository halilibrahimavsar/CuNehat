// ignore_for_file: deprecated_member_use

import 'package:cunehat/features/compare/domain/model/combine_model.dart';
import 'package:cunehat/features/compare/presentation/widgets/compare_contents_view.dart';
import 'package:cunehat/models/expense_model.dart';
import 'package:cunehat/models/income_model.dart';
import 'package:flutter/material.dart';

class CompareView extends StatelessWidget {
  final Map<DateTime, List<IncomeModel>> incomeData;
  final Map<DateTime, List<ExpenseModel>> expenseData;

  const CompareView({
    super.key,
    required this.incomeData,
    required this.expenseData,
  });

  List<CombinedTransaction> _createCombinedList() {
    final List<CombinedTransaction> combinedList = [];

    incomeData.values.expand((list) => list).forEach((income) {
      combinedList.add(CombinedTransaction(date: income.date, item: income));
    });

    expenseData.values.expand((list) => list).forEach((expense) {
      combinedList.add(CombinedTransaction(date: expense.date, item: expense));
    });

    combinedList.sort((a, b) => b.date.compareTo(a.date));

    return combinedList;
  }

  @override
  Widget build(BuildContext context) {
    final combinedList = _createCombinedList();
    final isBalanceVisible = ValueNotifier<bool>(true);

    return CompareContent(
      combinedList: combinedList,
      isBalanceVisible: isBalanceVisible,
      walletName: "new",
      walletIcon: Icon(Icons.wallet),
      balance: 8.99,
      initialBalance: 0.0, // Varsayılan başlangıç bakiyesi
    );
  }
}
