import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_dialog_handler.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_info_dialog.dart';
import 'package:flutter/material.dart';

List<WalletModel> wallets = List.generate(
  3,
  (index) {
    return WalletModel(
      id: index.toString(),
      userId: index.toString(),
      name: index.toString(),
      balance: index.toDouble(),
      colorHex: index.toString(),
      iconName: index.toString(),
      createdAt: DateTime.now(),
      isActive: index == 0,
      sortOrder: index,
    );
  },
);

class WalletManagementPage extends StatelessWidget {
  const WalletManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WalletManagementView();
  }
}

class _WalletManagementView extends StatelessWidget {
  const _WalletManagementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cüzdanlarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => WalletInfoDialog.show(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: wallets.length,
        itemBuilder: (context, index) {
          final wallet = wallets[index];
          final isActive = true;

          return WalletCardWidget(
            wallet: wallet,
            isActive: isActive,
            onTap: () {},
            onEdit: () => _showEditWalletDialog(context, wallet),
            onDelete: () => _confirmDelete(context, wallet),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWalletDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Cüzdan'),
      ),
    );
  }

  void _showCreateWalletDialog(BuildContext context) {
    WalletDialogHandler.showCreateDialog(
      context,
      onSuccess: () {},
      onError: (error) {
        // Error is already shown via SnackbarHelper
      },
    );
  }

  void _showEditWalletDialog(BuildContext context, WalletModel wallet) {
    WalletDialogHandler.showEditDialog(
      context,
      wallet,
      onSuccess: () {},
      onError: (error) {
        // Error is already shown via SnackbarHelper
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WalletModel wallet) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: wallet.name,
    );

    if (confirmed == true && context.mounted) {}
  }
}
