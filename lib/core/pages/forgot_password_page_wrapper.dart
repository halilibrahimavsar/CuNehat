import 'package:flutter/material.dart';

import 'package:remote_auth_module/remote_auth_module.dart';

class ForgotPasswordPageWrapper extends StatelessWidget {
  const ForgotPasswordPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordPage(
      onResetSent: () {
        // Maybe show a dialog or just pop
        // The page itself shows a snackbar and pops, so we might not need to do anything here
        // But the callback is void Function?
        // Checking source: widget.onResetSent?.call(); Navigator.pop(context);
        // So it pops itself.
      },
    );
  }
}
