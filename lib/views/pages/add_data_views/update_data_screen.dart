// ignore_for_file: must_be_immutable

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/constants/selected_option.dart';
import 'package:cunehat/firestore/cloud_const.dart';
import 'package:cunehat/firestore/firestore_service.dart';
import 'package:cunehat/views/view_utilities/custom_snackbar.dart';
import 'package:cunehat/views/view_utilities/customizable_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class UpdateDataScreen extends StatefulWidget {
  final SelectedOption selectedOption;
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
  final TextEditingController tagEditingController = TextEditingController();
  final tagValidator = GlobalKey<FormState>();

  late final TextEditingController _noteController;
  late final TextEditingController _priceController;

  late Timestamp date;
  late String _btnDate;
  late String _btnTime;

  @override
  void initState() {
    date = Timestamp.fromDate(DateTime.now());
    _noteController = TextEditingController();
    _priceController = TextEditingController();
    _noteController.text = widget.note;
    _priceController.text = widget.price.toString();

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
        screenSize.width * 0.6; // 60% of screen width

    String tag = widget.tag;
    List<String> tagList = widget.tagList;

    return KeyboardDismisser(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          title: const Text("Güncelle"),
        ),
        backgroundColor: const Color.fromARGB(255, 25, 24, 24),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 42, 41, 41),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        NeumorphicButton(
                          style: NeumorphicStyle(
                            color: const Color.fromARGB(255, 42, 41, 41),
                            boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(20),
                            ),
                            shape: NeumorphicShape.convex,
                            shadowLightColor: Colors.grey.shade500,
                            shadowDarkColor: Colors.black,
                            depth: 2,
                            intensity: 200,
                          ),
                          onPressed: () {
                            DatePickerBdaya.showDatePicker(
                              context,
                              onConfirm: (time) {
                                setState(() {
                                  date = Timestamp.fromDate(time);
                                  _btnDate = DateFormat('dd-MM-yyyy', 'tr')
                                      .format(
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
                            style: const TextStyle(
                              fontSize: 25,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        NeumorphicButton(
                          style: NeumorphicStyle(
                            color: const Color.fromARGB(255, 42, 41, 41),
                            boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(20),
                            ),
                            shape: NeumorphicShape.convex,
                            shadowLightColor: Colors.grey.shade500,
                            shadowDarkColor: Colors.black,
                            depth: 2,
                            intensity: 200,
                          ),
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
                            style: const TextStyle(
                              fontSize: 25,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 42, 41, 41),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextFormField(
                      controller: _priceController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color.fromRGBO(246, 245, 245, 1),
                      ),
                      decoration: InputDecoration(
                        errorStyle: const TextStyle(color: Colors.amber),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.amber,
                          ),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.amber,
                          ),
                        ),
                        labelStyle: const TextStyle(
                          color: Color.fromRGBO(246, 245, 245, 1),
                        ),
                        hintStyle: const TextStyle(
                          color: Color.fromRGBO(207, 207, 207, 0.735),
                        ),
                        suffixIconColor: Colors.purple,
                        prefixIconColor: Colors.purple,
                        iconColor: Colors.purple,
                        icon: const Icon(Icons.monetization_on_outlined,
                            size: 40),
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
                  ),
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 42, 41, 41),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
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
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              choiceCheckmark: true,
                              clipBehavior: Clip.antiAlias,
                              // choiceLoader: loadTag,
                              choiceStyle: const C2ChipStyle(
                                foregroundColor: Colors.white,
                                checkmarkColor: Colors.cyan,
                              ),
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
                                return Container(
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 42, 41, 41),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom,
                                    left: 16,
                                    right: 16,
                                    top: 16,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        Form(
                                          key: tagValidator,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              TextFormField(
                                                controller:
                                                    tagEditingController,
                                                validator: (value) {
                                                  if (value != null &&
                                                      value
                                                          .toString()
                                                          .isEmpty) {
                                                    return "bu alan boş olamaz!";
                                                  } else if (value!
                                                      .contains(' ')) {
                                                    return 'Etikette boşluk bırakılamaz';
                                                  } else {
                                                    return null;
                                                  }
                                                },
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Color.fromRGBO(
                                                      246, 245, 245, 1),
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelStyle: TextStyle(
                                                    color: Color.fromRGBO(
                                                        246, 245, 245, 1),
                                                  ),
                                                  hintStyle: TextStyle(
                                                    color: Color.fromRGBO(
                                                        207, 207, 207, 0.735),
                                                  ),
                                                  label: Text('Tag'),
                                                  hintText:
                                                      'Etiket için birşeyler yazın',
                                                ),
                                              ),
                                              MaterialButton(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                color:
                                                    Colors.blueAccent.shade200,
                                                onPressed: () {
                                                  if (tagValidator.currentState!
                                                      .validate()) {
                                                    tagList.add(
                                                        tagEditingController
                                                            .text);
                                                    setState(() {});
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                child: const Text('EKLE'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 30),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 42, 41, 41),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextFormField(
                      controller: _noteController,
                      style: const TextStyle(
                        color: Color.fromRGBO(246, 245, 245, 1),
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        suffix: IconButton(
                          onPressed: () => _noteController.clear(),
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.purple,
                          ),
                        ),
                        labelStyle: const TextStyle(
                          color: Color.fromRGBO(246, 245, 245, 1),
                        ),
                        hintStyle: const TextStyle(
                          color: Color.fromRGBO(207, 207, 207, 0.735),
                        ),
                        labelText: "AÇIKLAMA",
                        hintText: "Ne için harcama yaptın?",
                      ),
                    ),
                  ),
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
                if (widget.selectedOption == SelectedOption.expense) {
                  await FirestoreService().updateExpense(
                    id: widget.id,
                    data: {
                      fieldAmount: double.parse(_priceController.text),
                      fieldTitle: _noteController.text,
                      fieldTag: tag,
                      fieldDate: Timestamp.fromDate(
                          DateFormat('dd-MM-yyyy').parse(_btnDate)),
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
                      fieldDate: Timestamp.fromDate(
                          DateFormat('dd-MM-yyyy').parse(_btnDate)),
                      fieldTime: _btnTime,
                    },
                  );
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            );

            if (context.mounted) {
              if (isUpdate) {
                showSnackbar(
                  context: context,
                  title: "Success",
                  msg: "Data Updated in database",
                  type: ContentType.success,
                );
              } else {
                showSnackbar(
                  context: context,
                  title: "Warning",
                  msg: "Data not updated, user not want to :(",
                  type: ContentType.warning,
                );
              }
            }
          },
        ),
      ),
    );
  }
}
