import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                    onPressed: () =>
                        _showCreateWalletDialog(context, repository),
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
        onPressed: () => _showCreateWalletDialog(context, repository),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Cüzdan'),
      ),
    );
  }

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
          await repository.setActiveWallet(wallet.id);
          setState(() {});
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${wallet.name} aktif cüzdan olarak seçildi'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
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
                            if (wallet.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                  ),
                                ),
                                child: const Text(
                                  'Varsayılan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${wallet.balance.toStringAsFixed(2)} ₺',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                      onPressed: () =>
                          _showEditWalletDialog(context, wallet, repository),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Düzenle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!wallet.isDefault)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteWalletDialog(
                            context, wallet, repository),
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

  void _showCreateWalletDialog(
      BuildContext context, DataRepository repository) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController =
        TextEditingController(text: '0.0');

    String selectedColor = WalletDefaults.defaultColorHex;
    String selectedIcon = WalletDefaults.defaultIconName;
    bool isDefault = false; // ➕ YENİ: Varsayılan cüzdan mı?

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Yeni Cüzdan Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Cüzdan Adı',
                      hintText: 'Örn: Ana Cüzdan, Tatil Fonu',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: balanceController,
                    decoration: const InputDecoration(
                      labelText: 'Başlangıç Bakiyesi',
                      hintText: '0.0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Renk Seçin:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: WalletColors.presetColors.map((entry) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = entry.value.toString();
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                WalletColors.hexToColor(entry.value.toString()),
                            shape: BoxShape.circle,
                            border: selectedColor == entry.value
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
                          setDialogState(() {
                            selectedIcon = entry.key;
                          });
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
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Varsayılan Cüzdan'),
                    subtitle: const Text(
                        'Bu cüzdan varsayılan olarak kullanılsın mı?'),
                    value: isDefault,
                    onChanged: (value) {
                      setDialogState(() {
                        isDefault = value;
                      });
                    },
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
                  final balance =
                      double.tryParse(balanceController.text) ?? 0.0;

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen cüzdan adı girin')),
                    );
                    return;
                  }

                  final userId =
                      FirebaseAuth.instance.currentUser?.uid ?? 'local_user';
                  final wallet = Wallet.createLocal(
                    userId: userId,
                    name: name,
                    balance: balance,
                    colorHex: selectedColor,
                    iconName: selectedIcon,
                    isDefault: isDefault, // ➕ YENİ: isDefault değerini ekleyin
                    sortOrder: await _getNextSortOrder(repository),
                  );

                  try {
                    await repository.createWallet(wallet: wallet);
                    Navigator.pop(context);
                    setState(() {});

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"$name" cüzdanı oluşturuldu'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Oluştur'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditWalletDialog(
      BuildContext context, Wallet wallet, DataRepository repository) {
    final TextEditingController nameController =
        TextEditingController(text: wallet.name);
    final TextEditingController balanceController =
        TextEditingController(text: wallet.balance.toStringAsFixed(2));

    String selectedColor = wallet.colorHex;
    String selectedIcon = wallet.iconName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Cüzdanı Düzenle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Cüzdan Adı',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: balanceController,
                    decoration: const InputDecoration(
                      labelText: 'Bakiye',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Renk Seçin:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: WalletColors.presetColors.map((entry) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = entry.value.toString();
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                WalletColors.hexToColor(entry.value.toString()),
                            shape: BoxShape.circle,
                            border: selectedColor == entry.value
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
                          setDialogState(() {
                            selectedIcon = entry.key;
                          });
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
                  final balance =
                      double.tryParse(balanceController.text) ?? wallet.balance;

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen cüzdan adı girin')),
                    );
                    return;
                  }

                  final updatedWallet = wallet.copyWith(
                    name: name,
                    balance: balance,
                    colorHex: selectedColor,
                    iconName: selectedIcon,
                  );

                  try {
                    await repository.updateWallet(wallet: updatedWallet);
                    Navigator.pop(context);
                    setState(() {});

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"$name" cüzdanı güncellendi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteWalletDialog(
      BuildContext context, Wallet wallet, DataRepository repository) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cüzdanı Sil'),
        content: Text(
            '"${wallet.name}" cüzdanını silmek istediğinizden emin misiniz? '
            'Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await repository.deleteWallet(wallet.id);
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${wallet.name}" cüzdanı silindi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Silme hatası: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
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
            Text('• Varsayılan cüzdan silinemez.'),
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

  Future<int> _getNextSortOrder(DataRepository repository) async {
    final wallets = await repository.getAllWallets();
    if (wallets.isEmpty) return 0;
    return wallets.map((w) => w.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
