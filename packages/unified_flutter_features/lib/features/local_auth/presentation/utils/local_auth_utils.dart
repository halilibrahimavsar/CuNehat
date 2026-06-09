import '../../data/local_auth_repository.dart';
import '../constants/local_auth_constants.dart';

class LocalAuthUtils {
  static Future<bool> validateBiometricRequirements(
    LocalAuthRepository repository,
  ) async {
    final isPinSet = await repository.isPinSet();
    final isBioEnabled = await repository.isBiometricEnabled();
    final isAvailable = await repository.isBiometricAvailable();

    return isPinSet && isBioEnabled && isAvailable;
  }

  static Future<void> ensureBiometricConsistency(
    LocalAuthRepository repository,
  ) async {
    final isPinSet = await repository.isPinSet();
    final isBioEnabled = await repository.isBiometricEnabled();

    if (!isPinSet && isBioEnabled) {
      await repository.setBiometricEnabled(false);
    }
  }

  static String getLockoutDurationText(int level) {
    if (level <= 0) return '30 seconds';
    if (level == 1) return '2 minutes';
    if (level == 2) return '5 minutes';
    return '16.7 minutes';
  }

  static int getLockoutDurationSeconds(int level) {
    return LocalAuthConstants.lockoutDurations[level] ??
        LocalAuthConstants.lockoutDurations[3]!;
  }

  static String getRemainingTimeText(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '$minutes minutes';
    return '$minutes minutes $remainingSeconds seconds';
  }
}
