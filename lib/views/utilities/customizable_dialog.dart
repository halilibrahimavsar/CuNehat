import 'package:flutter/material.dart';

Future<bool> showCustmDialog(
  BuildContext context, {
  required String title,
  required String msg,
  required String cancelButton,
  required String confirmButton,
  required Color color,
  required Function() functionWhenConfirm,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: color,
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              cancelButton,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              functionWhenConfirm();
              Navigator.pop(context, true);
            },
            child: Text(
              confirmButton,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}
