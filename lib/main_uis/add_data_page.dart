import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddDataPage extends StatefulWidget {
  const AddDataPage({super.key});

  @override
  State<AddDataPage> createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  final _explainationController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  String _selectedDate =
      "${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}";

  void _showDatePicker() {
    showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1997),
            lastDate: DateTime(2100))
        .then((value) {
      setState(() {
        _selectedDate = "${value!.year}/${value.month}/${value.day}";
      });
    });
  }

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
                ElevatedButton(
                  onPressed: () => _showDatePicker(),
                  child: Text(_selectedDate),
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
        label: Text("KAYDET"),
        extendedPadding: EdgeInsets.symmetric(horizontal: 100),
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
