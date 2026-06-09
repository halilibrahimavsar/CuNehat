# Migration Guide: v1 -> v2

## Import Path Updates

Preferred top-level imports:

```dart
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:unified_flutter_features/shared_features.dart';
import 'package:unified_flutter_features/connection_monitor.dart';
import 'package:unified_flutter_features/local_auth.dart';
import 'package:unified_flutter_features/amount_visibility.dart';
import 'package:unified_flutter_features/slider_2d_navigation.dart';
```

`shared_features/shared_features.dart` is still supported for now but is no longer the preferred entrypoint.

## Connection State Rename

New canonical type:

- `ConnectionMonitorState`

Compatibility alias retained for migration window:

- `MyConnectionState`

You can migrate gradually without immediate breaks.

## Slider Entrypoint

Preferred path:

- `features/slider_2d_navigation/dynamic_slider.dart`

Legacy path still works:

- `features/slider_2d_navigation/widgets/dynamic_slider_button.dart`

## Local Auth Storage

Recommended:

- `SecureLocalAuthRepository`

Legacy/deprecated:

- `SharedPrefsLocalAuthRepository`

One-time migration:

```dart
final repo = SecureLocalAuthRepository(prefs: prefs);
await repo.migrateLegacyPinFromSharedPreferences();
```

## Typed Text Configs

New typed text configs with English defaults:

- `ConnectionTexts`
- `LocalAuthTexts`
- `DialogTexts`
- `DatePickerTexts`
- `DateRangePickerTexts`
- `SnackbarTexts`

Pass these into corresponding APIs to localize/customize without localization delegates.

## Rollout Policy

- v2.0.0: adapters and deprecated APIs kept.
- v2.1.x: migration window continues with deprecation warnings.
- v3.0.0: planned removal of deprecated v1 adapters.
