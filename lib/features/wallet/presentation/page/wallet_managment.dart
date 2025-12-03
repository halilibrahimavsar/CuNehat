import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_form_dialog.dart';
import 'package:cunehat/features/wallet/presentation/widgets/empty_state_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/error_state_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_info_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletManagementPage extends StatefulWidget {
  final String userId; // ✅ userId gerekli

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
    // ✅ Sayfa açıldığında cüzdanları yükle
    context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        // ✅ İşlem başarılı olunca listeyi yenile
        if (state is WalletCreatedSt) {
          context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
        } else if (state is WalletUpdatedSt) {
          context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
        } else if (state is WalletDeletedSt) {
          context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
        }
      },
      builder: (context, state) {
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
          body: _buildBody(state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showCreateEditDialog(
                context: context,
                userId: FirebaseAuth.instance.currentUser!
                    .uid, // TODO : This one is hardcoded, fix it ( in everywhere in the project)
                wallet: null, // null = create mode
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

        return WalletCardWidget(
          wallet: wallet,
          isActive: wallet.isActive,
          // activate
          onTap: () => context.read<WalletBloc>().add(SetActiveWalletEvent(
                userId: widget.userId,
                walletId: wallet.id,
              )),
          // edit
          onEdit: () {
            showCreateEditDialog(
              context: context,
              userId: FirebaseAuth.instance.currentUser!.uid,
              wallet: wallet, // non-null = edit mode
              onSuccess: () {/* ... */},
              onError: (error) {/* ... */},
            );
          },
          // delete
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
}
