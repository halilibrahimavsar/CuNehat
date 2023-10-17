import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/cloud_const.dart';
import 'package:cunehat/views/main_views/add_data_views/tag_editing.dart';
import 'package:cunehat/views/utilities/custom_snackbar.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:textfield_tags/textfield_tags.dart';

class AddDataScreen extends StatefulWidget {
  final Color colorOfClass;
  final String titleOfClass;
  final Function provider;
  final Function tagProvider;

  const AddDataScreen({
    super.key,
    required this.colorOfClass,
    required this.titleOfClass,
    required this.provider,
    required this.tagProvider,
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
  String _tag = "";
  List<String> tagList = [];

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
    final Size screenSize = MediaQuery.of(context).size;

    final double desiredTagWidth =
        screenSize.width * 0.8; // 80% of screen width
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.titleOfClass),
        backgroundColor: widget.colorOfClass,
      ),
      backgroundColor: Colors.grey.shade300,
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  NeumorphicButton(
                    onPressed: () {
                      DatePickerBdaya.showDatePicker(
                        context,
                        onConfirm: (time) {
                          setState(() {
                            date = Timestamp.fromDate(time);
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
                      style: TextStyle(
                        color: widget.colorOfClass,
                        fontSize: 25,
                      ),
                    ),
                  ),
                  NeumorphicButton(
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
                      style: TextStyle(
                        color: widget.colorOfClass,
                        fontSize: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _priceController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixIconColor: widget.colorOfClass,
                prefixIconColor: widget.colorOfClass,
                icon: const Icon(Icons.monetization_on_outlined),
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
                FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: desiredTagWidth,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ChipsChoice<String>.single(
                      value: _tag,
                      leading: Text(
                        "TAGS :",
                        style: TextStyle(
                          color: widget.colorOfClass,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      choiceCheckmark: true,
                      clipBehavior: Clip.antiAlias,
                      choiceLoader: loadTag,
                      onChanged: (val) => setState(() => _tag = val),
                      choiceItems: C2Choice.listFrom<String, String>(
                        source: tagList,
                        value: (i, v) => v,
                        label: (i, v) => v,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  color: widget.colorOfClass,
                  onPressed: () async {
                    showModalBottomSheet(
                      context: context,
                      enableDrag: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      builder: (context) {
                        return Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const SizedBox(height: 30),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
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
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                iconColor: widget.colorOfClass,
                border: const OutlineInputBorder(),
                suffix: IconButton(
                    onPressed: () => _noteController.clear(),
                    icon: Icon(
                      Icons.clear,
                      color: widget.colorOfClass,
                    )),
                labelText: "AÇIKLAMA",
                hintText: "Kayıt için not gir",
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: NeumorphicButton(
                child: Text(
                  "KAYDET",
                  style: TextStyle(color: widget.colorOfClass, fontSize: 30),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    bool isSave = await showCustmDialog(
                      context,
                      title: "Kaydet",
                      msg: '''
Fiyat    : ${_priceController.text}
Tag      : $_tag
Açıklama : ${_noteController.text}
Tarih    : $_btnDate - $_btnTime''',
                      cancelButton: "VAZGEÇ",
                      confirmButton: "KAYDET",
                      color: Colors.blue,
                      functionWhenConfirm: () {
                        widget.provider(
                          data: {
                            fieldUserId: FirebaseAuth.instance.currentUser?.uid,
                            fieldAmount: double.parse(_priceController.text),
                            fieldTitle: _noteController.text,
                            fieldTag: _tag,
                            fieldDate: date,
                            fieldTime: _btnTime,
                          },
                        );
                      },
                    );

                    if (isSave) {
                      if (context.mounted) {
                        showSnackbar(
                          context: context,
                          title: "Success",
                          msg: "Data Saving to database",
                          type: ContentType.success,
                        );
                        Navigator.of(context).pop();
                      }
                    }
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<List<C2Choice<String>>> loadTag() async {
    final res = await widget.tagProvider(
        ownerUserId: FirebaseAuth.instance.currentUser?.uid);
    return res;
  }

  // showSnackbar({
  //   required String title,
  //   required String msg,
  //   required ContentType type,
  // }) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       behavior: SnackBarBehavior.fixed,
  //       backgroundColor: Colors.transparent,
  //       content: AwesomeSnackbarContent(
  //           title: title, message: msg, contentType: type),
  //     ),
  //   );
  // }
}
