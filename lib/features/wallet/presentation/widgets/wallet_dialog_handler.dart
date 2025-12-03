import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_form_dialog.dart';
import 'package:flutter/material.dart';

class WalletDialogHandler {
  static void showCreateDialog(
    BuildContext context, {
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) {
    showWalletDialog(
      context: context,
      onSuccess: (message) {
        SnackbarHelper.showSuccess(context, message);
        onSuccess();
      },
      onError: (error) {
        SnackbarHelper.showError(context, error);
        onError(error);
      },
    );
  }

  static void showEditDialog(
    BuildContext context,
    WalletModel wallet, {
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) {
    showWalletDialog(
      context: context,
      wallet: wallet,
      onSuccess: (message) {
        SnackbarHelper.showSuccess(context, message);
        onSuccess();
      },
      onError: (error) {
        SnackbarHelper.showError(context, error);
        onError(error);
      },
    );
  }
}
