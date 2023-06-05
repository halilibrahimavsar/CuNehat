import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/cloud_const.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/add_data_views/tag_editing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:intl/intl.dart';
import 'package:textfield_tags/textfield_tags.dart';

class UpdateDataScreen extends StatefulWidget {
  final int selectedOption;
  final String id;
  final String note;
  final double price;
  final String tag;
  final Timestamp? date;
  final String time;

  const UpdateDataScreen({
    super.key,
    required this.selectedOption,
    required this.id,
    required this.note,
    required this.price,
    required this.tag,
    required this.date,
    required this.time,
  });

  @override
  State<UpdateDataScreen> createState() => _UpdateDataScreenState();
}

class _UpdateDataScreenState extends State<UpdateDataScreen> {
  late final TextEditingController _noteController;
  late final TextEditingController _priceController;
  late final TextfieldTagsController _tagController;
  late Timestamp date;
  late String _btnDate;
  late String _btnTime;

  @override
  void initState() {
    date = Timestamp.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch);
    _noteController = TextEditingController();
    _priceController = TextEditingController();
    _tagController = TextfieldTagsController();
    _btnDate = DateFormat('dd-MM-yyyy', 'tr').format(DateTime.now());
    _btnTime = DateFormat.Hm('tr').format(DateTime.now());
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
    _noteController.text = widget.note;
    _priceController.text = widget.price.toString();
    // _tagController.clearTags();
    // _tagController.addTag = widget.tag;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text("Güncelle"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MaterialButton(
                      color: Colors.purple,
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
                              _btnDate =
                                  DateFormat('dd-MM-yyyy', 'tr').format(time);
                            });
                          },
                          minTime: DateTime(1997, 5, 19),
                          maxTime: DateTime(2050, 0, 0),
                          currentTime: DateTime.now(),
                          locale: LocaleType.tr,
                        );
                      },
                      child: Text(
                        _btnDate,
                        style: const TextStyle(fontSize: 25),
                      ),
                    ),
                    MaterialButton(
                      color: Colors.purple,
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
                              date = Timestamp.fromMillisecondsSinceEpoch(
                                  time.millisecondsSinceEpoch);
                              _btnDate = DateFormat('dd-MM-yyyy', 'tr').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      date.millisecondsSinceEpoch));
                            });
                          },
                          currentTime: DateTime.now(),
                          locale: LocaleType.tr,
                        );
                      },
                      child: Text(
                        _btnTime,
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
                      color: Colors.blueAccent.shade200,
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
        backgroundColor: Colors.purple,
        label: const Text("GÜNCELLE"),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 100),
        onPressed: () {
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
                    color: Colors.purple,
                    child: const Text("VAZGEÇ")),
                MaterialButton(
                    onPressed: () async {
                      final tag = _tagController.getTags!.isNotEmpty
                          ? _tagController.getTags!.first
                          : "tag";

                      if (widget.selectedOption == 2) {
                        await FirestoreService().updateExpense(
                          id: widget.id,
                          data: {
                            fieldAmount: double.parse(_priceController.text),
                            fieldTitle: _noteController.text,
                            fieldTag: tag,
                            fieldDate: Timestamp.fromMillisecondsSinceEpoch(
                                DateTime.parse(_btnDate)
                                    .millisecondsSinceEpoch),
                            fieldTime: Timestamp.fromMillisecondsSinceEpoch(
                                DateTime.parse(_btnTime)
                                    .millisecondsSinceEpoch),
                          },
                        );
                      } else {
                        await FirestoreService().updateIncome(
                          id: widget.id,
                          data: {
                            fieldAmount: double.parse(_priceController.text),
                            fieldTitle: _noteController.text,
                            fieldTag: tag,
                            fieldDate: date,
                            fieldTime: _btnTime,
                          },
                        );
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    color: Colors.purple,
                    child: const Text("GÜNCELLE"))
              ],
            ),
          );
        },
      ),
    );
  }
}
