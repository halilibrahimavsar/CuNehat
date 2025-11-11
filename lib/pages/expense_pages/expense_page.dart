import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_bloc.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ExpenseView extends StatefulWidget {
  // Veriyi artık parametre olarak alıyor
  final Map<DateTime, List<Expense>> expenseData;

  const ExpenseView({
    super.key,
    required this.expenseData,
  });

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  // Form controller'ları hala burada (view'e ait state)
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _tagController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    // Artık initState'te _fetchData() ÇAĞIRMIYORUZ!
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // Gider Ekleme Formu (Değişiklik yok)
  void _showAddExpenseSheet(BuildContext context) {
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _titleController.clear();
    _amountController.clear();
    _tagController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Yeni Gider Ekle",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Başlık"),
                  ),
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: "Miktar (₺)"),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(labelText: "Etiket"),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat.yMd('tr_TR').format(_selectedDate)),
                      TextButton(
                        child: const Text("Tarih Seç"),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setModalState(() {
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
                          if (pickedTime != null) {
                            setModalState(() {
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
                      final amount =
                          double.tryParse(_amountController.text) ?? 0.0;
                      final tag = _tagController.text;
                      final userId = FirebaseAuth.instance.currentUser?.uid ??
                          'local_user';

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
                          time: DateFormat.Hm('tr_TR').format(combinedDateTime),
                        );

                        // BLoC'a event'i gönder.
                        // BlocListener (WalletPage'de) bunu duyacak ve listeyi yenileyecek.
                        context
                            .read<DataBloc>()
                            .add(AddExpenseEvent(expense: newExpense));
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Artık BlocListener veya BlocBuilder'a burada gerek yok.
      // Sadece veriyi göster.
      body: Builder(
        builder: (context) {
          // Gelen veriyi (widget.expenseData) kullan
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
                        DateFormat.yMMMEd('tr_TR').format(dateKey),
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
                          // Silme event'ini BLoC'a gönder
                          context
                              .read<DataBloc>()
                              .add(DeleteExpenseEvent(id: expense.id));
                          // SnackBar'ı hemen göster
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
}
