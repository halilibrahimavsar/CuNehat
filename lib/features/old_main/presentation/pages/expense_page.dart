// import 'package:cunehat/core/constants/app_constants.dart';
// import 'package:cunehat/models/expense_model.dart';
// import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
// import 'package:cunehat/features/compare/presentation/widgets/finance_entry_widget.dart';
// import 'package:flutter/material.dart';

// //dummy
// final List<ExpenseModel> listOfExpense = List.generate(
//   7,
//   (i) {
//     return ExpenseModel(
//         id: i.toString(),
//         userId: i.toString(),
//         title: i.toString(),
//         tag: i.toString(),
//         amount: i.ceilToDouble(),
//         date: DateTime.now(),
//         time: DateTime.now().toString(),
//         walletId: i.toString());
//   },
// );

// class ExpenseView extends StatefulWidget {
//   final Map<DateTime, List<ExpenseModel>> expenseData;

//   const ExpenseView({
//     super.key,
//     required this.expenseData,
//   });

//   @override
//   State<ExpenseView> createState() => _ExpenseViewState();
// }

// class _ExpenseViewState extends State<ExpenseView> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ListView.builder(
//         itemCount: listOfExpense.length,
//         itemBuilder: (context, index) {
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Text(
//                     AppFormatters.dateLong.format(listOfExpense[index].date),
//                     style: const TextStyle(
//                         fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 const Divider(height: 1),
//                 ...listOfExpense.map((expense) {
//                   return Dismissible(
//                     key: Key(expense.id),
//                     // İKİ YÖNLÜ KAYDIRMA
//                     direction: DismissDirection.horizontal,
//                     // SOLA KAYDIRMA - SİLME (kırmızı)
//                     background: Container(
//                       color: Colors.blue,
//                       alignment: Alignment.centerLeft,
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       child: const Row(
//                         children: [
//                           Icon(Icons.edit, color: Colors.white),
//                           SizedBox(width: 8),
//                           Text('Düzenle',
//                               style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                     // SAĞA KAYDIRMA - DÜZENLEME (mavi)
//                     secondaryBackground: Container(
//                       color: Colors.red,
//                       alignment: Alignment.centerRight,
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       child: const Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           Text('Sil',
//                               style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold)),
//                           SizedBox(width: 8),
//                           Icon(Icons.delete, color: Colors.white),
//                         ],
//                       ),
//                     ),
//                     confirmDismiss: (direction) async {
//                       if (direction == DismissDirection.endToStart) {
//                         // SOLA KAYDIRMA - SİLME ONAYI
//                         return await ConfirmDeleteDialog.show(
//                           context,
//                           title: expense.title,
//                         );
//                       } else {
//                         // SAĞA KAYDIRMA - DÜZENLEME
//                         _showEditExpenseSheet(context, expense);
//                         return false; // Dismiss etme, sadece sheet aç
//                       }
//                     },
//                     onDismissed: (direction) {
//                       // Sadece silme işlemi dismiss eder
//                       if (direction == DismissDirection.endToStart) {}
//                     },
//                     child: ListTile(
//                       title: Text(expense.title),
//                       subtitle: Text(expense.tag),
//                       trailing: Text(
//                         "-${expense.amount.toStringAsFixed(2)} ₺",
//                         style: const TextStyle(
//                             color: Colors.red, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _showEditExpenseSheet(BuildContext parentContext, ExpenseModel expense) {
//     showModalBottomSheet(
//       context: parentContext,
//       isScrollControlled: true,
//       enableDrag: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return FinanceEntryWidget(
//           isExpense: true,
//           initialData: FinanceInitialData(
//             id: expense.id,
//             title: expense.title,
//             amount: expense.amount,
//             tag: expense.tag,
//             date: expense.date,
//             time: expense.time,
//             walletId: expense.walletId,
//           ),
//           onSave: (item) {
//             Navigator.pop(context);
//           },
//           onCancel: () => Navigator.pop(context),
//         );
//       },
//     );
//   }
// }
