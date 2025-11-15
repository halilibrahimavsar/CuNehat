import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/data_layer/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SharedDrawer extends StatelessWidget {
  const SharedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 1,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text("Debug: Yerel Verileri Göster"),
            onTap: () async {
              Navigator.pop(context);
              final repo = context.read<DataRepository>();
              final allIncomes = await repo.getAllIncomes();
              final allExpenses = await repo.getAllExpenses();
              final mode = repo.getStorageMode();

              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Debug Bilgisi"),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Mod: ${mode.name}"),
                          const Divider(),
                          Text("Gelir Sayısı: ${allIncomes.length}"),
                          ...allIncomes
                              .take(3)
                              .map((i) => Text("- ${i.title}: ${i.amount}₺")),
                          const Divider(),
                          Text("Gider Sayısı: ${allExpenses.length}"),
                          ...allExpenses
                              .take(3)
                              .map((e) => Text("- ${e.title}: ${e.amount}₺")),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Kapat"),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Ayarlar"),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.settings);
            },
          ),
        ],
      ),
    );
  }
}
