import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/settings/data/repository/settings_repository_impl.dart';
import 'package:cunehat/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:cunehat/features/settings/presentation/widgets/migration_dialog.dart';
import 'package:cunehat/features/settings/presentation/widgets/settings_header.dart';
import 'package:cunehat/features/settings/presentation/widgets/settings_item.dart';
import 'package:cunehat/features/settings/presentation/widgets/theme_selector_dropdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(context.read<SettingsRepositoryImpl>())
        ..add(const LoadStorageModeEvent()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        StorageMode currentMode = StorageMode.local;

        if (state is StorageModeLoadedSt) {
          currentMode = state.mode;
        } else if (state is MigrationCompletedSt) {
          currentMode = state.newMode;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ayarlar'),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const SettingsHeader(title: 'TEMA'),
              const ThemeSelectorDropdown(),
              const SizedBox(height: 24),

              // STORAGE SECTION
              const SettingsHeader(title: 'VERİ DEPOLAMA'),
              _buildStorageModeCard(context, currentMode),
              const SizedBox(height: 24),

              // APP INFO SECTION
              const SettingsHeader(title: 'UYGULAMA'),
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
                      trailing: const Text('İbo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // PROFILE SECTION
              const SettingsHeader(title: "Profil"),
              SettingsItem(
                title: "Profil Ayarları",
                icon: Icons.person,
                onTap: () {
                  context.push("/profile");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStorageModeCard(BuildContext context, StorageMode currentMode) {
    final settingsBloc = context.read<SettingsBloc>();

    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          currentMode == StorageMode.cloud ? Icons.cloud : Icons.phone_android,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        title: const Text(
          'Depolama Modu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          currentMode == StorageMode.cloud
              ? 'Veriler bulutta saklanıyor'
              : 'Veriler cihazda saklanıyor',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          showMigrationDialog(
            context: context,
            userId: FirebaseAuth.instance.currentUser!.uid,
            currentMode: currentMode,
            settingsBloc: settingsBloc, // ✅ Bloc'u parametre olarak geçiyoruz
          );
        },
      ),
    );
  }
}
