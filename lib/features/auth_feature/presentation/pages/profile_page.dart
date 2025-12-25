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
      if (!_isPinSet) {
        _showSnackBar('⚠️ Önce PIN oluşturmalısınız', type: SnackbarType.error);
        return;
      }

      if (!_isAvailable) {
        _showSnackBar('❌ Cihazınız biyometrik desteklemiyor',
            type: SnackbarType.error);
        return;
      }

      final authenticated =
          await _biometricService.authenticateWithBiometrics();
      if (authenticated && mounted) {
        await _biometricService.enableBiometric();
        _showSnackBar('✅ Biyometrik giriş etkinleştirildi',
            type: SnackbarType.success);
      }
    } else {
      await _biometricService.disableBiometric();
      _showSnackBar('🔒 Biyometrik giriş kapatıldı', type: SnackbarType.info);
    }

    await _loadSettings();
  }

  void _handlePinOperation() async {
    if (_isPinSet) {
      _showPinOptions();
    } else {
      _showPinSetupDialog();
    }
  }

  void _showPinOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('PIN Değiştir'),
              onTap: () {
                Navigator.pop(context);
                _showPinSetupDialog(isChanging: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('PIN Kaldır'),
              onTap: () async {
                Navigator.pop(context);
                await _biometricService.deletePinCode();
                await _biometricService.disableBiometric();
                await _loadSettings();
                _showSnackBar('🗑️ PIN kaldırıldı', type: SnackbarType.success);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPinSetupDialog({bool isChanging = false}) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isChanging ? 'PIN Değiştir' : 'PIN Oluştur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Yeni PIN (6 haneli)',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'PIN Tekrar',
                counterText: '',
                border: OutlineInputBorder(),
              ),
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
              if (pinController.text.length != 6) {
                _showSnackBar('PIN 6 haneli olmalı', type: SnackbarType.error);
                return;
              }
              if (pinController.text != confirmController.text) {
                _showSnackBar('PIN kodları eşleşmiyor',
                    type: SnackbarType.error);
                return;
              }

              await _biometricService.savePinCode(pinController.text);
              if (context.mounted) {
                Navigator.pop(context);
                await _loadSettings();
                _showSnackBar('✅ PIN kaydedildi', type: SnackbarType.success);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required SnackbarType type}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: type == SnackbarType.success
            ? Colors.green
            : type == SnackbarType.error
                ? Colors.red
                : Colors.blue,
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
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('PIN Kodu'),
                        subtitle: Text(_isPinSet ? 'Aktif' : 'Ayarlanmadı'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _handlePinOperation,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.fingerprint),
                        title: const Text('Biyometrik Giriş'),
                        subtitle: const Text('Yüz veya parmak izi'),
                        value: _isBiometricEnabled,
                        onChanged: _isPinSet ? _toggleBiometric : null,
                      ),
                    ],
                  ),
                ),
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
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
    );
  }
}

enum SnackbarType { success, error, info }
