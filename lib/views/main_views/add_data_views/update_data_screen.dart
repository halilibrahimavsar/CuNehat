// ignore_for_file: must_be_immutable

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/cloud_const.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/add_data_views/tag_editing.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
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
  String tag;
  final List<String> tagList;
  final Timestamp? date;
  final String time;

  UpdateDataScreen({
    super.key,
    required this.selectedOption,
    required this.id,
    required this.note,
    required this.price,
    required this.tag,
    required this.tagList,
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
    _noteController.text = widget.note;
    _priceController.text = widget.price.toString();
    _tagController = TextfieldTagsController();
    _btnDate = DateFormat('dd-MM-yyyy', 'tr').format(widget.date!.toDate());
    _btnTime = widget.time;
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
    final Size screenSize = MediaQuery.of(context).size;

    final double desiredTagWidth =
        screenSize.width * 0.8; // 80% of screen width

    String tag = widget.tag;
    List<String> tagList = widget.tagList;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: desiredTagWidth,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ChipsChoice<String>.single(
                          value: tag,
                          leading: const Text(
                            "TAGS :",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          choiceCheckmark: true,
                          clipBehavior: Clip.antiAlias,
                          // choiceLoader: loadTag,
                          onChanged: (val) => setState(() {
                            widget.tag = val;
                          }),
                          choiceItems: C2Choice.listFrom<String, String>(
                            source: tagList,
                            value: (i, v) => v,
                            label: (i, v) => v,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        showModalBottomSheet(
                          context: context,
                          enableDrag: true,
                          useSafeArea: true,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(25))),
                          builder: (context) {
                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const SizedBox(height: 30),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                        child: TagEditing(
                                      tagController: _tagController,
                                    )),
                                    MaterialButton(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      color: Colors.blueAccent.shade200,
                                      onPressed: () {
                                        List<String> editedTags =
                                            _tagController.getTags!.toList();
                                        for (final String i in editedTags) {
                                          if (!tagList.contains(i)) {
                                            tagList.add(i);
                                          }
                                        }
                                        setState(() {});
                                        Navigator.pop(context);
                                      },
                                      child: const Text('EKLE'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  'Buradan eklenen taglar geçici süreliğine gösterilecektir',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
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
        onPressed: () async {
          bool isUpdate = await showCustmDialog(
            context,
            title: "Güncelle",
            msg: '''
Fiyat    : ${_priceController.text}
Tag      : $tag
Açıklama : ${_noteController.text}
Tarih    : $_btnDate - $_btnTime''',
            cancelButton: "VAZGEÇ",
            confirmButton: "GÜNCELLE",
            color: Colors.purple,
            functionWhenConfirm: () async {
              if (widget.selectedOption == 2) {
                await FirestoreService().updateExpense(
                  id: widget.id,
                  data: {
                    fieldAmount: double.parse(_priceController.text),
                    fieldTitle: _noteController.text,
                    fieldTag: tag,
                    fieldDate: Timestamp.fromMillisecondsSinceEpoch(
                        DateFormat('dd-MM-yyyy')
                            .parse(_btnDate)
                            .millisecondsSinceEpoch),
                    fieldTime: _btnTime,
                  },
                );
              } else {
                await FirestoreService().updateIncome(
                  id: widget.id,
                  data: {
                    fieldAmount: double.parse(_priceController.text),
                    fieldTitle: _noteController.text,
                    fieldTag: tag,
                    fieldDate: Timestamp.fromMillisecondsSinceEpoch(
                        DateFormat('dd-MM-yyyy')
                            .parse(_btnDate)
                            .millisecondsSinceEpoch),
                    fieldTime: _btnTime,
                  },
                );
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          );

          if (isUpdate) {
            showSnackbar(
              title: "Success",
              msg: "Data Updated in database",
              type: ContentType.success,
            );
          } else {
            showSnackbar(
              title: "Warning",
              msg: "Data not updated, user not want to :(",
              type: ContentType.warning,
            );
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
          title: title,
          message: msg,
          contentType: type,
        ),
      ),
    );
  }
}
