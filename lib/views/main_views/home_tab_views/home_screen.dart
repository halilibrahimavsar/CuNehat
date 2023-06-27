import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/add_data_views/update_data_screen.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
                  Expanded(
                    child: NeomorphicRadioGroup(
                      options: const ['Gelir', 'Gider'],
                      selectedOption: selectedOption,
                      onChanged: (value) {
                        setSelectedOption(value);
                      },
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
                              Navigator.push(context, MaterialPageRoute(
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
                              ));
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
                        child: ListTile(
                          title: Text(
                            data!.title,
                            style: TextStyle(
                                color: (selectedOption == 2)
                                    ? Colors.red
                                    : Colors.green),
                          ),
                          trailing: Text(
                            data.amount.toString(),
                            style: TextStyle(
                                fontSize: 18,
                                color: (selectedOption == 2)
                                    ? Colors.red
                                    : Colors.green),
                          ),
                          leading: Text(
                            "${data.date.toDate().toString().split(" ")[0]}\n${data.time}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: (selectedOption == 2)
                                    ? Colors.red
                                    : Colors.green),
                          ),
                          subtitle: Text(
                            data.tag,
                            style: const TextStyle(color: Colors.blue),
                          ),
                          titleAlignment: ListTileTitleAlignment.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
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

  void setSelectedOption(int option) {
    setState(() {
      selectedOption = option;
    });
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

class NeomorphicRadioGroup extends StatefulWidget {
  final List<String> options;
  final int selectedOption;
  final ValueChanged<int> onChanged;

  const NeomorphicRadioGroup({
    Key? key,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  }) : super(key: key);

  @override
  NeomorphicRadioGroupState createState() => NeomorphicRadioGroupState();
}

class NeomorphicRadioGroupState extends State<NeomorphicRadioGroup> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.options.map((option) {
        final index = widget.options.indexOf(option);
        final isSelected = index + 1 == widget.selectedOption;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              widget.onChanged(index + 1);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (index == 1 ? Colors.red : Colors.green)
                    : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(0, 6), // changes position of shadow
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 18,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
