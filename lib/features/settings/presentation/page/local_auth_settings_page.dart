import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';
import 'package:cunehat/config/di/injection.dart';

class LocalAuthSettingsPage extends StatelessWidget {
  const LocalAuthSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik Ayarları'),
        elevation: 0,
      ),
      body: SafeArea(
        child: LocalAuthSettingsWidget(
          repository: getIt<LocalAuthRepository>(),
          onPinChanged: () => debugPrint('PIN changed'),
          onBiometricToggled: () => debugPrint('Biometric toggled'),
          onPrivacyGuardToggled: () => debugPrint('Privacy Guard toggled'),
          onBackgroundLockChanged: () => debugPrint('Background lock changed'),
        ),
      ),
    );
  }
}
