import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/data_bloc/data_bloc.dart';
import 'package:cunehat/repository/data_bloc/data_event.dart';
import 'package:cunehat/shared/widgets/finance_entry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IncomeView extends StatefulWidget {
  final Map<DateTime, List<Income>> incomeData;

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
      body: Builder(
        builder: (context) {
          if (widget.incomeData.isEmpty) {
            return const Center(child: Text("Henüz hiç gelir eklememişsiniz."));
          }
          final sortedKeys = widget.incomeData.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final dateKey = sortedKeys[index];
              final incomesForDay = widget.incomeData[dateKey]!;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        AppFormatters.dateLong.format(dateKey),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    ...incomesForDay.map((income) {
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
                            return await _showDeleteConfirmDialog(
                                context, income.title);
                          } else {
                            // SAĞA KAYDIRMA - DÜZENLEME
                            _showEditIncomeSheet(context, income);
                            return false; // Dismiss etme, sadece sheet aç
                          }
                        },
                        onDismissed: (direction) {
                          // Sadece silme işlemi dismiss eder
                          if (direction == DismissDirection.endToStart) {
                            context.read<DataBloc>().add(DeleteIncomeEvent(
                                income: income, id: income.id));
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(
                            //       content: Text("${income.title} silindi.")),
                            // );
                          }
                        },
                        child: ListTile(
                          title: Text(income.title),
                          subtitle: Text(income.tag),
                          trailing: Text(
                            "+${income.amount.toStringAsFixed(2)} ₺",
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(
      BuildContext context, String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 48),
            title: const Text('Silme Onayı'),
            content: Text(
              '"$title" adlı geliri silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showEditIncomeSheet(BuildContext parentContext, Income income) {
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
          ),
          onSave: (item) {
            parentContext.read<DataBloc>().add(UpdateIncomeEvent(income: item));
          },
          onCancel: () => Navigator.pop(context),
        );
      },
    );
  }
}
