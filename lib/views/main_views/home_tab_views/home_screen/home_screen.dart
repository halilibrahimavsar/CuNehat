import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/constants/currency_format.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/add_data_views/add_data_screen.dart';
import 'package:cunehat/views/main_views/add_data_views/update_data_screen.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Timestamp firstDate;
  late Timestamp lastDate;
  int selectedOption = 1;

  @override
  void initState() {
    firstDate = Timestamp.fromMillisecondsSinceEpoch(
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
      ).millisecondsSinceEpoch,
    );
    lastDate = Timestamp.fromMillisecondsSinceEpoch(
        DateTime.now().add(const Duration(hours: 3)).millisecondsSinceEpoch);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: (selectedOption == 2)
          ? FirestoreService().getExpensesByMonthAndYear(
              firstDate: firstDate,
              lastDate: lastDate,
              ownerUserId: FirebaseAuth.instance.currentUser?.uid,
            )
          : FirestoreService().getIncomeByMonthAndYear(
              firstDate: firstDate,
              lastDate: lastDate,
              ownerUserId: FirebaseAuth.instance.currentUser?.uid,
            ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final allData = snapshot.data?.toList().reversed;
          Map<DateTime, List<ModelProvider>> trnsformAllData = {};

          allData!.toList().forEach((e) {
            // key for daily show data
            DateTime keyDaily = DateTime(
              e.date.toDate().year,
              e.date.toDate().month,
              e.date.toDate().day,
              0, // hour
              0, // minute
              0, // second
            );

            //
            // DateTime keyMonthly = DateTime(
            //   e.date.toDate().year,
            //   e.date.toDate().month,
            //   0, // day
            //   0, // hour
            //   0, // minute
            //   0, // second
            // );
            if (trnsformAllData.containsKey(keyDaily)) {
              trnsformAllData[keyDaily]?.add(e);
            } else {
              trnsformAllData[keyDaily] = [e];
            }
          });
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
              Expanded(
                child: ListView.builder(
                  itemCount: trnsformAllData.length,
                  itemBuilder: (context, index) {
                    final header = trnsformAllData.keys.elementAt(index);
                    return ExpansionTile(
                      title: Text(
                        DateFormat.yMMMd('tr').format(header),
                        style: TextStyle(
                          color:
                              selectedOption == 2 ? Colors.red : Colors.green,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat.E('tr').format(header),
                        style: TextStyle(
                          color:
                              selectedOption == 2 ? Colors.red : Colors.green,
                        ),
                      ),
                      leading: Text(
                        '   ${trnsformAllData[header]!.length}\nAdet',
                        style: TextStyle(
                          color:
                              selectedOption == 2 ? Colors.red : Colors.green,
                        ),
                      ),
                      maintainState: true,
                      children: List.generate(
                        trnsformAllData[header]!.length,
                        (indx) {
                          final data = trnsformAllData[header]?[indx];

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
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      context: context,
                                      builder: (context) {
                                        return UpdateDataScreen(
                                          selectedOption: selectedOption,
                                          id: data!.id,
                                          note: data.title,
                                          price: data.amount,
                                          tag: data.tag,
                                          tagList:
                                              data.tag.split(",.,.,.,.,.,"),
                                          date: data.date,
                                          time: data.time,
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
                                        msg:
                                            "Data not Removed, user not want to :(",
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
                            child: ShowListWidget(
                              selectedOption: selectedOption,
                              data: trnsformAllData[header]?[indx],
                            ),
                          );
                        },
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
                  style: const NeumorphicStyle(color: Colors.green),
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
                  child: const Icon(Icons.add),
                ),
                NeumorphicButton(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 100,
                  ),
                  style: const NeumorphicStyle(color: Colors.red),
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
                  child: const Icon(Icons.add),
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
          title: title,
          message: msg,
          contentType: type,
        ),
      ),
    );
  }
}

class ShowListWidget extends StatelessWidget {
  const ShowListWidget({
    Key? key,
    required this.selectedOption,
    required this.data,
  }) : super(key: key);

  final int selectedOption;
  final ModelProvider? data;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        tileColor: Colors.grey.shade200,
        title: Text(data!.title),
        trailing: Text(formatCurrency.format(data!.amount)),
        leading: Text(data!.time),
        subtitle: Text(data!.tag),
        titleAlignment: ListTileTitleAlignment.center,
      ),
    );
  }
}
