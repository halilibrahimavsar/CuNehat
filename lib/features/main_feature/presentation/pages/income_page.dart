import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/models/income_model.dart';
import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/features/compare/presentation/widgets/finance_entry_widget.dart';
import 'package:flutter/material.dart';

final List<IncomeModel> listOfIncome = List.generate(
  7,
  (i) {
    return IncomeModel(
        id: i.toString(),
        userId: i.toString(),
        title: i.toString(),
        tag: i.toString(),
        amount: i.ceilToDouble(),
        date: DateTime.now(),
        time: DateTime.now().toString(),
        walletId: i.toString());
  },
);

class IncomeView extends StatefulWidget {
  final Map<DateTime, List<IncomeModel>> incomeData;

  const IncomeView({
    super.key,
    required this.incomeData,
  });

  @override
  State<IncomeView> createState() => _IncomeViewState();
}

class _IncomeViewState extends State<IncomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: listOfIncome.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    AppFormatters.dateLong.format(listOfIncome[index].date),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                ...listOfIncome.map((income) {
                  return Dismissible(
                    key: Key(income.id),
                    // İKİ YÖNLÜ KAYDIRMA
                    direction: DismissDirection.horizontal,
                    // SAĞA KAYDIRMA - DÜZENLEME (mavi)
                    background: Container(
                      color: Colors.blue,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Düzenle',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // SOLA KAYDIRMA - SİLME (kırmızı)
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Sil',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.delete, color: Colors.white),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        // SOLA KAYDIRMA - SİLME ONAYI
                        return await ConfirmDeleteDialog.show(
                          context,
                          title: income.title,
                        );
                      } else {
                        // SAĞA KAYDIRMA - DÜZENLEME
                        _showEditIncomeSheet(context, income);
                        return false; // Dismiss etme, sadece sheet aç
                      }
                    },
                    onDismissed: (direction) {
                      // Sadece silme işlemi dismiss eder
                      if (direction == DismissDirection.endToStart) {}
                    },
                    child: ListTile(
                      title: Text(income.title),
                      subtitle: Text(income.tag),
                      trailing: Text(
                        "+${income.amount.toStringAsFixed(2)} ₺",
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditIncomeSheet(BuildContext parentContext, IncomeModel income) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FinanceEntryWidget(
          isExpense: false,
          initialData: FinanceInitialData(
            id: income.id,
            title: income.title,
            amount: income.amount,
            tag: income.tag,
            date: income.date,
            time: income.time,
            walletId: income.walletId,
          ),
          onSave: (item) {
            Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
        );
      },
    );
  }
}
