import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/cloud_const.dart';
import 'package:cunehat/views/main_views/add_data_views/tag_editing.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:textfield_tags/textfield_tags.dart';

class AddDataScreen extends StatefulWidget {
  final Function provider;
  final Color colorOfClass;
  final String titleOfClass;

  const AddDataScreen({
    super.key,
    required this.colorOfClass,
    required this.titleOfClass,
    required this.provider,
  });

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;
  late final TextEditingController _priceController;
  late final TextfieldTagsController _tagController;
  late Timestamp date;
  late String _btnDate;
  late String _btnTime;

  @override
  void initState() {
    date = Timestamp.fromDate(DateTime.now());
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.colorOfClass,
        title: Text(widget.titleOfClass),
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
                      color: widget.colorOfClass,
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
                              date = Timestamp.fromMillisecondsSinceEpoch(
                                  time.millisecondsSinceEpoch);
                              _btnDate = DateFormat('dd-MM-yyyy', 'tr').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      date.millisecondsSinceEpoch));
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
                      color: widget.colorOfClass,
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
                              _btnTime = DateFormat.Hm('tr').format(time);
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
                    hintText: "Kayıt için not gir",
                  ),
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: TagEditing(
                      tagController: _tagController,
                    )),
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
        backgroundColor: widget.colorOfClass,
        label: const Text("KAYDET"),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 100),
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            bool isSave = await showCustmDialog(
              context,
              title: "Kaydet",
              msg:
                  "Fiyat : ${_priceController.text}\nAçıklama : ${_noteController.text} \n\nKAYIT EDİLSİN Mİ? ",
              cancelButton: "VAZGEÇ",
              confirmButton: "KAYDET",
              color: Colors.blue,
              functionWhenConfirm: () {
                final tag = _tagController.getTags!.isNotEmpty
                    ? _tagController.getTags!.first
                    : "tag";
                widget.provider(data: {
                  fieldUserId: FirebaseAuth.instance.currentUser?.uid,
                  fieldAmount: double.parse(_priceController.text),
                  fieldTitle: _noteController.text,
                  fieldTag: tag,
                  fieldDate: date,
                  fieldTime: _btnTime,
                });
              },
            );

            if (isSave) {
              showSnackbar(
                title: "Success",
                msg: "Data Saving to database",
                type: ContentType.success,
              );
            } else {
              showSnackbar(
                title: "Warning",
                msg: "Data not saved, user not want to :(",
                type: ContentType.warning,
              );
            }
          }
        },
      ),
    );
  }

  showSnackbar({
    required String title,
    required String msg,
    required ContentType type,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.fixed,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
            title: title, message: msg, contentType: type),
      ),
    );
  }
}
