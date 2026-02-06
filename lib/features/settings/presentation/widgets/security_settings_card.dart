import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/core/constants/app_constants.dart';

/// Card that navigates to security settings.
class SecuritySettingsCard extends StatelessWidget {
  const SecuritySettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Uygulama Kilidi'),
            subtitle: const Text('PIN, Biyometrik ve Gizlilik Ayarları'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.localAuthSettings),
          ),
        ],
      ),
    );
  }
}
