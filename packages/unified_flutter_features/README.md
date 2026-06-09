# Unified Flutter Features

A reusable Flutter package with shared UI components and feature modules.

## Highlights

- Shared UI components: snackbar, dialog, glass surfaces/buttons, date pickers
- Feature modules: connection monitor, local auth, amount visibility, 2D slider
- Top-level stable imports for v2
- Flutter 3.0-compatible API usage

## Installation

```yaml
dependencies:
  unified_flutter_features:
    path: /path/to/unified_flutter_features
```

## Preferred Imports (v2)

```dart
import 'package:unified_flutter_features/unified_flutter_features.dart';

// or feature-level imports:
import 'package:unified_flutter_features/shared_features.dart';
import 'package:unified_flutter_features/connection_monitor.dart';
import 'package:unified_flutter_features/local_auth.dart';
import 'package:unified_flutter_features/amount_visibility.dart';
import 'package:unified_flutter_features/slider_2d_navigation.dart';
```

## Feature Overview

### Shared UI

- `IboSnackbar`
- `IboDialog`
- `IboGlassSurface`, `IboGlassButton`, `IboLoadingButton`
- `IboDatePicker`, `IboDateRangePicker`
- `PrivacyGuard`

### Connection Monitor

- `ConnectionCubit`
- `ConnectionMonitorState` (`MyConnectionState` kept as compatibility typedef)
- `ConnectionSnackbarHandler`
- `ConnectionNotificationHandler`

### Local Auth

- `LocalAuthRepository`
- `SecureLocalAuthRepository` (recommended)
- `SharedPrefsLocalAuthRepository` (deprecated migration bridge)
- `LocalAuthSettingsWidget`
- `LocalAuthSecurityLayer`
- `BiometricAuthPage`

### Amount Visibility

- `AmountVisibilityCubit`
- `AmountDisplay`, `SignedAmountDisplay`
- `AmountVisibilityButton`, `AmountVisibilityObfuscator`

### 2D Slider Navigation

- `DynamicSlider`
- `SliderState`, `MiniButtonData`, `SubMenuItem`
- `SliderStateHelper`, `SliderConfig`

## Typed Text Configuration

The package provides typed text config classes with English defaults:

- `ConnectionTexts`
- `LocalAuthTexts`
- `DialogTexts`
- `DatePickerTexts`
- `DateRangePickerTexts`
- `SnackbarTexts`

These can be passed to related widgets/services for caller-level localization without a localization delegate requirement.

## Security Note

For production apps, use `SecureLocalAuthRepository` for PIN hash/salt storage. If upgrading from v1 storage, call:

```dart
final repo = SecureLocalAuthRepository(prefs: prefs);
await repo.migrateLegacyPinFromSharedPreferences();
```

## Migration

See `MIGRATION_V2.md` for import path updates, deprecated APIs, and rollout guidance.

## Example App

The runnable demo app is under `example/`.

## License

MIT (see `LICENSE`).
