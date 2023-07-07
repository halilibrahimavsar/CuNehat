import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/add_data_views/add_data_screen.dart';
import 'package:cunehat/views/main_views/add_data_views/update_data_screen.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

// TODO : add daily data into one listItem
class HomeScreen extends StatefulWidget {
  final Timestamp firstDate;
  final Timestamp lastDate;
  const HomeScreen({Key? key, required this.firstDate, required this.lastDate})
      : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedOption = 1;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: (selectedOption == 2)
          ? FirestoreService().getExpensesByMonthAndYear(
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              ownerUserId: FirebaseAuth.instance.currentUser?.uid,
            )
          : FirestoreService().getIncomeByMonthAndYear(
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              ownerUserId: FirebaseAuth.instance.currentUser?.uid,
            ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final allData = snapshot.data;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  NeumorphicButton(
                    margin: const EdgeInsets.fromLTRB(2, 10, 2, 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 55,
                      vertical: 8,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedOption = 1;
                      });
                    },
                    style: NeumorphicStyle(
                      color: Colors.grey.shade200,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(20)),
                      shape: NeumorphicShape.concave,
                      oppositeShadowLightSource: selectedOption == 1,
                    ),
                    child: Text(
                      "Gelir",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color:
                            selectedOption == 1 ? Colors.green : Colors.black,
                      ),
                    ),
                  ),
                  NeumorphicButton(
                    margin: const EdgeInsets.fromLTRB(2, 10, 2, 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 55,
                      vertical: 8,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedOption = 2;
                      });
                    },
                    style: NeumorphicStyle(
                      color: Colors.grey.shade200,
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(20)),
                      shape: NeumorphicShape.concave,
                      oppositeShadowLightSource: selectedOption == 2,
                    ),
                    child: Text(
                      "Gider",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: selectedOption == 2 ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.builder(
                  itemCount: allData?.length,
                  itemBuilder: (context, index) {
                    final data = allData?.elementAt(index);
                    return Slidable(
                      startActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              showModalBottomSheet(
                                enableDrag: true,
                                useSafeArea: true,
                                isScrollControlled: true,
                                isDismissible: true,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25)),
                                context: context,
                                builder: (context) {
                                  return UpdateDataScreen(
                                    selectedOption: selectedOption,
                                    id: data?.id ?? "",
                                    note: data?.title ?? "",
                                    price: data?.amount ?? 0,
                                    tag: data?.tag ?? "",
                                    tagList: data?.tag.split(",.,.,.,.,.,") ??
                                        ["no-tag"],
                                    date: data?.date,
                                    time: data?.time ?? "",
                                  );
                                },
                              );
                            },
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            icon: Icons.update,
                            label: 'Update',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) async {
                              bool isDelete = await showCustmDialog(
                                context,
                                title: "Sil",
                                msg:
                                    "Bu veriyi tekrar getiremezsiniz. Silinsin mi?",
                                cancelButton: "VAZGEÇ",
                                confirmButton: "SİL",
                                color: Colors.amber,
                                functionWhenConfirm: () async {
                                  (selectedOption == 2)
                                      ? await FirestoreService()
                                          .deleteExpense(id: data!.id)
                                      : await FirestoreService()
                                          .deleteIncome(id: data!.id);
                                },
                              );

                              if (isDelete) {
                                showSnackbar(
                                  title: "Success",
                                  msg: "Data Removed",
                                  type: ContentType.success,
                                );
                              } else {
                                showSnackbar(
                                  title: "Warning",
                                  msg: "Data not Removed, user not want to :(",
                                  type: ContentType.warning,
                                );
                              }
                            },
                            backgroundColor:
                                const Color.fromARGB(255, 255, 224, 23),
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Neumorphic(
                          style: NeumorphicStyle(
                            color: (selectedOption == 2)
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                          ),
                          child: ListTile(
                            title: NeumorphicText(
                              data!.title,
                              style: NeumorphicStyle(
                                oppositeShadowLightSource: true,
                                color: (selectedOption == 2)
                                    ? Colors.red.shade900
                                    : Colors.green.shade900,
                              ),
                              textStyle: NeumorphicTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: NeumorphicText(
                              data.amount.toString(),
                              style: NeumorphicStyle(
                                oppositeShadowLightSource: true,
                                color: (selectedOption == 2)
                                    ? Colors.red.shade900
                                    : Colors.green.shade900,
                              ),
                              textStyle: NeumorphicTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            leading: NeumorphicText(
                              "${data.date.toDate().toString().split(" ")[0]}\n${data.time}",
                              style: NeumorphicStyle(
                                oppositeShadowLightSource: true,
                                color: (selectedOption == 2)
                                    ? Colors.red.shade900
                                    : Colors.green.shade900,
                              ),
                              textStyle: NeumorphicTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: NeumorphicText(
                              data.tag,
                              style: NeumorphicStyle(
                                oppositeShadowLightSource: true,
                                color: (selectedOption == 2)
                                    ? Colors.red.shade900
                                    : Colors.green.shade900,
                              ),
                              textStyle: NeumorphicTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            titleAlignment: ListTileTitleAlignment.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              [
                NeumorphicButton(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 100,
                  ),
                  child: Icon(Icons.add, color: Colors.green.shade300),
                  onPressed: () {
                    showModalBottomSheet(
                      enableDrag: true,
                      useSafeArea: true,
                      isScrollControlled: true,
                      isDismissible: true,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      context: context,
                      builder: (context) {
                        return AddDataScreen(
                          colorOfClass: Colors.green,
                          titleOfClass: "Gelir",
                          provider: FirestoreService().addIncome,
                          tagProvider: FirestoreService().getIncomeTags,
                        );
                      },
                    );
                  },
                ),
                NeumorphicButton(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 100,
                  ),
                  child: Icon(Icons.add, color: Colors.red.shade300),
                  onPressed: () {
                    showModalBottomSheet(
                      enableDrag: true,
                      useSafeArea: true,
                      isScrollControlled: true,
                      isDismissible: true,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      context: context,
                      builder: (context) {
                        return AddDataScreen(
                          colorOfClass: Colors.red,
                          titleOfClass: "Gider",
                          provider: FirestoreService().addExpense,
                          tagProvider: FirestoreService().getExpenseTags,
                        );
                      },
                    );
                  },
                ),
              ][selectedOption - 1]
            ],
          );
        } else if (snapshot.hasError) {
          // Handle error case
          return const Center(child: Text('There is no data'));
        } else {
          // Show loading indicator
          return const Center(child: CircularProgressIndicator());
        }
      },
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
