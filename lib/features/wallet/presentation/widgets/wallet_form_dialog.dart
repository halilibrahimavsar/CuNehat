// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/features/wallet/presentation/provider/wallet_form_bloc/wallet_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showWalletDialog({
  required BuildContext context,
  Wallet? wallet, // null → create, non-null → edit
  required Function(String message) onSuccess, // ✅ CHANGED: Pass message back
  Function(String error)? onError, // ✅ NEW: Optional error callback
}) async {
  await showDialog(
    context: context,
    builder: (dialogContext) => BlocProvider(
      create: (_) => WalletFormBloc(
        repository: context.read<DataRepository>(),
        initialWallet: wallet,
      ),
      child: _WalletFormDialog(
        isEditMode: wallet != null,
        onSuccess: onSuccess,
        onError: onError,
      ),
    ),
  );
}

/// **_WalletFormDialog**: Internal dialog widget
class _WalletFormDialog extends StatelessWidget {
  final bool isEditMode;
  final Function(String message) onSuccess;
  final Function(String error)? onError;

  const _WalletFormDialog({
    required this.isEditMode,
    required this.onSuccess,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletFormBloc, WalletFormState>(
      listener: (context, state) {
        // ✅ Handle success - close dialog and pass message to parent
        if (state is WalletFormSuccess) {
          Navigator.pop(context); // Close dialog first
          onSuccess(state.message); // Then show snackbar in parent context
        }
        // ✅ Handle error - close dialog and pass error to parent
        else if (state is WalletFormError) {
          Navigator.pop(context); // Close dialog first
          if (onError != null) {
            onError!(state.message); // Pass error to parent
          }
        }
      },
      builder: (context, state) {
        // Show loading overlay during submission
        final isSubmitting = state is WalletFormSubmitting;

        return Stack(
          children: [
            // Main dialog content
            _buildDialogContent(context, state),

            // Loading overlay
            if (isSubmitting)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context, WalletFormState state) {
    if (state is! WalletFormEditing) {
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: Text(isEditMode ? 'Cüzdanı Düzenle' : 'Yeni Cüzdan Ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ============ NAME FIELD ============
            TextField(
              controller: TextEditingController(text: state.name)
                ..selection = TextSelection.collapsed(
                  offset: state.name.length,
                ),
              decoration: InputDecoration(
                labelText: 'Cüzdan Adı',
                hintText: 'Örn: Ana Cüzdan',
                errorText: state.nameError,
              ),
              onChanged: (value) {
                context.read<WalletFormBloc>().add(UpdateNameEvent(value));
              },
            ),
            const SizedBox(height: 16),

            // ============ BALANCE FIELD ============
            TextField(
              controller: TextEditingController(text: state.balance)
                ..selection = TextSelection.collapsed(
                  offset: state.balance.length,
                ),
              decoration: InputDecoration(
                labelText: isEditMode ? 'Bakiye' : 'Başlangıç Bakiyesi',
                hintText: '0.0',
                errorText: state.balanceError,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                context.read<WalletFormBloc>().add(UpdateBalanceEvent(value));
              },
            ),
            const SizedBox(height: 16),

            // ============ COLOR PICKER ============
            const Text('Renk Seçin:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: WalletColors.presetColors.map((color) {
                final hex = WalletColors.colorToHex(color);
                final isSelected = state.colorHex == hex;

                return GestureDetector(
                  onTap: () {
                    context.read<WalletFormBloc>().add(UpdateColorEvent(hex));
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ============ ICON PICKER ============
            const Text('İkon Seçin:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: WalletIcons.icons.entries.map((entry) {
                final isSelected = state.iconName == entry.key;

                return GestureDetector(
                  onTap: () {
                    context
                        .read<WalletFormBloc>()
                        .add(UpdateIconEvent(entry.key));
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    child: Icon(
                      entry.value,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        // ============ CANCEL BUTTON ============
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),

        // ============ SUBMIT BUTTON ============
        ElevatedButton(
          onPressed: () {
            // ✅ Submit via BLoC
            context.read<WalletFormBloc>().add(SubmitFormEvent());
          },
          child: Text(isEditMode ? 'Kaydet' : 'Oluştur'),
        ),
      ],
    );
  }
}
