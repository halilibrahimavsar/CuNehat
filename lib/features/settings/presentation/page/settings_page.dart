import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/auth_feature/data/datasources/biometric_data_source.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/remote_auth/remote_auth_bloc.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/local_auth/local_auth_bloc.dart';
import 'package:cunehat/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:cunehat/features/settings/presentation/widgets/migration_dialog.dart';
import 'package:cunehat/features/settings/presentation/widgets/settings_header.dart';
import 'package:cunehat/features/settings/presentation/widgets/theme_selector_dropdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _toggleBiometric(bool value, LocalAuthState state) {
    if (value) {
      // Eğer PIN yoksa, direkt PIN oluşturmaya yönlendir
      if (!state.isPinSet) {
        SnackbarHelper.showInfo(
            context, '⚠️ Biyometrik için önce PIN oluşturmalısınız');
        _showPinSetupDialog(); // Otomatik yönlendirme
        return;
      }

      if (!state.isBiometricAvailable) {
        SnackbarHelper.showError(
            context, '❌ Cihazınız biyometrik desteklemiyor');
        return;
      }
    }

    context.read<LocalAuthBloc>().add(ToggleBiometricEvent(enable: value));
  }

  void _handlePinOperation(bool isPinSet) {
    if (isPinSet) {
      _showPinOptions();
    } else {
      _showPinSetupDialog();
    }
  }

  void _showPinOptions() {
    // 1. ADIM: BLoC referansını burada, güvenli context ile yakalıyoruz.
    // Bu sayede aşağıda context ölü olsa bile bloc referansı elimizde olur.
    final localAuthBloc = context.read<LocalAuthBloc>();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Builder context'ine 'sheetContext' adını verelim ki karışmasın
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- PIN DEĞİŞTİR SEÇENEĞİ ---
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.blue),
                ),
                title: const Text('PIN Değiştir'),
                onTap: () {
                  Navigator.pop(sheetContext); // BottomSheet'i kapat

                  _showVerificationDialog(
                    onSuccess: () {
                      _showPinSetupDialog(isChanging: true);
                    },
                  );
                },
              ),

              // --- PIN KALDIR SEÇENEĞİ ---
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                ),
                title: const Text('PIN Kaldır'),
                onTap: () {
                  Navigator.pop(sheetContext); // BottomSheet'i kapat

                  _showVerificationDialog(
                    title: 'PIN Kaldırılıyor',
                    subtitle:
                        'Güvenliğiniz için lütfen mevcut şifrenizi girin.',
                    onSuccess: () {
                      // 2. ADIM: Burada 'context.read' yerine yukarıda yakaladığımız değişkeni kullanıyoruz.
                      // Bu referans güvenlidir çünkü UI ağacından bağımsızdır.
                      localAuthBloc.add(DeletePinEvent());
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Eski _showOldPinDialog yerine bunu kullanın
  Future<void> _showVerificationDialog({
    required VoidCallback onSuccess,
    String title = 'Doğrulama Gerekli',
    String subtitle = 'Devam etmek için mevcut PIN kodunuzu doğrulayın.',
  }) async {
    final pinController = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              _buildPinField(
                // Senin yazdığın helper widget
                context: context,
                controller: pinController,
                hint: 'Mevcut PIN',
                errorText: error,
                autoFocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                setDialogState(() => error = null); // Hatayı temizle

                // Doğrulama işlemi
                final isValid = await BiometricDataSource()
                    .verifyPinCode(pinController.text);

                if (context.mounted) {
                  if (isValid) {
                    Navigator.pop(context); // Dialogu kapat
                    onSuccess(); // ✅ Başarılıysa istenen işlemi yap (Sil veya Değiştir)
                  } else {
                    setDialogState(() => error = 'Hatalı PIN kodu');
                    pinController.clear();
                  }
                }
              },
              child: const Text('Doğrula'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPinSetupDialog({bool isChanging = false}) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Hataları anlık göstermek için gerekli
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isChanging ? 'Yeni PIN Belirleyin' : 'PIN Oluştur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Güvenliğiniz için 4 haneli bir kod girin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              _buildPinField(
                context: context,
                controller: pinController,
                hint: 'Yeni PIN',
                autoFocus: true,
              ),
              const SizedBox(height: 16),
              _buildPinField(
                context: context,
                controller: confirmController,
                hint: 'Tekrar Girin',
                errorText: errorMessage, // Hata burada gösterilecek
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                final p1 = pinController.text;
                final p2 = confirmController.text;

                if (p1.length < 4) {
                  setDialogState(() => errorMessage = 'PIN 4 haneli olmalı');
                } else if (p1 != p2) {
                  setDialogState(() => errorMessage = 'PIN kodları eşleşmiyor');
                } else {
                  context.read<LocalAuthBloc>().add(SavePinEvent(p1));
                  Navigator.pop(context);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<LocalAuthBloc, LocalAuthState>(
      listener: (context, state) {
        if (state.message != null) {
          if (state.status == SecurityStatus.error) {
            SnackbarHelper.showError(context, state.message!);
          } else if (state.status == SecurityStatus.success) {
            SnackbarHelper.showSuccess(context, state.message!);
          }
        }
      },
      builder: (context, localAuthState) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            StorageMode currentMode = StorageMode.local;

            if (settingsState is StorageModeLoadedSt) {
              currentMode = settingsState.mode;
            } else if (settingsState is MigrationCompletedSt) {
              currentMode = settingsState.newMode;
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Ayarlar'),
                elevation: 0,
              ),
              body: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 1. KULLANICI KARTI (Eski Profil Sayfasından)
                  _buildUserCard(theme),
                  const SizedBox(height: 24),

                  // 2. TEMA
                  const SettingsHeader(title: 'GÖRÜNÜM'),
                  const ThemeSelectorDropdown(),
                  const SizedBox(height: 24),

                  // 3. GÜVENLİK (Yeni Entegre Edilen Kısım)
                  const SettingsHeader(title: 'GÜVENLİK'),
                  _buildSecuritySection(theme, localAuthState),
                  const SizedBox(height: 24),

                  // 4. VERİ DEPOLAMA
                  const SettingsHeader(title: 'VERİ & YEDEKLEME'),
                  _buildStorageModeCard(context, currentMode),
                  const SizedBox(height: 24),

                  // 5. UYGULAMA BİLGİSİ
                  const SettingsHeader(title: 'HAKKINDA'),
                  Card(
                    elevation: 1,
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Versiyon'),
                          trailing: Text('1.0.0'),
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          leading: Icon(Icons.code),
                          title: Text('Geliştirici'),
                          trailing: Text('İbo'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Çıkış Yap',
                              style: TextStyle(color: Colors.red)),
                          onTap: () {
                            context
                                .read<RemoteAuthBloc>()
                                .add(SignOutRequested());
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard(ThemeData theme) {
    return BlocBuilder<RemoteAuthBloc, AuthState>(
      builder: (context, state) {
        String email = 'Kullanıcı';
        String initial = 'K';

        final user = state is Authenticated
            ? state.user
            : (state is AuthLocked ? state.user : null);

        if (user != null) {
          email = user.email ?? 'Kullanıcı';
          if (email.isNotEmpty) initial = email[0].toUpperCase();
        }

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoşgeldiniz',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        email,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecuritySection(ThemeData theme, LocalAuthState state) {
    return Card(
      elevation: 1,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('PIN Kodu'),
            subtitle: Text(state.isPinSet ? 'Aktif' : 'Ayarlanmadı'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: state.isPinSet
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                state.isPinSet ? 'Değiştir' : 'Kur',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: state.isPinSet ? Colors.green : Colors.orange,
                ),
              ),
            ),
            onTap: () => _handlePinOperation(state.isPinSet),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biyometrik Giriş'),
            subtitle: const Text('Yüz veya parmak izi'),
            trailing: Switch.adaptive(
              value: state.isBiometricEnabled,
              onChanged: (val) => _toggleBiometric(val, state),
              activeColor: theme.primaryColor,
            ),
          ),
        ],
      ),
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

// Bu fonksiyonu _SettingsPageState içine ekleyin
Widget _buildPinField({
  required BuildContext context,
  required TextEditingController controller,
  required String hint,
  String? errorText,
  FocusNode? focusNode,
  bool autoFocus = false,
}) {
  return TextField(
    controller: controller,
    focusNode: focusNode,
    autofocus: autoFocus,
    keyboardType: TextInputType.number,
    maxLength: 4, // 4 haneye sabitledik
    obscureText: true,
    textAlign: TextAlign.center,
    style: const TextStyle(
        fontSize: 16, letterSpacing: 4, fontWeight: FontWeight.bold),
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      hintText: hint,
      errorText: errorText, // Hata mesajı burada görünecek
      counterText: '',
      filled: true,
      fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    ),
  );
}
