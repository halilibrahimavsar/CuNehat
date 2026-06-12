import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

class LocalAuthSettingsPage extends StatelessWidget {
  const LocalAuthSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.guvenlikAyarlari),
        elevation: 0,
      ),
      body: SafeArea(
        child: LocalAuthSettingsWidget(
          repository: getIt<LocalAuthRepository>(),
          texts: context.localAuthTexts,
          onPinChanged: () => debugPrint('PIN changed'),
          onBiometricToggled: () => debugPrint('Biometric toggled'),
          onPrivacyGuardToggled: () => debugPrint('Privacy Guard toggled'),
          onBackgroundLockChanged: () => debugPrint('Background lock changed'),
        ),
      ),
    );
  }
}
