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
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  Navigator.pop(context);
                  _showPinSetupDialog(isChanging: true);
                },
              ),
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
                onTap: () async {
                  Navigator.pop(context);
                  await _biometricService.deletePinCode();
                  await _biometricService.disableBiometric();
                  await _loadSettings();
                  _showSnackBar('🗑️ PIN kaldırıldı',
                      type: SnackbarType.success);
                },
              ),
            ],
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isChanging ? 'PIN Değiştir' : 'PIN Oluştur',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Güvenliğiniz için 6 haneli bir PIN belirleyin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '••••••',
                counterText: '',
                filled: true,
                fillColor:
                    Theme.of(context).dividerColor.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '••••••',
                counterText: '',
                filled: true,
                fillColor:
                    Theme.of(context).dividerColor.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
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
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: const Text('Profil'),
                  centerTitle: false,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  surfaceTintColor: theme.scaffoldBackgroundColor,
                  actions: [
                    IconButton(
                      onPressed: () => _loadSettings(),
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Yenile',
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserInfo(theme),
                        const SizedBox(height: 32),
                        _buildSectionHeader(theme, 'GÜVENLİK'),
                        const SizedBox(height: 16),
                        _buildSecurityCard(theme, isDark),
                        if (!_isAvailable) ...[
                          const SizedBox(height: 16),
                          _buildWarningCard(theme),
                        ],
                        const SizedBox(height: 32),
                        _buildSectionHeader(theme, 'HESAP'),
                        const SizedBox(height: 16),
                        _buildLogoutButton(theme),
                        const SizedBox(height: 50), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserInfo(ThemeData theme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String email = 'Kullanıcı';
        String initial = 'K';

        // Helper to extract user
        final user = state is Authenticated
            ? state.user
            : (state is AuthLocked ? state.user : null);

        if (user != null) {
          email = user.email ?? 'Kullanıcı';
          if (email.isNotEmpty) initial = email[0].toUpperCase();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 4),
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
        );
      },
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSecurityCard(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            theme,
            icon: Icons.lock_outline_rounded,
            title: 'PIN Kodu',
            subtitle: _isPinSet ? 'Aktif' : 'Ayarlanmadı',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isPinSet
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isPinSet ? 'Değiştir' : 'Kur',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isPinSet ? Colors.green : Colors.orange,
                ),
              ),
            ),
            onTap: _handlePinOperation,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
                height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
          ),
          _buildSettingsTile(
            theme,
            icon: Icons.fingerprint_rounded,
            title: 'Biyometrik Giriş',
            subtitle: 'Yüz veya parmak izi ile giriş',
            trailing: Switch.adaptive(
              value: _isBiometricEnabled,
              onChanged: _isPinSet ? _toggleBiometric : null,
              activeColor: theme.primaryColor,
            ),
            onTap:
                _isPinSet ? () => _toggleBiometric(!_isBiometricEnabled) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cihazınız biyometrik girişi desteklemiyor veya ayarlanmamış.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<AuthBloc>().add(SignOutRequested());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
          foregroundColor: theme.colorScheme.error,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded),
            SizedBox(width: 8),
            Text(
              'Çıkış Yap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SnackbarType { success, error, info }
