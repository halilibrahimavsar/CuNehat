import 'package:cunehat/constants/currency_format.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:flutter/material.dart';

class SubListItem extends StatelessWidget {
  const SubListItem({
    Key? key,
    required this.selectedOption,
    required this.data,
  }) : super(key: key);

  final int selectedOption;
  final ModelProvider? data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        data!.title,
        style: TextStyle(
          color: selectedOption == 2 ? Colors.red : Colors.green,
        ),
      ),
      trailing: Text(
        formatCurrency.format(data!.amount),
        style: TextStyle(
          color: selectedOption == 2 ? Colors.red : Colors.green,
        ),
      ),
      leading: Text(
        data!.time,
        style: TextStyle(
          color: selectedOption == 2 ? Colors.red : Colors.green,
        ),
      ),
      subtitle: Text(
        data!.tag,
        style: TextStyle(
          color: selectedOption == 2 ? Colors.red : Colors.green,
        ),
      ),
      titleAlignment: ListTileTitleAlignment.center,
    );
  }
}
