import 'package:cunehat/services/crud/cunehat_services.dart';
import 'package:flutter/material.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DbIncome>>(
      stream: CunehatServices().allIncome,
      builder: (context, incomeSnapshot) {
        if (incomeSnapshot.hasData) {
          final incomes = incomeSnapshot.data;
          // Update UI with incomes data
          return ListView.builder(
            itemCount: incomes?.length,
            itemBuilder: (context, index) {
              final income = incomes?[index];
              // Build UI item for income
              return ListTile(
                onLongPress: () {
                  CunehatServices().incomeDelete(id: income.id);
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
                title: Text(income!.note),
                trailing: Text(income.price.toString()),
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
