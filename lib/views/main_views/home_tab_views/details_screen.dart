import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirestoreService()
          .getAllIncomes(ownerUserId: FirebaseAuth.instance.currentUser?.uid),
      builder: (context, incomeSnapshot) {
        if (incomeSnapshot.hasData) {
          final incomes = incomeSnapshot.data;
          // Update UI with incomes data
          return ListView.builder(
            itemCount: incomes?.length,
            itemBuilder: (context, index) {
              final income = incomes?.elementAt(index);
              // Build UI item for income
              return ListTile(
                onLongPress: () {
                  // TODO : CunehatServices().incomeDelete(id: income.id);
                },
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return const Dialog(
                        child: Column(
                          children: [
                            Text("title"),
                          ],
                        ),
                      );
                    },
                  );
                },
                title: Text(income!.date),
                trailing: Text(income.amount.toString()),
                leading: Text("${income.date}\n${income.time}"),
                subtitle: Text("${income.tag}  |   ${income.userId}"),
                titleAlignment: ListTileTitleAlignment.center,
                // Other income details...
              );
            },
          );
        } else if (incomeSnapshot.hasError) {
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
