import 'package:cunehat/services/crud/cunehat_services.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DbExpense>>(
      stream: CunehatServices().allExpense,
      builder: (context, expenseSnapshot) {
        if (expenseSnapshot.hasData) {
          final expenses = expenseSnapshot.data;
          // Update UI with expenses data
          return ListView.builder(
            itemCount: expenses?.length,
            itemBuilder: (context, index) {
              final expense = expenses?[index];
              // Build UI item for expense
              return ListTile(
                onLongPress: () {
                  CunehatServices().expenseDelete(id: expense.id);
                },
                onTap: () {
                  showDialog(
                    context: context,
                    useSafeArea: true,
                    builder: (context) {
                      return const Dialog(
                        child: Column(
                          children: [
                            Text("TITLE"),
                          ],
                        ),
                      );
                    },
                  );
                },
                title: Text(expense!.note),
                trailing: Text(expense.price.toString()),
                leading: Text("${expense.date}\n${expense.time}"),
                subtitle: Text("${expense.tag}  |   ${expense.userId}"),
                titleAlignment: ListTileTitleAlignment.center,
                // Other expense details...
              );
            },
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

    // add some button which can be able to add PERSON, DELETE PERSON, SWİTCH PERSON,
  }
}
