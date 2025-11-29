// ignore_for_file: deprecated_member_use

import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/data_bloc/data_bloc.dart';
import 'package:cunehat/repository/data_bloc/data_event.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/shared/dialogs/wallet_form_dialog.dart';
import 'package:cunehat/utilities/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletManagementPage extends StatefulWidget {
  const WalletManagementPage({super.key});

  @override
  State<WalletManagementPage> createState() => _WalletManagementPageState();
}

class _WalletManagementPageState extends State<WalletManagementPage> {
  @override
  Widget build(BuildContext context) {
    final repository = context.read<DataRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cüzdanlarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Wallet>>(
        future: repository.getAllWallets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Hata: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Yeniden Dene'),
                  ),
                ],
              ),
            );
          }

          final wallets = snapshot.data ?? [];

          if (wallets.isEmpty) {
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
                    onPressed: () => showWalletDialog(
                      context: context,
                      repository: repository,
                      onUpdated: () {},
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('İlk Cüzdanı Oluştur'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                final isActive = wallet.id == repository.getActiveWalletId();

                return _buildWalletCard(
                  context,
                  wallet,
                  isActive,
                  repository,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWalletDialog(
          context: context,
          repository: repository,
          onUpdated: () {},
        ),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Cüzdan'),
      ),
    );
  }

  // SADECE _buildWalletCard METODUNU DEĞİŞTİRİYORUZ

  Widget _buildWalletCard(
    BuildContext context,
    Wallet wallet,
    bool isActive,
    DataRepository repository,
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
        onTap: () async {
          // ✅ DÜZELTME: Cüzdanı değiştir ve ana sayfayı yenile
          await repository.setActiveWallet(wallet.id);

          // ➕ YENİ: setState ile bu sayfayı yenile
          setState(() {});

          if (context.mounted) {
            // ➕ YENİ: Ana sayfadaki DataBloc'u tetikle
            final now = DateTime.now();
            final startDate = now.subtract(const Duration(days: 30));

            context.read<DataBloc>().add(
                  RefreshDataEvent(
                    filterStart: startDate,
                    filterEnd: now,
                  ),
                );

            SnackbarHelper.showSuccess(
                context, '${wallet.name} aktif cüzdan olarak seçildi');

            // ➕ YENİ: Bottom sheet'i kapat ve ana sayfaya dön
            // Navigator.pop(context);
          }
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
                        Row(
                          children: [
                            Text(
                              wallet.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                      onPressed: () => showWalletDialog(
                          context: context,
                          repository: repository,
                          wallet: wallet,
                          onUpdated: () => setState(() {})),
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
                        onPressed: () async {
                          bool? result = await ConfirmDeleteDialog.show(context,
                              title: wallet.name);
                          if (result == true) {
                            await repository.deleteWallet(wallet.id);
                            setState(() {});
                          } else {
                            if (context.mounted) {
                              SnackbarHelper.showInfo(
                                  context, 'Silme işlemi iptal edildi.');
                            }
                          }
                        },
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cüzdan Yönetimi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Aktif cüzdanınızı değiştirmek için bir cüzdana tıklayın.'),
            SizedBox(height: 8),
            Text(
                '• Aktif olan cüzdan silinemez. Silmek için önce başka bir cüzdanı aktif yapmalısınız.'),
            SizedBox(height: 8),
            Text('• Cüzdan bakiyeleri otomatik olarak güncellenir.'),
            SizedBox(height: 8),
            Text('• Her cüzdanın kendi gelir/gider kayıtları vardır.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
