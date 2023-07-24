import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

showSnackbar({
  required BuildContext context,
  required String title,
  required String msg,
  required ContentType type,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.fixed,
      backgroundColor: Colors.transparent,
      content:
          AwesomeSnackbarContent(title: title, message: msg, contentType: type),
    ),
  );
}
