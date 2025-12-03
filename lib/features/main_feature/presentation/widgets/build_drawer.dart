import 'package:cunehat/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// **SharedDrawer**: Navigation drawer for the app
///
/// Provides quick access to:
/// - Settings page
/// - (Future: Analytics, Export, etc.)
class SharedDrawer extends StatelessWidget {
  const SharedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 1,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ============ HEADER ============
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'CuNehat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Finansal Yönetim',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ============ NAVIGATION ITEMS ============
          const Divider(),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Yatırım Takip'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.investment);
            },
          ),

          // Future menu items can be added here:
          // - Analytics/Reports
          // - Export Data
          // - Help/About
        ],
      ),
    );
  }
}
