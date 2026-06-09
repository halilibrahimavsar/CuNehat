# Changelog

## 2.0.0 - 2026-02-17

### Added

- New top-level barrels:
  - `lib/shared_features.dart`
  - `lib/amount_visibility.dart`
  - `lib/connection_monitor.dart`
  - `lib/local_auth.dart`
  - `lib/slider_2d_navigation.dart`
- Typed text config classes:
  - `ConnectionTexts`, `LocalAuthTexts`, `DialogTexts`, `DatePickerTexts`, `DateRangePickerTexts`, `SnackbarTexts`
- `SecureLocalAuthRepository` with secure PIN storage backend.
- `LocalAuthMigration` helper for one-time PIN migration from shared preferences.
- Canonical slider entrypoint: `lib/features/slider_2d_navigation/dynamic_slider.dart`.
- Root `analysis_options.yaml`.
- CI workflow for analyze/test formatting checks.
- `MIGRATION_V2.md`.

### Changed

- `ConnectionMonitorState` is now the canonical connection state model.
  - Backward compatible alias kept: `typedef MyConnectionState = ConnectionMonitorState`.
- Default user-facing package texts switched to English where hardcoded defaults were used.
- Flutter 3.0 compatibility updates:
  - Replaced `withValues(alpha: ...)` usages.
  - Removed direct `showDragHandle` usage.
  - Removed `AppLifecycleState.hidden` dependency.

### Fixed

- `LocalAuthLoginState.copyWith` nullable clearing behavior (lockout reset path).
- Lockout reset flow now clears persisted lockout state when expired.
- Background lock bypass via logout action in lock screen.
- `DynamicSlider` now handles controller replacement lifecycle safely.
- Vertical drag in slider carousel now clamps offsets to scroll bounds.
- Guarded amount visibility cubit emits after disposal.
- Dialog text input controller disposal and safer loading dialog dismissal path.

### Deprecated

- `SharedPrefsLocalAuthRepository` is deprecated and kept as a migration bridge.
- Legacy deep import path `shared_features/shared_features.dart` remains available; top-level `shared_features.dart` is preferred.
