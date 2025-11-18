import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/pages/settings_pages/settings_views_helpers/theme_selector_dropdown.dart';
import 'package:cunehat/repository/data_bloc/data_bloc.dart';
import 'package:cunehat/repository/data_bloc/data_event.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/repository/get_storage_mod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// **SettingsPage**: WITH UI REFRESH AFTER MODE CHANGE
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late StorageMode _currentMode;
  bool _isLoading = false;
  final formatCurrency = NumberFormat.currency(symbol: "₺", decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _currentMode = context.read<GetStorageMod>().getStorageMode();
    print('🔧 [SETTINGS] Initialized with mode: ${_currentMode.name}');
  }

  /// Shows storage mode selection dialog
  Future<void> _showStorageModeDialog() async {
    final repository = context.read<GetStorageMod>();
    final currentMode = repository.getStorageMode();

    final selectedMode = await showDialog<StorageMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage, color: Colors.blue),
            SizedBox(width: 8),
            Text('Depolama Modu Seçin'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StorageModeOption(
              mode: StorageMode.local,
              currentMode: currentMode,
              icon: Icons.phone_android,
              title: 'Yerel Depolama',
              description: 'Veriler sadece bu cihazda saklanır',
              features: const [
                '✓ Hızlı erişim',
                '✓ İnternet gerektirmez',
                '✓ Tamamen özel',
                '✗ Cihaz arası senkronizasyon yok',
              ],
              onTap: () => Navigator.pop(dialogContext, StorageMode.local),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _StorageModeOption(
              mode: StorageMode.cloud,
              currentMode: currentMode,
              icon: Icons.cloud,
              title: 'Bulut Depolama',
              description: 'Veriler Google Firestore\'da saklanır',
              features: const [
                '✓ Çoklu cihaz desteği',
                '✓ Otomatik yedekleme',
                '✓ Veri güvenliği',
                '⚠ İnternet gerektirir',
              ],
              onTap: () => Navigator.pop(dialogContext, StorageMode.cloud),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (selectedMode != null && selectedMode != currentMode) {
      await _handleStorageModeChange(selectedMode);
    }
  }

  /// Handles storage mode change with migration if needed
  Future<void> _handleStorageModeChange(StorageMode newMode) async {
    final repository = context.read<DataRepository>();

    // LOCAL → CLOUD: Upload and clear local
    if (newMode == StorageMode.cloud) {
      final shouldMigrate = await _showMigrationDialog();
      if (!shouldMigrate) return;

      setState(() => _isLoading = true);

      try {
        print('🔄 [SETTINGS] Starting migration to cloud...');
        await repository.migrateLocalToCloud();
        print('✓ [SETTINGS] Migration successful');

        if (mounted) {
          setState(() {
            _currentMode = StorageMode.cloud;
            _isLoading =
                false; // Bu satır zaten vardı, tekrar eklemeye gerek yok.
          });

          print('📤 [SETTINGS] Triggering data refresh after mode change');
          _refreshMainPageData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✓ Veriler buluta taşındı!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('❌ [SETTINGS] Migration failed: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✗ Geçiş başarısız: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }

    // CLOUD → LOCAL: Download cloud data to local
    else if (newMode == StorageMode.local) {
      final confirmed = await _showCloudToLocalWarning();
      if (!confirmed) return;

      setState(() => _isLoading = true);

      try {
        print('🔄 [SETTINGS] Starting migration to local...');
        await repository.migrateCloudToLocal();
        print('✓ [SETTINGS] Migration successful');

        if (mounted) {
          setState(() {
            _currentMode = StorageMode.local;
            _isLoading = false;
          });

          print('📤 [SETTINGS] Triggering data refresh after mode change');
          _refreshMainPageData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✓ Bulut verileri yerel depolamaya indirildi!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('❌ [SETTINGS] Mode change failed: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✗ Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  /// ⚠️ NEW METHOD: Refresh main page data
  void _refreshMainPageData() {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));

    print('📤 [SETTINGS] Dispatching RefreshDataEvent');
    context.read<DataBloc>().add(
          RefreshDataEvent(
            filterStart: startDate,
            filterEnd: now,
          ),
        );
  }

  Future<bool> _showMigrationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
            title: const Text('Buluta Taşıma'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tüm yerel verileriniz (gelir ve giderler) buluta yüklenecek ve '
                  'cihazdan silinecektir.',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  '⚠️ Bu işlem geri alınamaz!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '✓ İnternet bağlantınızın aktif olduğundan emin olun.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Taşı'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showCloudToLocalWarning() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.download, size: 48, color: Colors.blue),
            title: const Text('Bulut Verilerini İndir'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tüm bulut verileriniz bu cihaza taşınacak ve buluttaki kopyaları silinecektir.',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  '✓ Ne Olacak:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  '• Buluttaki tüm veriler bu cihaza indirilecek.\n'
                  '• İndirme sonrası buluttaki verileriniz temizlenecek.\n'
                  '• Yeni işlemler sadece bu cihazda tutulacak',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 12),
                Text(
                  '⚠️ Dikkat:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  '• Bu işlemden sonra çoklu cihaz senkronizasyonu duracaktır.\n'
                  '• Verileriniz artık sadece bu cihazda saklanacaktır.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.move_down),
                label: const Text('İndir ve Geç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showEditBalanceDialog() {
    final repository = context.read<DataRepository>();
    final currentBalance = repository.getMainBalance();
    final controller = TextEditingController(
      text: currentBalance.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anapara Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mevcut Bakiye: ${formatCurrency.format(currentBalance)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Yeni Anapara',
                suffixText: '₺',
                border: OutlineInputBorder(),
                helperText: 'Not: Bu değer tüm işlemlerinizi etkilemez',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBalance = double.tryParse(controller.text) ?? 0.0;
              await repository.setMainBalance(newBalance);

              if (mounted) {
                setState(() {});
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Anapara ${formatCurrency.format(newBalance)} olarak güncellendi',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<DataRepository>();
    final currentBalance = repository.getMainBalance();
    final pendingCount = repository.getPendingSyncCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _SectionHeader(title: 'TEMA'),
          const ThemeDropdown(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'ANAPARA'),
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(
                Icons.account_balance_wallet,
                color: currentBalance >= 0 ? Colors.green : Colors.red,
                size: 28,
              ),
              title: const Text('Mevcut Bakiye'),
              subtitle: Text(
                formatCurrency.format(currentBalance),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: currentBalance >= 0 ? Colors.green : Colors.red,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _showEditBalanceDialog,
                tooltip: 'Düzenle',
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'VERİ DEPOLAMA'),
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(
                _currentMode == StorageMode.cloud
                    ? Icons.cloud
                    : Icons.phone_android,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              title: Text(
                _currentMode == StorageMode.cloud
                    ? 'Bulut Depolama'
                    : 'Yerel Depolama',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    _currentMode == StorageMode.cloud
                        ? 'Veriler Google Firestore\'da güvende'
                        : 'Veriler sadece bu cihazda',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (pendingCount > 0 && _currentMode == StorageMode.cloud)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$pendingCount işlem senkronizasyon bekliyor',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              trailing: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isLoading ? null : _showStorageModeDialog,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: _currentMode == StorageMode.cloud
                ? Colors.green.shade50
                : Colors.blue.shade50,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: _currentMode == StorageMode.cloud
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bilgi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentMode == StorageMode.cloud
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentMode == StorageMode.cloud
                        ? 'Tüm verileriniz bulutta güvenle saklanıyor. '
                            'Farklı cihazlardan erişebilirsiniz.'
                        : 'Verileriniz sadece bu cihazda tutuluyor. '
                            'Daha fazla güvenlik için buluta taşıyabilirsiniz.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'UYGULAMA'),
          Card(
            elevation: 1,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Versiyon'),
                  trailing: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Geliştirici'),
                  trailing: const Text('İbo + Claude'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StorageModeOption extends StatelessWidget {
  final StorageMode mode;
  final StorageMode currentMode;
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final VoidCallback onTap;

  const _StorageModeOption({
    required this.mode,
    required this.currentMode,
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.shade50 : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.blue : Colors.grey.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
