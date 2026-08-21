# Changelog

## 3.0.0 - 2026-08-21

### Changed (BREAKING)

- `SliderKnob`: `showUpArrow` / `showDownArrow` kaldırıldı, yerine
  `selectedIndex` geldi. Dikey chevron'lar komşu etiketle çakışıyordu
  (ok y 65–93, etiket ~85–92) ve kaç alt sayfa olduğunu söylemiyordu;
  yerlerini hapın sağ iç kenarındaki nokta rayı aldı.
- `SliderKnob`: `metrics` (`SliderMetrics`) artık zorunlu; sabit
  100/50/130/42 ölçüleri kaldırıldı.
- `SliderKnob.onHorizontalDragEnd` artık `GestureDragEndCallback` (hız
  okunabilsin diye).
- `VerticalCarousel`: `itemExtent` ve `height` zorunlu parametre oldu.
- `SliderConfig.carouselTotalHeight` / `carouselItemHeight` kaldırıldı.
  `carouselTotalHeight` ölü koddu: çark `Positioned.fill` ile sıkı 100 px
  alıyordu, 168'lik değer hiç uygulanmıyordu.
- `SliderConfig.knobLabelStyle` artık açık `height` taşıyor; taşımadığında
  Material 3'ün `bodyMedium`'undan `height: 1.43` miras alıp 16 px'lik
  puntoyu 23 px'lik satır kutusuna çeviriyordu.

### Added

- Çark oturma eğrisi: `Curves.linear` → `Curves.easeOutCubic` (260 ms).
  (`SliderConfig.animationDuration` 380 ms'e çekilmişti; cihazda fazla hızlı
  bulunup 600 ms'de bırakıldı.)
- `SliderMetrics`: kaydırıcı ölçülerini sistem yazı ölçeğinden türetir.
  Değişmezler: komşu etiket ne hapla çakışır ne viewport'tan taşar; punto
  tabana inmeden hiçbir etiket kesilmez.
- `DynamicSlider.peekStates` / `onPeekPlayed`: dikey navigasyonu bir kez
  tanıtan "göz kırpma" animasyonu.
- `resolveDragTarget` / `flingDirection` (`helpers/drag_settle.dart`):
  sürükleme bitişinde konum + HIZ. Eskiden yalnız konuma bakılıyor ve kısa
  yol almış hızlı fiske yutuluyordu.

### Fixed

- Ölçülen üç kesilme: komşu etiketin altı viewport kenarında kesiliyordu
  (x1.0'da 4,7 px, x2.0'da 17,6 px), ana etiket ellipsis'e düşüyordu
  (TR x1.8'den, EN "TRANSACTIONS" x1.15'ten), ShaderMask'in beyaz odak bandı
  satır kutusundan dardı (16 px'e karşı 23 px) ve `İ`nin noktası griye
  düşüyordu.
- Etiket ölçümü artık ortamdaki `DefaultTextStyle`'ın font ailesini kullanıyor;
  çıplak `TextPainter` ölçümüyle boyama sessizce ayrışabiliyordu.
- Jest başına tek dokunsal geri bildirim (eskiden üç ayrı titreşim).
- Komşu etiketin opaklığı 0.6 → 0.85: dekoratif altyazı gibi değil,
  dokunulabilir bir öğe gibi okunuyor.

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
