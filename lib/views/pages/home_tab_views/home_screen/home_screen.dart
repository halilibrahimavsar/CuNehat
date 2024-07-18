import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/firestore/firestore_service.dart';
import 'package:cunehat/views/pages/add_data_views/add_data_screen.dart';
import 'package:cunehat/views/pages/home_tab_views/home_screen/data_showing/stream_of_expense_income.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:toggle_switch/toggle_switch.dart';

class HomeScreen extends StatefulWidget {
  final Timestamp firstDate;
  final Timestamp lastDate;

  const HomeScreen({
    super.key,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedOption = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ToggleSwitch(
          customWidths: const [150, 150],
          animate: true,
          animationDuration: 500,
          initialLabelIndex: selectedOption - 1,
          totalSwitches: 2,
          labels: const ['GELİR', 'GİDER'],
          activeBgColor: [selectedOption == 1 ? Colors.green : Colors.red],
          inactiveBgColor: Colors.transparent,
          inactiveFgColor: Colors.white60,
          onToggle: (index) {
            setState(() {
              selectedOption = (index! + 1);
            });
          },
        ),
        [
          StreamOfExpOrInc(
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            selectedOption: selectedOption,
            stream: FirestoreService().getIncomeByMonthAndYear(
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              ownerUserId: FirebaseAuth.instance.currentUser?.uid,
            ),
          ),
          StreamOfExpOrInc(
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            selectedOption: selectedOption,
            stream: FirestoreService().getExpensesByMonthAndYear(
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              ownerUserId: FirebaseAuth.instance.currentUser?.uid,
            ),
          ),
        ][selectedOption - 1],
        [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(
                    horizontal: 60,
                  ),
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(
                      color: Colors.green,
                      style: BorderStyle.solid,
                      strokeAlign: 10,
                    ),
                  ),
                ),
                foregroundColor: MaterialStateProperty.all(Colors.green),
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: const Icon(Icons.add),
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
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(
                    horizontal: 60,
                  ),
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(
                        color: Colors.red,
                        style: BorderStyle.solid,
                        strokeAlign: 10),
                  ),
                ),
                foregroundColor: MaterialStateProperty.all(Colors.red),
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: const Icon(Icons.add),
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
          ),
        ][selectedOption - 1]
      ],
    );
  }
}
