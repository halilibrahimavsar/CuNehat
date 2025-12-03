// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:flutter/material.dart';

Future<void> showWalletDialog({
  required BuildContext context,
  WalletModel? wallet, // null → create, non-null → edit
  required Function(String message) onSuccess, // ✅ CHANGED: Pass message back
  Function(String error)? onError, // ✅ NEW: Optional error callback
}) async {
  await showDialog(
    context: context,
    builder: (context) {
      return _WalletFormDialog(
        isEditMode: wallet != null,
        onSuccess: onSuccess,
        onError: onError,
      );
    },
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
    return AlertDialog(
      title: Text(isEditMode ? 'Cüzdanı Düzenle' : 'Yeni Cüzdan Ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ============ NAME FIELD ============
            TextField(
              controller: TextEditingController(text: "state.name")
                ..selection = TextSelection.collapsed(
                  offset: 3,
                ),
              decoration: InputDecoration(
                labelText: 'Cüzdan Adı',
                hintText: 'Örn: Ana Cüzdan',
                errorText: "state.nameError",
              ),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),

            // ============ BALANCE FIELD ============
            TextField(
              controller: TextEditingController(text: "state.balance")
                ..selection = TextSelection.collapsed(
                  offset: 4,
                ),
              decoration: InputDecoration(
                labelText: isEditMode ? 'Bakiye' : 'Başlangıç Bakiyesi',
                hintText: '0.0',
                errorText: "state.balanceError",
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),

            // ============ COLOR PICKER ============
            const Text('Renk Seçin:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: WalletColors.presetColors.map((color) {
                final hex = WalletColors.colorToHex(color);
                final isSelected = Colors.amber.toString() == hex;

                return GestureDetector(
                  onTap: () {},
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
                final isSelected = Icons.abc.toString() == entry.key;

                return GestureDetector(
                  onTap: () {},
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
          },
          child: Text(isEditMode ? 'Kaydet' : 'Oluştur'),
        ),
      ],
    );
  }
}
