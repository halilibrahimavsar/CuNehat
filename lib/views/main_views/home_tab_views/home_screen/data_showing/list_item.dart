import 'package:cunehat/constants/currency_format.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:flutter/material.dart';

class ShowListWidget extends StatelessWidget {
  const ShowListWidget({
    Key? key,
    required this.selectedOption,
    required this.data,
  }) : super(key: key);

  final int selectedOption;
  final ModelProvider? data;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        tileColor: Colors.grey.shade200,
        title: Text(data!.title),
        trailing: Text(formatCurrency.format(data!.amount)),
        leading: Text(data!.time),
        subtitle: Text(data!.tag),
        titleAlignment: ListTileTitleAlignment.center,
      ),
    );
  }
}
