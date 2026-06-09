import 'dart:async';

/// Repository interface for local authentication operations.
///
/// This abstract class defines the contract for all local authentication
/// related data operations including biometric authentication, PIN management,
/// privacy settings, and security lockout mechanisms.
///
/// Implementations should handle secure storage of authentication data
/// and provide thread-safe operations for all authentication methods.
abstract class LocalAuthRepository {
  /// Stream of settings changes that widgets can listen to for updates.
  ///
  /// Emits whenever any setting (privacy guard, background lock, etc.) changes.
  Stream<void> get settingsChanges;

  /// Checks if biometric authentication is available on the device.
  ///
  /// Returns true if device has biometric hardware (fingerprint, face ID, etc.).
  Future<bool> isBiometricAvailable();

  /// Checks if biometric authentication is enabled by the user.
  ///
  /// Returns true if user has opted in to biometric authentication.
  Future<bool> isBiometricEnabled();

  /// Enables or disables biometric authentication.
  ///
  /// [enabled] Whether to enable biometric authentication.
  Future<void> setBiometricEnabled(bool enabled);

  /// Checks if a PIN has been set for authentication.
  ///
  /// Returns true if user has configured a PIN.
  Future<bool> isPinSet();

  /// Saves a new PIN for authentication.
  ///
  /// [pin] The PIN to save (should be hashed before storage).
  Future<void> savePin(String pin);

  /// Verifies if the provided PIN matches the stored PIN.
  ///
  /// [pin] The PIN to verify.
  /// Returns true if PIN is correct.
  Future<bool> verifyPin(String pin);

  /// Deletes the stored PIN, disabling PIN authentication.
  Future<void> deletePin();

  /// Performs biometric authentication with optional reason.
  ///
  /// [reason] Optional reason to show in biometric prompt.
  /// Returns true if authentication was successful.
  Future<bool> authenticateWithBiometrics({String? reason});

  /// Checks if privacy guard (background blur) is enabled.
  ///
  /// Returns true if privacy guard is active.
  Future<bool> isPrivacyGuardEnabled();

  /// Enables or disables privacy guard.
  ///
  /// [enabled] Whether to enable privacy guard.
  Future<void> setPrivacyGuardEnabled(bool enabled);

  /// Gets the background lock timeout in seconds.
  ///
  /// Returns how many seconds after background before requiring re-authentication.
  Future<int> getBackgroundLockTimeoutSeconds();

  /// Sets the background lock timeout.
  ///
  /// [seconds] Timeout in seconds before requiring re-authentication.
  Future<void> setBackgroundLockTimeoutSeconds(int seconds);

  /// Gets the timestamp when app last went to background.
  ///
  /// Returns null if app hasn't been backgrounded.
  Future<int?> getLastBackgroundTime();

  /// Sets the timestamp when app went to background.
  ///
  /// [timestampMillis] Current timestamp in milliseconds.
  Future<void> setLastBackgroundTime(int timestampMillis);

  /// Clears the stored background timestamp.
  Future<void> clearLastBackgroundTime();

  /// Gets the end time for current lockout period.
  ///
  /// Returns null if not currently locked out.
  Future<int?> getLockoutEndTime();

  /// Gets the current lockout level (number of previous lockouts).
  ///
  /// Higher levels result in longer lockout durations.
  Future<int> getLockoutLevel();

  /// Saves lockout state after failed authentication attempts.
  ///
  /// [level] The lockout level (affects duration).
  /// [endTime] When the lockout period ends (timestamp in milliseconds).
  Future<void> saveLockoutState(int level, int endTime);

  /// Clears all lockout state after successful authentication.
  Future<void> clearLockoutState();
}
