import 'package:cunehat/constants/currency_format.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:flutter/material.dart';

class SubListItem extends StatelessWidget {
  const SubListItem({
    Key? key,
    required this.data,
  }) : super(key: key);

  final ModelProvider? data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        data!.title,
        style: const TextStyle(color: Colors.cyan),
      ),
      trailing: Text(
        formatCurrency.format(data!.amount),
        style: const TextStyle(color: Colors.cyan),
      ),
      leading: Text(
        data!.time,
        style: const TextStyle(color: Colors.cyan),
      ),
      subtitle: Text(
        data!.tag,
        style: const TextStyle(color: Colors.cyan),
      ),
      titleAlignment: ListTileTitleAlignment.center,
    );
  }
}
