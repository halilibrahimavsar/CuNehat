import 'package:cunehat/services/firestore/firestore_service.dart';
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
                          // A SlidableAction can have an icon and/or a label.
                          SlidableAction(
                            onPressed: (context) {},
                            backgroundColor: Color(0xFFFE4A49),
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                          SlidableAction(
                            onPressed: (context) {},
                            backgroundColor: Color(0xFF21B7CA),
                            foregroundColor: Colors.white,
                            icon: Icons.update,
                            label: 'Update',
                          ),
                        ],
                      ),

                      // The end action pane is the one at the right or the bottom side.
                      endActionPane: ActionPane(
                        motion: ScrollMotion(),
                        children: [
                          SlidableAction(
                            // An action can be bigger than the others.
                            flex: 2,
                            onPressed: (context) {},
                            backgroundColor: Color(0xFF7BC043),
                            foregroundColor: Colors.white,
                            icon: Icons.share,
                            label: 'Share',
                          ),
                        ],
                      ),

                      // The child of the Slidable is what the user sees when the
                      // component is not dragged.
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

          // return ListView.builder(
          //   itemCount: expenses?.length,
          //   itemBuilder: (context, index) {
          //     final expense = expenses?.elementAt(index);
          //     // Build UI item for expense
          //     return ListTile(
          //       onLongPress: () {
          //         // CunehatServices().expenseDelete(id: expense.id);
          //       },
          //       onTap: () {
          //         showDialog(
          //           context: context,
          //           useSafeArea: true,
          //           builder: (context) {
          //             return const Dialog(
          //               child: Column(
          //                 children: [
          //                   Text("TITLE"),
          //                 ],
          //               ),
          //             );
          //           },
          //         );
          //       },
          //       title: Text(expense!.date),
          //       trailing: Text(expense.amount.toString()),
          //       leading: Text("${expense.date}\n${expense.time}"),
          //       subtitle: Text("${expense.tag}  |   ${expense.userId}"),
          //       titleAlignment: ListTileTitleAlignment.center,
          //       // Other expense details...
          //     );
          //   },
          // );
        } else if (expenseSnapshot.hasError) {
          // Handle error case
          return const Center(child: Text('There is no data'));
        } else {
          // Show loading indicator
          return const Center(child: CircularProgressIndicator());
        }
      },
    );

    // add some button which can be able to add PERSON, DELETE PERSON, SWİTCH PERSON,
  }
}
