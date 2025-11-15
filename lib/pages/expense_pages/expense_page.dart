import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_bloc.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpenseView extends StatefulWidget {
  final Map<DateTime, List<Expense>> expenseData;

  const ExpenseView({
    super.key,
    required this.expenseData,
  });

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          if (widget.expenseData.isEmpty) {
            return const Center(child: Text("Henüz hiç gider eklememişsiniz."));
          }

          final sortedKeys = widget.expenseData.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final dateKey = sortedKeys[index];
              final expensesForDay = widget.expenseData[dateKey]!;

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
                    ...expensesForDay.map((expense) {
                      return Dismissible(
                        key: Key(expense.id),
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
                              .add(DeleteExpenseEvent(id: expense.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("${expense.title} silindi.")),
                          );
                        },
                        child: ListTile(
                          title: Text(expense.title),
                          subtitle: Text(expense.tag),
                          trailing: Text(
                            "-${expense.amount.toStringAsFixed(2)} ₺",
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
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
        onPressed: () => _showAddExpenseSheet(context),
        tooltip: 'Gider Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext parentContext) {
    // Controller'ları modal içinde oluştur
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _AddExpenseForm(parentContext: parentContext);
      },
    );
  }
}

// AYRI BİR STATEFUL WIDGET OLARAK FORM
class _AddExpenseForm extends StatefulWidget {
  final BuildContext parentContext;

  const _AddExpenseForm({required this.parentContext});

  @override
  State<_AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<_AddExpenseForm> {
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
          const Text("Yeni Gider Ekle",
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

                final newExpense = Expense.createLocal(
                  userId: userId,
                  title: title,
                  tag: tag.isEmpty ? 'Diğer' : tag,
                  amount: amount,
                  date: combinedDateTime,
                  time: AppFormatters.time.format(combinedDateTime),
                );

                // Parent context'i kullan
                widget.parentContext
                    .read<DataBloc>()
                    .add(AddExpenseEvent(expense: newExpense));
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
