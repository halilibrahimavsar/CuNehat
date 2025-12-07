// import 'package:cunehat/features/compare/presentation/widgets/finance_entry_widget.dart';
// import 'package:flutter/material.dart';

// class FinanceSheetHandler {
//   static void showExpenseSheet(BuildContext context) {
//     showModalBottomSheet(
//       isScrollControlled: true,
//       enableDrag: true,
//       backgroundColor: Colors.transparent,
//       context: context,
//       builder: (sheetContext) {
//         return FinanceEntryWidget(
//           walletId: "activeWalletId",
//           isExpense: true,
//           onSave: (item) {
//             Navigator.pop(sheetContext);
//           },
//           onCancel: () {
//             Navigator.pop(sheetContext);
//           },
//         );
//       },
//     );
//   }

//   static void showIncomeSheet(BuildContext context) {
//     showModalBottomSheet(
//       isScrollControlled: true,
//       enableDrag: true,
//       backgroundColor: Colors.transparent,
//       context: context,
//       builder: (sheetContext) {
//         return FinanceEntryWidget(
//           walletId: "activeWalletId",
//           isExpense: false,
//           onSave: (item) {
//             Navigator.pop(sheetContext);
//           },
//           onCancel: () => Navigator.pop(sheetContext),
//         );
//       },
//     );
//   }
// }
