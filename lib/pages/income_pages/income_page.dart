import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_bloc.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class IncomeView extends StatefulWidget {
  // Veriyi artık parametre olarak alıyor
  final Map<DateTime, List<Income>> incomeData;

  const IncomeView({
    super.key,
    required this.incomeData,
  });

  @override
  State<IncomeView> createState() => _IncomeViewState();
}

class _IncomeViewState extends State<IncomeView> {
  // Form controller'ları
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

  // Gelir Ekleme Formu (Değişiklik yok)
  void _showAddIncomeSheet(BuildContext context) {
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
                  const Text("Yeni Gelir Ekle",
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

                        final newIncome = Income.createLocal(
                          userId: userId,
                          title: title,
                          tag: tag.isEmpty ? 'Diğer' : tag,
                          amount: amount,
                          date: combinedDateTime,
                          time: DateFormat.Hm('tr_TR').format(combinedDateTime),
                        );

                        context
                            .read<DataBloc>()
                            .add(AddIncomeEvent(income: newIncome));
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
      body: Builder(
        builder: (context) {
          // Gelen veriyi (widget.incomeData) kullan
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
                        DateFormat.yMMMEd('tr_TR').format(dateKey),
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
}
