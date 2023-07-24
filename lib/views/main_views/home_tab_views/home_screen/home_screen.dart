import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/add_data_views/add_data_screen.dart';
import 'package:cunehat/views/main_views/home_tab_views/home_screen/data_showing/custom_listview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

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
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
                shape: NeumorphicShape.concave,
                oppositeShadowLightSource: selectedOption == 1,
              ),
              child: Text(
                "Gelir",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: selectedOption == 1 ? Colors.green : Colors.black,
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
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
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
        StreamBuilder(
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
              return CustomListview(
                trnsformAllData: trnsformAllData,
                selectedOption: selectedOption,
              );
            } else if (snapshot.hasError) {
              // Handle error case
              return const Center(child: Text('There is no data'));
            } else {
              // Show loading indicator
              return const Center(child: CircularProgressIndicator());
            }
          },
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
  }
}
