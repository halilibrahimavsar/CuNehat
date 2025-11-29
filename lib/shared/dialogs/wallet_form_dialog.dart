// ignore_for_file: deprecated_member_use

import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/utilities/snackbar_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showWalletDialog({
  required BuildContext context,
  required DataRepository repository,
  Wallet? wallet, // null → create, dolu → edit
  required VoidCallback onUpdated,
}) {
  final TextEditingController nameController =
      TextEditingController(text: wallet?.name ?? '');

  final TextEditingController balanceController = TextEditingController(
    text: wallet != null ? wallet.balance.toStringAsFixed(2) : '0.0',
  );

  String selectedColor = wallet?.colorHex ?? WalletDefaults.defaultColorHex;
  String selectedIcon = wallet?.iconName ?? WalletDefaults.defaultIconName;

  final scaffoldContext = context;

  final bool isEdit = wallet != null;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(isEdit ? 'Cüzdanı Düzenle' : 'Yeni Cüzdan Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Cüzdan Adı',
                    hintText: 'Örn: Ana Cüzdan',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: balanceController,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Bakiye' : 'Başlangıç Bakiyesi',
                    hintText: '0.0',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Renk Seçin:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: WalletColors.presetColors.map((color) {
                    final hex = WalletColors.colorToHex(color);
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedColor = hex);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == hex
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('İkon Seçin:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: WalletIcons.icons.entries.map((entry) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedIcon = entry.key);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selectedIcon == entry.key
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: selectedIcon == entry.key
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                        ),
                        child: Icon(
                          entry.value,
                          color: selectedIcon == entry.key
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text) ??
                    (wallet?.balance ?? 0.0);

                if (name.isEmpty) {
                  SnackbarHelper.showInfo(context, 'Lütfen cüzdan adı girin');

                  return;
                }

                try {
                  if (isEdit) {
                    // --------------------------------------------------------
                    // EDIT
                    // --------------------------------------------------------
                    final updatedWallet = wallet.copyWith(
                      name: name,
                      balance: balance,
                      colorHex: selectedColor,
                      iconName: selectedIcon,
                    );

                    await repository.updateWallet(wallet: updatedWallet);
                    if (scaffoldContext.mounted) {
                      SnackbarHelper.showSuccess(context, 'Cüzdan güncellendi');
                    }
                  } else {
                    // --------------------------------------------------------
                    // CREATE
                    // --------------------------------------------------------
                    final userId =
                        FirebaseAuth.instance.currentUser?.uid ?? 'local_user';

                    final newWallet = Wallet.createLocal(
                      userId: userId,
                      name: name,
                      balance: balance,
                      colorHex: selectedColor,
                      iconName: selectedIcon,
                      isActive: false,
                      sortOrder: await repository.getAllWallets().then(
                        (value) {
                          return value.length;
                        },
                      ),
                    );

                    await repository.createWallet(wallet: newWallet);
                    if (scaffoldContext.mounted) {
                      SnackbarHelper.showSuccess(context, 'Cüzdan oluşturuldu');
                    }
                  }

                  onUpdated(); // UI yenile
                } catch (e) {
                  if (scaffoldContext.mounted) {
                    SnackbarHelper.showError(context, 'Hata: $e');
                  }
                }
              },
              child: Text(isEdit ? 'Kaydet' : 'Oluştur'),
            ),
          ],
        );
      },
    ),
  );
}
