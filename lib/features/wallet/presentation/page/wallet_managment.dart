// lib/features/wallet/presentation/page/wallet_managment.dart
// ✅ UPDATED: Add transfer button

import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/transfer/domain/usecases/transfer_money_usecase.dart';
import 'package:cunehat/features/transfer/presentation/widgets/transfer_dialog.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_form_dialog.dart';
import 'package:cunehat/features/wallet/presentation/widgets/empty_state_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/error_state_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletManagementPage extends StatefulWidget {
  final String userId;

  const WalletManagementPage({
    super.key,
    required this.userId,
  });

  @override
  State<WalletManagementPage> createState() => _WalletManagementPageState();
}

class _WalletManagementPageState extends State<WalletManagementPage> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WalletCreatedSt ||
            state is WalletUpdatedSt ||
            state is WalletDeletedSt) {
          context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cüzdanlarım'),
            actions: [
              // ========== ✅ NEW: Transfer Button ==========
              if (state is WalletLoadedSt && state.wallets.length >= 2)
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () => _showTransferDialog(context, state.wallets),
                  tooltip: 'Para Transferi',
                ),

              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => WalletInfoDialog.show(context),
              ),
            ],
          ),
          body: _buildBody(state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showCreateEditDialog(
                context: context,
                userId: widget.userId,
                wallet: null,
                onSuccess: () {
                  SnackbarHelper.showSuccess(context, 'Cüzdan oluşturuldu!');
                },
                onError: (error) {
                  SnackbarHelper.showError(context, error);
                },
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Yeni Cüzdan'),
          ),
        );
      },
    );
  }

  Widget _buildBody(WalletState state) {
    return switch (state) {
      NoDataSt() => const EmptyStateWidget(),
      WalletLoadingSt() => const Center(child: CircularProgressIndicator()),
      WalletLoadedSt() => _buildWalletList(state.wallets),
      WalletErrorSt() => ErrorStateWidget(errorMessage: state.err),
      _ => const Center(child: Text('Beklenmeyen durum')),
    };
  }

  Widget _buildWalletList(List<WalletModel> wallets) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wallets.length,
      itemBuilder: (context, index) {
        final wallet = wallets[index];
        print("||||||||||||||||||||||||||");
        print(wallet);
        print("||||||||||||||||||||||||||");
        return WalletCardWidget(
          wallet: wallet,
          onTap: () => context.read<WalletBloc>().add(SetActiveWalletEvent(
                userId: widget.userId,
                walletId: wallet.id,
              )),
          onEdit: () {
            showCreateEditDialog(
              context: context,
              userId: widget.userId,
              wallet: wallet,
              onSuccess: () {
                SnackbarHelper.showSuccess(context, 'Cüzdan güncellendi!');
              },
              onError: (error) {
                SnackbarHelper.showError(context, error);
              },
            );
          },
          onDelete: () => ConfirmDeleteDialog.show(
            context,
            title: "Cüzdanı Sil",
            onDelete: () {
              context.read<WalletBloc>().add(
                    DeleteWalletEvent(wallet.id),
                  );
            },
          ),
        );
      },
    );
  }

  // ========== ✅ NEW: Show Transfer Dialog ==========
  Future<void> _showTransferDialog(
      BuildContext context, List<WalletModel> wallets) async {
    final transferUseCase = TransferMoneyUseCase(
      context.read<WalletBloc>().repository,
    );

    final bool? transferSuccessful = await showTransferDialog(
      context: context,
      userId: widget.userId,
      wallets: wallets,
      transferUseCase: transferUseCase,
    );

    // Show snackbar here, after the dialog is closed
    if (transferSuccessful == true && context.mounted) {
      SnackbarHelper.showSuccess(context, '✅ Transfer başarılı!');
    }
  }
}
