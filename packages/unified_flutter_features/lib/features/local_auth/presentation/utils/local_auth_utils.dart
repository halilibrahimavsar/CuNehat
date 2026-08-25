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

  static int getLockoutDurationSeconds(int level) {
    return LocalAuthConstants.lockoutDurations[level] ??
        LocalAuthConstants.lockoutDurations[3]!;
  }

  /// Süre metni. Birim adları ÇAĞIRANDAN gelir: burada gömülüyken Türkçe
  /// arayüzde arka plan kilidi seçenekleri "5 seconds" yazıyordu.
  static String getRemainingTimeText(
    int seconds, {
    String secondsLabel = 'seconds',
    String minutesLabel = 'minutes',
  }) {
    if (seconds < 60) return '$seconds $secondsLabel';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '$minutes $minutesLabel';
    return '$minutes $minutesLabel $remainingSeconds $secondsLabel';
  }
}
