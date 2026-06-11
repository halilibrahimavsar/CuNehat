import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class GoogleDriveBackupCard extends StatefulWidget {
  const GoogleDriveBackupCard({super.key});

  @override
  State<GoogleDriveBackupCard> createState() => _GoogleDriveBackupCardState();
}

class _GoogleDriveBackupCardState extends State<GoogleDriveBackupCard> {
  final GoogleDriveBackupService _backupService =
      getIt<GoogleDriveBackupService>();
  final SharedPreferences _prefs = getIt<SharedPreferences>();

  bool _isLoading = false;
  bool _isConnected = false;
  String _userEmail = '';
  String _lastBackup = 'Hiç yedekleme yapılmadı';

  static const String _lastBackupKey = 'last_google_drive_backup_time';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    final isConnected = await _backupService.silentSignIn();
    final lastBackupTime = _prefs.getString(_lastBackupKey);

    setState(() {
      _isConnected = isConnected;
      if (isConnected && _backupService.currentUser != null) {
        _userEmail = _backupService.currentUser!.email;
      }
      if (lastBackupTime != null) {
        _lastBackup = lastBackupTime;
      }
      _isLoading = false;
    });
  }

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    final success = await _backupService.signIn();
    setState(() {
      _isConnected = success;
      if (success && _backupService.currentUser != null) {
        _userEmail = _backupService.currentUser!.email;
      }
      _isLoading = false;
    });

    if (success) {
      _showSnackBar('Google Drive başarıyla bağlandı.', Colors.green);
    } else {
      _showSnackBar('Google Drive bağlantısı başarısız oldu.', Colors.red);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    await _backupService.signOut();
    setState(() {
      _isConnected = false;
      _userEmail = '';
      _isLoading = false;
    });
    _showSnackBar('Google Drive bağlantısı kesildi.', Colors.orange);
  }

  Future<void> _backup() async {
    setState(() => _isLoading = true);
    final success = await _backupService.backup();
    if (success) {
      final nowStr = _formatDateTime(DateTime.now());
      await _prefs.setString(_lastBackupKey, nowStr);
      setState(() {
        _lastBackup = nowStr;
      });
      _showSnackBar(
          'Veriler Google Drive\'a başarıyla yedeklendi.', Colors.green);
    } else {
      _showSnackBar('Yedekleme başarısız oldu.', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verileri Geri Yükle?'),
        content: const Text(
          'Buluttaki verileriniz cihazınızdaki mevcut verilerin üzerine yazılacaktır. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Geri Yükle'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _backupService.restore();
    if (success) {
      _showSnackBar(
        'Veriler başarıyla geri yüklendi. Değişikliklerin görünmesi için lütfen uygulamayı yeniden başlatın.',
        Colors.green,
      );
    } else {
      _showSnackBar(
          'Geri yükleme başarısız oldu. Yedek dosyası bulunamadı.', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message, Color color) {
    if (color == Colors.green) {
      IboSnackbar.showSuccess(context, message);
    } else if (color == Colors.red) {
      IboSnackbar.showError(context, message);
    } else if (color == Colors.orange) {
      IboSnackbar.showWarning(context, message);
    } else {
      IboSnackbar.showInfo(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.cloud_queue_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Google Drive Yedekleme',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
            ],
          ),
          const SizedBox(height: 16),
          if (!_isConnected) ...[
            Text(
              'Verilerinizin güvenliği için kendi kişisel Google Drive hesabınıza yedekleme yapın.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _connect,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Google Drive\'a Bağlan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hesap:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _userEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Son Yedekleme:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _lastBackup,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _restore,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Geri Yükle'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: colorScheme.outline),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _backup,
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Yedekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _disconnect,
                icon:
                    const Icon(Icons.link_off_rounded, color: Colors.redAccent),
                label: const Text(
                  'Bağlantıyı Kes',
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
