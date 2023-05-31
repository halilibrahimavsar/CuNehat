import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/cloud_const.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/add_data_views/update_data_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirestoreService()
          .getAllExpenses(ownerUserId: FirebaseAuth.instance.currentUser?.uid),
      builder: (context, expenseSnapshot) {
        if (expenseSnapshot.hasData) {
          final expenses = expenseSnapshot.data;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: expenses?.length,
                  itemBuilder: (context, index) {
                    final expense = expenses?.elementAt(index);
                    return Slidable(
                      // The start action pane is the one at the left or the top side.
                      startActionPane: ActionPane(
                        // A motion is a widget used to control how the pane animates.
                        motion: const ScrollMotion(),

                        // A pane can dismiss the Slidable.

                        // All actions are defined in the children parameter.
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) {
                                  return UpdateDataScreen(
                                    collection: FirebaseFirestore.instance
                                        .collection(expenseTable),
                                    id: expense?.id ?? "",
                                    note: expense?.title ?? "",
                                    price: expense?.amount ?? 0,
                                    tag: expense?.tag ?? "",
                                    date: expense?.date ?? "",
                                    time: expense?.time ?? "",
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
                            onPressed: (context) {
                              FirestoreService().deleteExpense(id: expense!.id);
                            },
                            backgroundColor: const Color(0xFFFE4A49),
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),

                      child: ListTile(
                        title: Text(expense!.title),
                        trailing: Text(expense.amount.toString()),
                        leading: Text("${expense.date}\n${expense.time}",
                            textAlign: TextAlign.center),
                        subtitle: Text(expense.tag),
                        titleAlignment: ListTileTitleAlignment.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        } else if (expenseSnapshot.hasError) {
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
