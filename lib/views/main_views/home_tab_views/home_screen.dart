import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/add_data_views/update_data_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedOption = 1;
  Timestamp firstDate = Timestamp.fromMillisecondsSinceEpoch(
    DateTime(
      DateTime.now().year,
      DateTime.now().month,
    ).millisecondsSinceEpoch,
  );
  Timestamp lastDate = Timestamp.fromMillisecondsSinceEpoch(
      DateTime.now().add(Duration(hours: 3)).millisecondsSinceEpoch);

  void setSelectedOption(int option) {
    setState(() {
      selectedOption = option;
    });
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
          final allData = snapshot.data;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                          (selectedOption == 2) ? Colors.red : Colors.green)),
                  onPressed: () async {
                    DateTimeRange result = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(1997),
                          lastDate: DateTime(2050),
                          currentDate: DateTime.now(),
                          initialDateRange: DateTimeRange(
                            start: DateTime.now()
                                .subtract(const Duration(days: 30)),
                            end: DateTime.now(),
                          ),
                        ) ??
                        DateTimeRange(
                            start: DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                            ),
                            end: DateTime.now());
                    setState(() {
                      firstDate = Timestamp.fromMillisecondsSinceEpoch(
                          result.start.millisecondsSinceEpoch);
                      lastDate = Timestamp.fromMillisecondsSinceEpoch(result.end
                          .add(const Duration(hours: 3))
                          .millisecondsSinceEpoch);
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        firstDate.toDate().toString().split(" ")[0],
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const Text(
                        ">",
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      Text(
                        lastDate.toDate().toString().split(" ")[0],
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
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
                              bool isDelete = await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.amber,
                                    title: const Text("Sil!"),
                                    content: const Text(
                                        "Bu veriyi tekrar getiremezsiniz. Silinsin mi?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                        child: const Text(
                                          "Hayır",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                        child: const Text(
                                          "Evet",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ).then((value) => value ?? false);

                              if (isDelete) {
                                (selectedOption == 2)
                                    ? FirestoreService()
                                        .deleteExpense(id: data!.id)
                                    : FirestoreService()
                                        .deleteIncome(id: data!.id);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content: AwesomeSnackbarContent(
                                          title: "Sil",
                                          message:
                                              "Veriler geri getirilemez! \nSilinsin mi",
                                          contentType: ContentType.warning),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
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
          print(snapshot.error);
          // Handle error case
          return const Center(child: Text('There is no data'));
        } else {
          // Show loading indicator
          return const Center(child: CircularProgressIndicator());
        }
      },
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
