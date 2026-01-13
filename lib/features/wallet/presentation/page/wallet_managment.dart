import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/core/shared/widgets/error_view.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/transfer/domain/usecases/transfer_money_usecase.dart';
import 'package:cunehat/features/transfer/presentation/widgets/transfer_dialog.dart';
import 'package:cunehat/features/wallet/data/repository/wallet_repository_impl.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_form_dialog.dart';
import 'package:cunehat/features/wallet/presentation/widgets/no_wallet_view.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletSheetContent extends StatefulWidget {
  final String userId;
  final ScrollController scrollController;

  const WalletSheetContent({
    super.key,
    required this.userId,
    required this.scrollController,
  });

  @override
  State<WalletSheetContent> createState() => _WalletSheetContentState();
}

class _WalletSheetContentState extends State<WalletSheetContent> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WalletOperationSuccesSt) {
          context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.9),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // ========== DRAG HANDLE ==========
                _buildDragHandle(),

                // ========== HEADER ==========
                _buildHeader(context, state),

                // ========== DIVIDER ==========
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade200,
                ),

                // ========== BODY CONTENT ==========
                Expanded(
                  child: _buildBody(state),
                ),

                // ========== FLOATING ADD BUTTON ==========
                _buildFloatingAddButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Drag handle (sürükleme göstergesi)
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Header with title and actions
  Widget _buildHeader(BuildContext context, WalletState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
      child: Row(
        children: [
          // Icon + Title
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cüzdanlarım',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Cüzdanlarınızı yönetin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (state is WalletLoadedSt && state.wallets.length >= 2)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _showTransferDialog(context, state.wallets),
              tooltip: 'Para Transferi',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => WalletInfoDialog.show(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Body content based on state
  Widget _buildBody(WalletState state) {
    return switch (state) {
      NoWalletSt() => const Center(
          child: NoWalletView(
            infoText: "Henüz cüzdan oluşturmadınız",
            showButton: false,
          ),
        ),
      WalletLoadingSt() => const Center(
          child: CircularProgressIndicator(),
        ),
      WalletLoadedSt() => _buildWalletList(state.wallets),
      WalletErrorSt() => Center(
          child: ErrorView(message: state.err),
        ),
      _ => const Center(
          child: Text('Beklenmeyen durum'),
        ),
    };
  }

  /// Wallet list
  Widget _buildWalletList(List<WalletEntity> wallets) {
    return ListView.builder(
      controller: widget.scrollController,
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for FAB
      itemCount: wallets.length,
      itemBuilder: (context, index) {
        final wallet = wallets[index];
        return AnimatedScale(
          scale: 1.0,
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          child: WalletCardWidget(
            wallet: wallet,
            onTap: () => context.read<WalletBloc>().add(
                  SetActiveWalletEvent(
                    userId: widget.userId,
                    walletId: wallet.id!,
                  ),
                ),
            onEdit: () => _editWallet(context, wallet),
            onDelete: () => _deleteWallet(context, wallet),
          ),
        );
      },
    );
  }

  /// Floating add button (fixed at bottom)
  Widget _buildFloatingAddButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => _createWallet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add, size: 22),
            label: const Text(
              'Yeni Cüzdan Oluştur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // 🔧 HELPER METHODS
  // ========================================

  void _createWallet(BuildContext context) {
    showCreateEditDialog(
      context: context,
      userId: widget.userId,
      wallet: null,
      onSuccess: () {
        SnackbarHelper.showSuccess(context, '✅ Cüzdan oluşturuldu!');
      },
      onError: (error) {
        SnackbarHelper.showError(context, '❌ $error');
      },
    );
  }

  void _editWallet(BuildContext context, WalletEntity wallet) {
    showCreateEditDialog(
      context: context,
      userId: widget.userId,
      wallet: wallet,
      onSuccess: () {
        SnackbarHelper.showSuccess(context, '✅ Cüzdan güncellendi!');
      },
      onError: (error) {
        SnackbarHelper.showError(context, '❌ $error');
      },
    );
  }

  void _deleteWallet(BuildContext context, WalletEntity wallet) {
    ConfirmDeleteDialog.show(
      context,
      title: wallet.name,
      onDelete: () {
        context.read<WalletBloc>().add(DeleteWalletEvent(wallet.id!));
        SnackbarHelper.showSuccess(context, '🗑️ Cüzdan silindi');
      },
    );
  }

  Future<void> _showTransferDialog(
    BuildContext context,
    List<WalletEntity> wallets,
  ) async {
    final transferUseCase = TransferMoneyUseCase(
      context.read<WalletRepositoryImpl>().dataSource,
    );

    final bool? transferSuccessful = await showTransferDialog(
      context: context,
      userId: widget.userId,
      wallets: wallets,
      transferUseCase: transferUseCase,
    );

    if (transferSuccessful == true && context.mounted) {
      SnackbarHelper.showSuccess(context, '✅ Transfer başarılı!');
      // Refresh wallets
      context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
    }
  }
}
