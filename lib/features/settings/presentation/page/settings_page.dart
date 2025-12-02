import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/settings/presentation/widgets/settings_header.dart';
import 'package:cunehat/features/settings/presentation/widgets/settings_item.dart';
import 'package:cunehat/features/settings/presentation/widgets/theme_selector_dropdown.dart';
import 'package:cunehat/repository/data_bloc/data_bloc.dart';
import 'package:cunehat/repository/data_bloc/data_event.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/core/shared/dialogs/storage_mode_dialog.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Import SettingsBloc
import 'package:cunehat/features/settings/presentation/provider/settings_bloc/settings_bloc.dart';

/// **SettingsPage**: Completely BLoC-driven
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(
        repository: context.read<DataRepository>(),
      )..add(LoadSettingsEvent()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        elevation: 0,
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          // ✅ Handle migration states
          if (state is MigrationInProgress) {
            SnackbarHelper.showLoading(context, state.message);
          } else if (state is MigrationSuccess) {
            SnackbarHelper.showSuccess(
              context,
              state.newMode == StorageMode.cloud
                  ? 'Veriler buluta taşındı!'
                  : 'Bulut verileri yerel depolamaya indirildi!',
            );

            // ✅ Refresh main page data
            _refreshMainPageData(context);
          } else if (state is SettingsError) {
            SnackbarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SettingsBloc>().add(LoadSettingsEvent());
                    },
                    child: const Text('Yeniden Dene'),
                  ),
                ],
              ),
            );
          }

          if (state is SettingsLoaded) {
            return _buildSettingsContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, SettingsLoaded state) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // THEME SECTION
        const SectionHeader(title: 'TEMA'),
        const ThemeDropdown(),
        const SizedBox(height: 24),

        // STORAGE SECTION
        const SectionHeader(title: 'VERİ DEPOLAMA'),
        _buildStorageModeCard(context, state),
        const SizedBox(height: 12),
        _buildStorageInfoCard(context, state.storageMode),
        const SizedBox(height: 24),

        // APP INFO SECTION
        const SectionHeader(title: 'UYGULAMA'),
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

        // PROFILE SECTION
        const SectionHeader(title: "Profil"),
        SettingsItem(
          title: "Profil Ayarları",
          icon: Icons.person,
          onTap: () {
            context.push("/profile");
          },
        ),
      ],
    );
  }

  Widget _buildStorageModeCard(BuildContext context, SettingsLoaded state) {
    final currentMode = state.storageMode;
    final pendingCount = state.pendingSyncCount;

    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          currentMode == StorageMode.cloud ? Icons.cloud : Icons.phone_android,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        title: Text(
          currentMode == StorageMode.cloud
              ? 'Bulut Depolama'
              : 'Yerel Depolama',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              currentMode == StorageMode.cloud
                  ? 'Veriler Google Firestore\'da güvende'
                  : 'Veriler sadece bu cihazda',
              style: const TextStyle(fontSize: 12),
            ),
            if (pendingCount > 0 && currentMode == StorageMode.cloud)
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showStorageModeDialog(context, currentMode),
      ),
    );
  }

  Widget _buildStorageInfoCard(BuildContext context, StorageMode currentMode) {
    return Card(
      color: currentMode == StorageMode.cloud
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
                  color: currentMode == StorageMode.cloud
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bilgi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: currentMode == StorageMode.cloud
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currentMode == StorageMode.cloud
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
    );
  }

  Future<void> _showStorageModeDialog(
    BuildContext context,
    StorageMode currentMode,
  ) async {
    final selectedMode = await SettingsDialogManager.showStorageModeDialog(
      context: context,
      currentMode: currentMode,
      onLocalTap: (mode) => mode,
      onCloudTap: (mode) => mode,
    );

    if (selectedMode != null &&
        selectedMode != currentMode &&
        context.mounted) {
      // Show appropriate confirmation dialog
      bool confirmed = false;

      if (selectedMode == StorageMode.cloud) {
        confirmed = await SettingsDialogManager.showMigrationDialog(context);
      } else {
        confirmed =
            await SettingsDialogManager.showCloudToLocalWarning(context);
      }

      if (confirmed && context.mounted) {
        // ✅ Use BLoC to change storage mode
        context.read<SettingsBloc>().add(ChangeStorageModeEvent(selectedMode));
      }
    }
  }

  void _refreshMainPageData(BuildContext context) {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));

    context.read<DataBloc>().add(
          RefreshDataEvent(
            filterStart: startDate,
            filterEnd: now,
          ),
        );
  }
}
