// lib/shared/widgets/wallet_managment.dart
// ✅ FIXED: Now uses app-level WalletBloc instead of creating new instance

import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/data_bloc/data_bloc.dart';
import 'package:cunehat/repository/data_bloc/data_event.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/shared/dialogs/wallet_form_dialog.dart';
import 'package:cunehat/shared/dialogs/wallet_info_dialog.dart';
import 'package:cunehat/utilities/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/repository/wallet_bloc/wallet_bloc.dart';

/// **WalletManagementPage**: Uses shared app-level WalletBloc
///
/// ✅ FIXED: No longer creates its own BLoC instance
class WalletManagementPage extends StatelessWidget {
  const WalletManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ CRITICAL FIX: Use existing WalletBloc, don't create new one
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
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          // ✅ Handle operation results
          if (state is WalletOperationSuccess) {
            SnackbarHelper.showSuccess(context, state.message);

            // ✅ Refresh main page data if active wallet changed
            if (state.type == WalletOperationType.setActive) {
              final now = DateTime.now();
              final startDate = now.subtract(const Duration(days: 30));

              context.read<DataBloc>().add(
                    RefreshDataEvent(
                      filterStart: startDate,
                      filterEnd: now,
                    ),
                  );
            }
          } else if (state is WalletError) {
            SnackbarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          // ✅ Loading state
          if (state is WalletLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ Error state
          if (state is WalletError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Hata: ${state.message}'),
                  ElevatedButton(
                    onPressed: () {
                      context.read<WalletBloc>().add(LoadWalletsEvent());
                    },
                    child: const Text('Yeniden Dene'),
                  ),
                ],
              ),
            );
          }

          // ✅ Loaded state
          if (state is WalletsLoaded) {
            final wallets = state.wallets;

            if (wallets.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<WalletBloc>().add(LoadWalletsEvent());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  final isActive = wallet.id == state.activeWalletId;

                  return _buildWalletCard(
                    context,
                    wallet,
                    isActive,
                  );
                },
              ),
            );
          }

          // ✅ Initial state
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWalletDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Cüzdan'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Henüz cüzdan eklenmemiş'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showCreateWalletDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('İlk Cüzdanı Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    BuildContext context,
    Wallet wallet,
    bool isActive,
  ) {
    final color = WalletColors.hexToColor(wallet.colorHex);

    return Card(
      elevation: isActive ? 8 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          // ✅ Use shared BLoC to set active wallet
          context.read<WalletBloc>().add(SetActiveWalletEvent(wallet.id));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      WalletIcons.getIcon(wallet.iconName),
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name & Balance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${wallet.balance.toStringAsFixed(2)} ₺',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                wallet.balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          'Oluşturulma: ${_formatDate(wallet.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active Indicator
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Aktif',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Action Buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditWalletDialog(context, wallet),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Düzenle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isActive)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, wallet),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Sil'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withOpacity(0.3)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateWalletDialog(BuildContext context) {
    showWalletDialog(
      context: context,
      wallet: null,
      onSuccess: (message) {
        SnackbarHelper.showSuccess(context, message);
        // ✅ Reload wallets using shared BLoC
        context.read<WalletBloc>().add(LoadWalletsEvent());
      },
      onError: (error) {
        SnackbarHelper.showError(context, error);
      },
    );
  }

  void _showEditWalletDialog(BuildContext context, Wallet wallet) {
    showWalletDialog(
      context: context,
      wallet: wallet,
      onSuccess: (message) {
        SnackbarHelper.showSuccess(context, message);
        // ✅ Reload wallets using shared BLoC
        context.read<WalletBloc>().add(LoadWalletsEvent());
      },
      onError: (error) {
        SnackbarHelper.showError(context, error);
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Wallet wallet) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: wallet.name,
    );

    if (confirmed == true && context.mounted) {
      // ✅ Use shared BLoC to delete wallet
      context.read<WalletBloc>().add(DeleteWalletEvent(wallet.id));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
