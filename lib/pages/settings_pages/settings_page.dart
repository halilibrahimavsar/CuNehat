import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/pages/settings_pages/settings_views_helpers/settings_header.dart';
import 'package:cunehat/pages/settings_pages/settings_views_helpers/settings_item.dart';
import 'package:cunehat/pages/settings_pages/settings_views_helpers/theme_selector_dropdown.dart';
import 'package:cunehat/repository/data_bloc/data_bloc.dart';
import 'package:cunehat/repository/data_bloc/data_event.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/repository/get_storage_mod.dart';
import 'package:cunehat/shared/dialogs/storage_mode_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/utilities/snackbar_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  }

  /// Shows storage mode selection dialog
  Future<void> _showStorageModeDialog() async {
    final repository = context.read<GetStorageMod>();
    final currentMode = repository.getStorageMode();

    final selectedMode = await SettingsDialogManager.showStorageModeDialog(
      context: context,
      currentMode: currentMode,
      onLocalTap: (mode) => mode,
      onCloudTap: (mode) => mode,
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
      final shouldMigrate =
          await SettingsDialogManager.showMigrationDialog(context);
      if (!shouldMigrate) return;

      setState(() => _isLoading = true);
      if (mounted) {
        SnackbarHelper.showLoading(context, 'Veriler buluta taşınıyor...');
      }

      try {
        await repository.migrateLocalToCloud();

        if (mounted) {
          setState(() {
            _currentMode = StorageMode.cloud;
            _isLoading = false;
          });

          _refreshMainPageData();

          SnackbarHelper.showSuccess(context, 'Veriler buluta taşındı!');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackbarHelper.showError(context, 'Geçiş başarısız: ${e.toString()}');
        }
      }
    }

    // CLOUD → LOCAL: Download cloud data to local
    else if (newMode == StorageMode.local) {
      final confirmed =
          await SettingsDialogManager.showCloudToLocalWarning(context);
      if (!confirmed) return;

      setState(() => _isLoading = true);
      if (mounted) {
        SnackbarHelper.showLoading(context, 'Bulut verileri indiriliyor...');
      }

      try {
        await repository.migrateCloudToLocal();

        if (mounted) {
          setState(() {
            _currentMode = StorageMode.local;
            _isLoading = false;
          });

          _refreshMainPageData();

          SnackbarHelper.showSuccess(
              context, 'Bulut verileri yerel depolamaya indirildi!');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackbarHelper.showError(context, 'Hata: ${e.toString()}');
        }
      }
    }
  }

  /// ⚠️ NEW METHOD: Refresh main page data
  void _refreshMainPageData() {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));

    context.read<DataBloc>().add(
          RefreshDataEvent(
            filterStart: startDate,
            filterEnd: now,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<DataRepository>();
    final pendingCount = repository.getPendingSyncCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SectionHeader(title: 'TEMA'),
          const ThemeDropdown(),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          SectionHeader(title: 'VERİ DEPOLAMA'),
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
          SectionHeader(title: 'UYGULAMA'),
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
          const SizedBox(height: 24),
          SectionHeader(title: "Profil"),
          SettingsItem(
            title: "Profil Ayarları",
            icon: Icons.person,
            onTap: () {
              context.push("/profile");
            },
          )
        ],
      ),
    );
  }
}
