import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/add_data_views/tag_editing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:textfield_tags/textfield_tags.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;
  late final TextEditingController _priceController;
  late final TextfieldTagsController _tagController;
  late String btnDate;
  late String btnTime;

  @override
  void initState() {
    _noteController = TextEditingController();
    _priceController = TextEditingController();
    _tagController = TextfieldTagsController();
    btnDate = DateFormat('dd/MM/yyyy', 'tr').format(DateTime.now());
    btnTime = DateFormat.Hm('tr').format(DateTime.now());
    super.initState();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text("Gelir"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MaterialButton(
                      color: Colors.redAccent,
                      elevation: 20,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onPressed: () {
                        DatePickerBdaya.showDatePicker(
                          context,
                          onConfirm: (time) {
                            setState(() {
                              btnDate =
                                  DateFormat('dd/MM/yyyy', 'tr').format(time);
                            });
                          },
                          minTime: DateTime(1997, 5, 19),
                          maxTime: DateTime(2050, 0, 0),
                          currentTime: DateTime.now(),
                          locale: LocaleType.tr,
                        );
                      },
                      child: Text(
                        btnDate,
                        style: const TextStyle(fontSize: 25),
                      ),
                    ),
                    MaterialButton(
                      color: Colors.redAccent,
                      elevation: 20,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onPressed: () {
                        DatePickerBdaya.showTime12hPicker(
                          context,
                          onConfirm: (time) {
                            setState(() {
                              btnTime = DateFormat.Hm('tr').format(time);
                            });
                          },
                          currentTime: DateTime.now(),
                          locale: LocaleType.tr,
                        );
                      },
                      child: Text(
                        btnTime,
                        style: const TextStyle(fontSize: 25),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                TextFormField(
                  controller: _priceController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    icon: const Icon(Icons.monetization_on_outlined, size: 40),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                        onPressed: () => _priceController.clear(),
                        icon: const Icon(Icons.clear)),
                    labelText: "FİYAT",
                    hintText: "Nekadar harcama yaptın?",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.toString().isEmpty) {
                      return "bu alan boş olamaz!";
                    } else {
                      return null;
                    }
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^(\d+)?\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffix: IconButton(
                        onPressed: () => _noteController.clear(),
                        icon: const Icon(Icons.clear)),
                    labelText: "AÇIKLAMA",
                    hintText: "Ne için harcama yaptın?",
                  ),
                  validator: (value) {
                    if (value != null && value.toString().isEmpty) {
                      return "Bu alan boş olamaz";
                    } else {
                      return null;
                    }
                  },
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: TagEditing(tagController: _tagController)),
                    MaterialButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      color: Colors.red.shade100,
                      onPressed: () {
                        _tagController.clearTags();
                      },
                      child: const Text('CLEAR TAG'),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 100,
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        label: const Text("KAYDET"),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 100),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Kaydet"),
                content: Text(
                    "Fiyat : ${_priceController.text}\nAçıklama : ${_noteController.text} \n\nKAYIT EDİLSİN Mİ? "),
                actions: [
                  MaterialButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      color: Colors.red,
                      child: const Text("VAZGEÇ")),
                  MaterialButton(
                      onPressed: () async {
                        final tag = _tagController.getTags!.isNotEmpty
                            ? _tagController.getTags!.first
                            : "tag";
                        FirestoreService().addExpense(expense: {
                          "price": double.parse(_priceController.text),
                          "note": _noteController.text,
                          "tag": tag,
                          "date": btnDate,
                          "time": btnTime,
                        });
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      color: Colors.green,
                      child: const Text("KAYDET"))
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
