import 'package:cunehat/constants/chose_storage.dart';
import 'package:cunehat/data_layer/data_repository.dart';
import 'package:cunehat/pages/settings_pages/settings_views_helpers/theme_selector_dropdown.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late StorageMode _currentMode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında mevcut depolama modunu oku
    _currentMode = context.read<DataRepository>().getStorageMode();
  }

  Future<void> _migrateToCloud() async {
    // Kullanıcıya bir onay sorusu sormak iyi bir fikir olabilir.
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
    if (context.mounted) {
      try {
        // DataRepository'deki geçiş fonksiyonunu çağır
        await context.read<DataRepository>().migrateLocalToCloud();

        // Başarılı
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
      } catch (e) {
        // Hata
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ThemeDropdown(),
          ListTile(
            title: const Text("Veri Depolama"),
            subtitle: Text(_isLoading
                ? "Geçiş yapılıyor..."
                : "Mevcut mod: ${_currentMode == StorageMode.cloud ? 'Bulut (Firestore)' : 'Yerel (Cihaz)'}"),
          ),
          if (_currentMode == StorageMode.local && !_isLoading)
            ElevatedButton(
              onPressed: _migrateToCloud,
              child: const Text("Verileri Buluta Taşı ve Senkronize Et"),
            ),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_currentMode == StorageMode.cloud && !_isLoading)
            const ListTile(
              leading: Icon(Icons.cloud_done, color: Colors.green),
              title: Text("Verileriniz güvende!"),
              subtitle:
                  Text("Tüm verileriniz artık bulut ile senkronize ediliyor."),
            ),
        ],
      ),
    );
  }
}
