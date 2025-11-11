import 'package:cunehat/pages/settings_pages/settings_views_helpers/general_helper.dart';
import 'package:cunehat/pages/settings_pages/settings_views_helpers/header_helper.dart';
import 'package:cunehat/pages/settings_pages/settings_views_helpers/switch_helper.dart';
import 'package:cunehat/pages/settings_pages/settings_views_helpers/theme_selector_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Ana Sayfa ---

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Geri dönüşsüz yer tutucu fonksiyon
  void _placeholderAction(String action) {
    // Gerçek uygulamada burada navigasyon, durum yönetimi veya API çağrısı olur.
    print('Action triggered: $action');
  }

  void _goToProfilePage(BuildContext context) {
    context.push("/profile");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[
          // ------------------------------------
          // 1. GÖRÜNÜM AYARLARI (TEMA & YAZI TİPİ)
          // ------------------------------------
          const SettingsHeader(title: "GÖRÜNÜM"),

          // Tema Seçimi (DROPDOWN ile doğrudan yapılıyor)
          const ThemeDropdown(),

          // Yazı Stili (Font)
          SettingsItem(
            title: "Yazı Stili",
            subtitle: "Uygulama fontunu değiştirin",
            icon: Icons.font_download_outlined,
            onTap: () => _placeholderAction("Yazı Stili Seçimi"),
          ),

          // ------------------------------------
          // 2. GÜVENLİK AYARLARI (UYGULAMA KİLİTLEME)
          // ------------------------------------
          const SettingsHeader(title: "GÜVENLİK"),

          // Uygulama Kilidi (Switch)
          SettingsSwitchItem(
            title: "Uygulama Kilidini Etkinleştir",
            icon: Icons.lock_outline,
            initialValue: false, // Başlangıç değeri
            onChanged: (isOn) {
              _placeholderAction("Uygulama Kilidi: $isOn");
            },
          ),

          // Şifre Değiştirme
          SettingsItem(
            title: "Şifreyi Değiştir",
            subtitle: "Uygulama kilidi şifrenizi güncelleyin",
            icon: Icons.vpn_key_outlined,
            onTap: () => _placeholderAction("Şifre Değiştirme Ekranı"),
          ),

          // ------------------------------------
          // 3. GENEL AYARLAR
          // ------------------------------------
          const SettingsHeader(title: "GENEL"),

          // Bildirimler
          SettingsSwitchItem(
            title: "Bildirimleri Aç/Kapat",
            icon: Icons.notifications_none,
            initialValue: true,
            onChanged: (isOn) {
              _placeholderAction("Bildirimler: $isOn");
            },
          ),

          // Veri Senkronizasyonu
          SettingsItem(
            title: "Veri Senkronizasyonu",
            subtitle: "Bulut verilerini şimdi senkronize et",
            icon: Icons.cloud_upload_outlined,
            onTap: () => _placeholderAction("Senkronizasyon Başlatıldı"),
          ),

          // ------------------------------------
          // 4. HESAP
          // ------------------------------------
          const SettingsHeader(title: "HESAP"),

          SettingsItem(
            title: "Profil",
            subtitle: "Profil düzenleme ve oturum işlemleri",
            icon: Icons.account_circle_outlined,
            onTap: () => _goToProfilePage(context),
          ),
        ],
      ),
    );
  }
}
