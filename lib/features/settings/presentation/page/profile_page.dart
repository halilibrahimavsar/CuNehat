import 'dart:async';
import 'package:cunehat/features/auth_feature/data/datasources/biometric_data_source.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricEnabled = false;
  bool _isPinSet = false;
  bool _isLoading = true;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final [bioEnabled, pinSet, isAvailable] = await Future.wait([
      _biometricService.isBiometricEnabled(),
      _biometricService.isPinCodeSet(),
      _biometricService.isBiometricAvailable(),
    ]);

    if (mounted) {
      setState(() {
        _isBiometricEnabled = bioEnabled;
        _isPinSet = pinSet;
        _isAvailable = isAvailable;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Açmaya çalışıyor
      if (!_isPinSet) {
        _showDialog(
          title: 'PIN Gerekli',
          message: 'Biyometrik girişi açmak için önce PIN belirlemelisiniz.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPinSetupDialog();
              },
              child: const Text('PIN Oluştur'),
            ),
          ],
        );
        return;
      }

      if (!_isAvailable) {
        _showSnackBar(
          'Cihazınızda biyometrik doğrulama kullanılamıyor.',
          type: SnackbarType.error,
        );
        return;
      }

      // Açmadan önce doğrulama iste
      final authenticated =
          await _biometricService.authenticateWithBiometrics();

      if (authenticated && mounted) {
        await _biometricService.enableBiometric();
        _showSnackBar(
          'Biyometrik giriş etkinleştirildi',
          type: SnackbarType.success,
        );
      }
    } else {
      // Kapatmaya çalışıyor
      await _biometricService.disableBiometric();
      _showSnackBar(
        'Biyometrik giriş devre dışı bırakıldı',
        type: SnackbarType.info,
      );
    }
  }

  void _handlePinOperation() async {
    if (_isPinSet) {
      // PIN zaten var, değiştirme veya silme seçenekleri
      _showBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(
              icon: Icons.edit,
              title: 'PIN Değiştir',
              subtitle: 'Mevcut PIN kodunuzu değiştirin',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _showPinSetupDialog(isChanging: true);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline,
              title: 'PIN Kaldır',
              subtitle: 'PIN girişini devre dışı bırak',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                await _showConfirmDialog(
                  title: 'PIN Kaldır',
                  message:
                      'PIN kodunuz ve biyometrik giriş kaldırılacak. Emin misiniz?',
                  onConfirm: () async {
                    await _biometricService.deletePinCode();
                    await _biometricService.disableBiometric();
                    await _loadSettings();
                    _showSnackBar(
                      'PIN ve biyometrik giriş kaldırıldı',
                      type: SnackbarType.success,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            ),
          ],
        ),
      );
    } else {
      // PIN yok, oluştur
      _showPinSetupDialog();
    }
  }

  Future<void> _showPinSetupDialog({bool isChanging = false}) async {
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorText;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isChanging ? 'PIN Değiştir' : 'PIN Oluştur',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPinInputField(
                  controller: newPinController,
                  label: 'Yeni PIN',
                  hint: '6 haneli PIN giriniz',
                ),
                const SizedBox(height: 16),
                _buildPinInputField(
                  controller: confirmPinController,
                  label: 'PIN Tekrar',
                  hint: 'PIN tekrarını giriniz',
                  errorText: errorText,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (newPinController.text.length != 6 ||
                              confirmPinController.text.length != 6) {
                            setState(
                                () => errorText = 'PIN 6 haneli olmalıdır');
                            return;
                          }
                          if (newPinController.text !=
                              confirmPinController.text) {
                            setState(
                                () => errorText = 'PIN kodları eşleşmiyor');
                            return;
                          }

                          await _biometricService
                              .savePinCode(newPinController.text);
                          if (context.mounted) {
                            Navigator.pop(context);
                            await _loadSettings();
                            _showSnackBar(
                              'PIN başarıyla kaydedildi',
                              type: SnackbarType.success,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Kaydet',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            letterSpacing: 8,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          textAlign: TextAlign.center,
          onChanged: (_) {
            if (errorText != null) {
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('PIN Kodu'),
            subtitle: Text(_isPinSet ? 'Aktif' : 'Ayarlanmadı'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handlePinOperation,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biyometrik Giriş'),
            subtitle: const Text('Yüz veya parmak izi'),
            value: _isBiometricEnabled,
            onChanged: _isPinSet ? _toggleBiometric : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: color.withValues(alpha: 0.7)),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showSnackBar(String message, {required SnackbarType type}) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case SnackbarType.error:
        backgroundColor = Colors.red;
        icon = Icons.error_outline;
        break;
      case SnackbarType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info_outline;
        break;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<void> _showConfirmDialog({
    required String title,
    required String message,
    required FutureOr<void> Function() onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Onayla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDialog({
    required String title,
    required String message,
    required List<Widget> actions,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions,
      ),
    );
  }

  Future<void> _showBottomSheet({required Widget child}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    'PIN İşlemleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik Ayarları'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSecuritySection(),
                if (!_isAvailable) ...[
                  const SizedBox(height: 16),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline, color: Colors.amber),
                      title: Text('Cihazınız biyometrik girişi desteklemiyor'),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(SignOutRequested());
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Çıkış Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

enum SnackbarType { success, error, info }
