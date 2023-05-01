import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class AddDataPage extends StatefulWidget {
  const AddDataPage({super.key});

  @override
  State<AddDataPage> createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  final _explainationController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  String btnDateTime = DateFormat('dd/MM/yyyy', 'tr').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ekle"),
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
                const SizedBox(height: 50),
                MaterialButton(
                  color: Colors.cyan,
                  elevation: 20,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onPressed: () {
                    DatePicker.showDatePicker(
                      context,
                      onConfirm: (time) {
                        setState(() {
                          btnDateTime =
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
                    btnDateTime,
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
                const SizedBox(height: 50),
                TextFormField(
                  controller: _priceController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    icon: const Icon(Icons.monetization_on_outlined, size: 50),
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _explainationController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffix: IconButton(
                        onPressed: () => _explainationController.clear(),
                        icon: const Icon(Icons.clear)),
                    labelText: "AÇIKLAMA",
                    hintText: "Ne için harcama yaptın?",
                  ),
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (value != null && value.toString().isEmpty) {
                      return "Bu alan boş olamaz";
                    } else {
                      return null;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("KAYDET"),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 100),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Kaydet"),
                content: Text(
                    "Fiyat : ${_priceController.text}\nAçıklama : ${_explainationController.text} \n\nKAYIT EDİLSİN Mİ? "),
                actions: [
                  MaterialButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      color: Colors.red,
                      child: const Text("VAZGEÇ")),
                  MaterialButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        //TODO: Add database and ask for "do you want to save the date blablablaa",
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
