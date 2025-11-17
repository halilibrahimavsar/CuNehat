import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/data_bloc/data_bloc.dart';
import 'package:cunehat/repository/data_bloc/data_event.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          context
                              .read<DataBloc>()
                              .add(DeleteIncomeEvent(id: income.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${income.title} silindi.")),
                          );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddIncomeSheet(context),
        tooltip: 'Gelir Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddIncomeSheet(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _AddIncomeForm(parentContext: parentContext);
      },
    );
  }
}

// AYRI BİR STATEFUL WIDGET OLARAK FORM
class _AddIncomeForm extends StatefulWidget {
  final BuildContext parentContext;

  const _AddIncomeForm({required this.parentContext});

  @override
  State<_AddIncomeForm> createState() => _AddIncomeFormState();
}

class _AddIncomeFormState extends State<_AddIncomeForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _tagController;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Yeni Gelir Ekle",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Başlık"),
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: "Miktar (₺)"),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _tagController,
            decoration: const InputDecoration(labelText: "Etiket"),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppFormatters.dateShort.format(_selectedDate)),
              TextButton(
                child: const Text("Tarih Seç"),
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && mounted) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_selectedTime.format(context)),
              TextButton(
                child: const Text("Saat Seç"),
                onPressed: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (pickedTime != null && mounted) {
                    setState(() {
                      _selectedTime = pickedTime;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            child: const Text("Kaydet"),
            onPressed: () {
              final title = _titleController.text;
              final amount = double.tryParse(_amountController.text) ?? 0.0;
              final tag = _tagController.text;
              final userId =
                  FirebaseAuth.instance.currentUser?.uid ?? 'local_user';

              if (title.isNotEmpty && amount > 0) {
                final combinedDateTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                );

                final newIncome = Income.createLocal(
                  userId: userId,
                  title: title,
                  tag: tag.isEmpty ? 'Diğer' : tag,
                  amount: amount,
                  date: combinedDateTime,
                  time: AppFormatters.time.format(combinedDateTime),
                );

                widget.parentContext
                    .read<DataBloc>()
                    .add(AddIncomeEvent(income: newIncome));
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
