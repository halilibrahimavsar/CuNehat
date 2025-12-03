import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/widgets/empty_state_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/error_state_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_dialog_handler.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, walletState) {},
      builder: (context, walletState) {
        switch (walletState) {
          case NoDataSt():
            return EmptyStateWidget();
          case WalletLoadingSt():
            return const Center(child: CircularProgressIndicator());
          case WalletLoadedSt():
            final wallets = walletState.wallets;
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
                itemCount: walletState.wallets.length,
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

          case WalletErrorSt():
            return ErrorStateWidget(errorMessage: walletState.err);

          default:
            return Text("default");
        }
      },
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
