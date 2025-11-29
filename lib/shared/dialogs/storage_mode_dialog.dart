import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/pages/settings_pages/settings_views_helpers/storage_mode_option.dart';
import 'package:flutter/material.dart';

class SettingsDialogManager {
  /// Shows storage mode selection dialog
  static Future<StorageMode?> showStorageModeDialog({
    required BuildContext context,
    required StorageMode currentMode,
    required Function(StorageMode) onLocalTap,
    required Function(StorageMode) onCloudTap,
  }) async {
    return await showDialog<StorageMode>(
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
            StorageModeOption(
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
              onTap: () {
                Navigator.pop(dialogContext, StorageMode.local);
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            StorageModeOption(
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
              onTap: () {
                Navigator.pop(dialogContext, StorageMode.cloud);
              },
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
  }

  /// Shows migration dialog for local to cloud
  static Future<bool> showMigrationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => _MigrationDialog(),
        ) ??
        false;
  }

  /// Shows warning dialog for cloud to local migration
  static Future<bool> showCloudToLocalWarning(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => _CloudToLocalDialog(),
        ) ??
        false;
  }
}

/// Migration Dialog for Local → Cloud
class _MigrationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
    );
  }
}

/// Cloud to Local Migration Dialog
class _CloudToLocalDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
              fontSize: 13,
            ),
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
              fontSize: 13,
            ),
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
    );
  }
}
