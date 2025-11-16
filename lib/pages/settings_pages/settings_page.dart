import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/data_layer/data_repository.dart';
import 'package:cunehat/pages/settings_pages/settings_views_helpers/theme_selector_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
    _currentMode = context.read<DataRepository>().getStorageMode();
  }

  Future<void> _migrateToCloud() async {
    final wantsToMigrate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Buluta Taşı"),
        content: const Text(
            "Tüm yerel verileriniz (gelir ve giderler) buluta taşınacak ve cihazdan silinecektir. Bu işlem geri alınamaz. Emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Taşı"),
          ),
        ],
      ),
    );

    if (wantsToMigrate != true) return;

    setState(() {
      _isLoading = true;
    });

    // context.mounted kontrolü asenkron işlemden SONRA yapılmalı
    try {
      await context.read<DataRepository>().migrateLocalToCloud();

      if (mounted) {
        setState(() {
          _currentMode = StorageMode.cloud;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Başarıyla buluta taşındı!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Geçiş başarısız: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        title: const Text("Anapara Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Mevcut Bakiye: ${formatCurrency.format(currentBalance)}",
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
                labelText: "Yeni Anapara",
                suffixText: "₺",
                border: OutlineInputBorder(),
                helperText: "Not: Bu değer tüm işlemlerinizi etkilemez",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal"),
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
                      "Anapara ${formatCurrency.format(newBalance)} olarak güncellendi",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<DataRepository>();
    final currentBalance = repository.getMainBalance();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // TEMA AYARI
          const Text(
            "TEMA",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const ThemeDropdown(),

          const SizedBox(height: 24),

          // ANAPARA AYARI
          const Text(
            "ANAPARA",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.account_balance_wallet,
                color: currentBalance >= 0 ? Colors.green : Colors.red,
              ),
              title: const Text("Mevcut Bakiye"),
              subtitle: Text(
                formatCurrency.format(currentBalance),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: currentBalance >= 0 ? Colors.green : Colors.red,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _showEditBalanceDialog,
                tooltip: "Düzenle",
              ),
            ),
          ),

          const SizedBox(height: 24),

          // VERİ DEPOLAMA AYARI
          const Text(
            "VERİ DEPOLAMA",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                _currentMode == StorageMode.cloud
                    ? Icons.cloud
                    : Icons.phone_android,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text("Depolama Modu"),
              subtitle: Text(
                _isLoading
                    ? "Geçiş yapılıyor..."
                    : "Mevcut: ${_currentMode == StorageMode.cloud ? 'Bulut (Firestore)' : 'Yerel (Cihaz)'}",
              ),
              trailing: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),

          if (_currentMode == StorageMode.local && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton.icon(
                onPressed: _migrateToCloud,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Verileri Buluta Taşı"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

          if (_currentMode == StorageMode.cloud && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Card(
                color: Colors.green.shade50,
                child: const ListTile(
                  leading: Icon(Icons.cloud_done, color: Colors.green),
                  title: Text("Verileriniz güvende!"),
                  subtitle: Text(
                    "Tüm verileriniz artık bulut ile senkronize ediliyor.",
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
