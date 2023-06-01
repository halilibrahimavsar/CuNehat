import 'package:clay_containers/clay_containers.dart';
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

  void setSelectedOption(int option) {
    setState(() {
      selectedOption = option;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: selectedOption == 1
          ? FirestoreService().getAllExpenses(
              ownerUserId: FirebaseAuth.instance.currentUser?.uid)
          : FirestoreService().getAllIncomes(
              ownerUserId: FirebaseAuth.instance.currentUser?.uid),
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
                                    date: data?.date ?? "",
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
                                    title: const Text("Sil!"),
                                    content: const Text(
                                        "Bu veriyi tekrar getiremezsiniz. Silinsin mi?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                        child: const Text("Hayır"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                        child: const Text("Evet"),
                                      ),
                                    ],
                                  );
                                },
                              ).then((value) => value ?? false);

                              if (isDelete) {
                                selectedOption == 1
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
                            backgroundColor: const Color(0xFFFE4A49),
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ClayContainer(
                        curveType: CurveType.concave,
                        borderRadius: 10,
                        depth: 10,
                        child: ListTile(
                          title: Text(data!.title),
                          trailing: Text(data.amount.toString()),
                          leading: Text("${data.date}\n${data.time}",
                              textAlign: TextAlign.center),
                          subtitle: Text(data.tag),
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
                color: isSelected ? Colors.blue : Colors.white,
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
