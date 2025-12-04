import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows storage mode selection + migration confirmation dialog
Future<void> showMigrationDialog({
  required BuildContext context,
  required String userId, // Kullanıcı kimliği
  required StorageMode currentMode, // Mevcut depolama modu
  required SettingsBloc settingsBloc, // Ayarlar Bloc'u
}) async {
  final result = await showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: settingsBloc, // ✅ Parametreden gelen bloc'u kullan
        child: _MigrationDialog(
          userId: userId,
          currentMode: currentMode,
        ),
      );
    },
  );

  // Dialog kapandıktan sonra gelen sonuca göre SnackBar göster
  if (result != null && context.mounted) {
    if (result.startsWith('✅')) {
      SnackbarHelper.showSuccess(context, result);
    } else {
      SnackbarHelper.showError(context, result);
    }
  }
}

class _MigrationDialog extends StatefulWidget {
  final String userId;
  final StorageMode currentMode;

  const _MigrationDialog({
    required this.userId,
    required this.currentMode,
  });

  @override
  State<_MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<_MigrationDialog> {
  StorageMode? _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is MigrationCompletedSt) {
          Navigator.pop(context, '✅ Migration tamamlandı!');
        } else if (state is SettingsErrorSt) {
          Navigator.pop(context, '❌ Migration hatası: ${state.error}');
        }
      },
      builder: (context, state) {
        // Migration sırasında ilerleme durumu diyaloğunu göster
        if (state is MigrationInProgressSt) {
          return _buildProgressDialog(state);
        }

        // Diğer tüm durumlarda seçim diyaloğunu göster
        return _buildSelectionDialog();
      },
    );
  }

  /// Storage mode selection dialog
  Widget _buildSelectionDialog() {
    return AlertDialog(
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
          _buildModeOption(
            mode: StorageMode.local,
            icon: Icons.phone_android,
            title: 'Yerel Depolama',
            description: 'Veriler sadece bu cihazda saklanır',
            features: const [
              '✓ Hızlı erişim',
              '✓ İnternet gerektirmez',
              '✓ Tamamen özel',
              '✗ Cihaz arası senkronizasyon yok',
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildModeOption(
            mode: StorageMode.cloud,
            icon: Icons.cloud,
            title: 'Bulut Depolama',
            description: 'Veriler Google Firestore\'da saklanır',
            features: const [
              '✓ Çoklu cihaz desteği',
              '✓ Otomatik yedekleme',
              '✓ Veri güvenliği',
              '⚠ İnternet gerektirir',
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _selectedMode == widget.currentMode
              ? null
              : () => _confirmMigration(context),
          child: const Text('Değiştir'),
        ),
      ],
    );
  }

  /// Mode option card
  Widget _buildModeOption({
    required StorageMode mode,
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
  }) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
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

  /// Migration progress dialog
  Widget _buildProgressDialog(MigrationInProgressSt state) {
    return AlertDialog(
      title: const Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text(
            'Migration Devam Ediyor',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: state.progress),
          const SizedBox(height: 16),
          Text(
            state.step,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            '${(state.progress * 100).toInt()}%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog before migration
  void _confirmMigration(BuildContext context) {
    final isGoingToCloud = _selectedMode == StorageMode.cloud;

    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        icon: Icon(
          isGoingToCloud ? Icons.cloud_upload : Icons.download,
          size: 48,
          color: Colors.blue,
        ),
        title: Text(isGoingToCloud ? 'Buluta Taşı' : 'Yerele İndir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isGoingToCloud
                  ? 'Tüm yerel verileriniz buluta yüklenecek ve cihazdan silinecektir.'
                  : 'Tüm bulut verileriniz bu cihaza indirilecek ve buluttan silinecektir.',
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Bu işlem geri alınamaz!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '✓ İnternet bağlantınızın aktif olduğundan emin olun.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(confirmContext); // Close confirmation
              // Trigger migration using the bloc from the outer context
              context.read<SettingsBloc>().add(
                    ChangeStorageModeEvent(
                      userId: widget.userId,
                      newMode: _selectedMode!,
                    ),
                  );
            },
            icon: Icon(isGoingToCloud ? Icons.cloud_upload : Icons.download),
            label: const Text('Taşı'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
