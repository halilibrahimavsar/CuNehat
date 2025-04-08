import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

showSnackbar({
  required BuildContext context,
  required String title,
  required String msg,
  required ContentType type,
  Duration? keepAlive,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: keepAlive ?? const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: msg,
        contentType: type,
      ),
    ),
  );
}
