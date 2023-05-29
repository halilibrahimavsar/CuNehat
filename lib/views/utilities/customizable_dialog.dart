import 'package:flutter/material.dart';

class CustomizableDialog extends StatelessWidget {
  final String title;
  final String message;
  final Color backgroundColor;

  const CustomizableDialog({
    super.key,
    required this.title,
    required this.message,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      backgroundColor: backgroundColor,
      content: Text(message),
      actions: <Widget>[
        MaterialButton(
          color: Colors.redAccent,
          child: const Text("HAYIR"),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        MaterialButton(
          color: Colors.greenAccent,
          child: const Text("EVET"),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
