# Security Features

This package includes two security-related features to help protect sensitive user data and provide secure authentication.

## Features

### 1. Privacy Guard

A widget that automatically blurs sensitive content when the app goes to background, preventing sensitive information from being visible in app switchers or screenshots.

#### Usage

```dart
import 'package:unified_flutter_features/shared_features.dart';

PrivacyGuard(
  enabled: true, // Optional, defaults to true
  child: YourSensitiveWidget(),
)
```

#### With Local Auth (Recommended)

If you use the Local Auth feature, you can wrap the entire page with
`LocalAuthSecurityLayer` to automatically combine Privacy Guard and
background lock behavior.

```dart
final prefs = await SharedPreferences.getInstance();
final repo = SecureLocalAuthRepository(prefs: prefs);

LocalAuthSecurityLayer(
  repository: repo,
  child: YourAppOrPage(),
)
```

#### Features

- Automatically detects app lifecycle changes
- Applies blur effect when app is not in foreground (inactive/paused)
- Shows a lock icon with semi-transparent overlay
- Can be enabled/disabled via the `enabled` parameter
- Uses `WidgetsBindingObserver` for lifecycle monitoring

#### Parameters

- `child`: The widget to protect (required)
- `enabled`: Whether privacy protection is active (optional, defaults to true)

### 2. Local Authentication

A comprehensive local authentication system supporting both biometric (fingerprint/face) and PIN-based authentication with security features like lockout mechanisms.

#### Components

- **LocalAuthLoginBloc**: BLoC for managing authentication flow
- **LocalAuthSettingsBloc**: BLoC for managing PIN/biometric settings
- **BiometricAuthPage**: Complete UI for PIN/biometric authentication
- **Security states and events**: For handling different auth scenarios

#### Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/shared_features.dart';

// In your app
final prefs = await SharedPreferences.getInstance();
final repo = SecureLocalAuthRepository(prefs: prefs);

RepositoryProvider.value(
  value: repo,
  child: BlocProvider(
    create: (context) => LocalAuthLoginBloc(
      repository: context.read<LocalAuthRepository>(),
    ),
    child: BiometricAuthPage(
    onSuccess: () {
      // Navigate to authenticated content
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthenticatedContent()),
      );
    },
    onLogout: () {
      // Handle logout
      Navigator.pop(context);
    },
  ),
  ),
)
```

#### Features

- **PIN Authentication**: 4-digit PIN with visual feedback
- **Biometric Support**: Fingerprint and face authentication
- **Security Lockout**: Progressive lockout after failed attempts (3, 5, 10 attempts)
- **Visual Feedback**: Shake animation on wrong PIN, haptic feedback
- **Timer Display**: Shows remaining lockout time
- **State Management**: Complete BLoC implementation with states and events

#### Security States

- `LoginLoadStatus`: initial, loading, success, error
- `SettingsStatus`: initial, loading, success, error
- `AuthStatus`: initial, loading, authenticated, failure, lockedOut

#### Lockout Mechanism

- **3 failed attempts**: 30 seconds lockout
- Each lockout increases the lockout level
- Next lockouts: 2 minutes, 5 minutes, then 1000+ seconds

#### UI Features

- Numpad with haptic feedback
- PIN dots with fill animation
- Biometric button when available
- Lockout timer display
- Shake animation on authentication failure
- Logout button in app bar

## Implementation Notes

### Privacy Guard

- Uses `ImageFilter.blur` with sigmaX/Y of 15 for strong blur effect
- Semi-transparent overlay (0.5 alpha) with lock icon
- Automatically handles app lifecycle state changes
- No additional dependencies required

### Local Authentication

- Uses `shared_preferences` for PIN/flags and `local_auth` for biometrics
- Uses `flutter_bloc` for state management
- Includes comprehensive error handling and user feedback
- Timer-based lockout system with automatic recovery

## Dependencies

Both features require:
- `flutter_bloc`: For state management (Local Auth)
- `shared_preferences` and `local_auth` for Local Auth
- No additional dependencies for Privacy Guard

## Integration

To use these features in your project:

1. Import the shared_features package:
   ```dart
   import 'package:unified_flutter_features/shared_features.dart';
   ```

2. For Privacy Guard, wrap sensitive widgets:
   ```dart
   PrivacyGuard(child: sensitiveContent)
   ```

3. For Local Auth, provide `LocalAuthRepository` and `LocalAuthLoginBloc`:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   final repo = SecureLocalAuthRepository(prefs: prefs);

   RepositoryProvider.value(
     value: repo,
     child: BlocProvider(
       create: (context) => LocalAuthLoginBloc(
         repository: context.read<LocalAuthRepository>(),
       ),
       child: BiometricAuthPage(...)
     ),
   )
   ```

## Platform Setup (Local Auth)

### Android
- Add `USE_BIOMETRIC` (or `USE_FINGERPRINT`) permission in `AndroidManifest.xml`.
- Ensure your app targets at least Android 6.0 (API 23).

### iOS
- Add `NSFaceIDUsageDescription` to `Info.plist`.

## Security Best Practices

- Always enable Privacy Guard for screens showing sensitive financial or personal data
- Use biometric authentication when available for better UX
- Consider implementing additional security measures like session timeout
- Test the lockout mechanism thoroughly to prevent brute force attacks
