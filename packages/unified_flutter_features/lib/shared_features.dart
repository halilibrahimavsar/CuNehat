/// Export file for all shared UI components and feature modules.
///
/// Preferred import path:
/// `import 'package:unified_flutter_features/shared_features.dart';`
///
/// This file exports:
/// - Shared UI components (snackbar, dialog, glass button, date pickers, privacy guard)
/// - Connection monitor feature with BLoC state management
/// - Amount visibility feature with obfuscation and persistence
/// - 2D Slider navigation feature with animation support
/// - Local auth feature with biometric and PIN authentication
///
/// Import this file to get access to all shared components and features.
library;

// Shared UI Components
export 'shared_features/snackbar/ibo_snackbar.dart';
export 'shared_features/date_picker/ibo_date_picker.dart';
export 'shared_features/date_range_picker/ibo_date_range_picker.dart';
export 'shared_features/dialog/ibo_dialog.dart';
export 'shared_features/glass_button/ibo_glass_button.dart';
export 'features/amount_visibility/ibo_amount_display.dart';
export 'shared_features/common/ibo_glass_surface.dart';
export 'shared_features/common/ibo_quick_menu_style.dart';
export 'shared_features/privacy_guard/ibo_privacy_guard.dart';

// Connection Monitor Feature
// Monitors internet connectivity using BLoC pattern with connectivity_plus
export 'features/connection_monitor/connection_cubit.dart';
export 'features/connection_monitor/connection_state.dart';
export 'features/connection_monitor/services/connection_notification_service.dart';
export 'features/connection_monitor/services/connection_snackbar_handler.dart';
export 'features/connection_monitor/widgets/connection_indicator_widget.dart';

// Amount Visibility Feature
// Manages amount visibility with BLoC pattern and shared preferences
export 'features/amount_visibility/amount_visibility_cubit.dart';

// 2D Slider Navigation Feature
// Animated slider with state transitions and mini button/sub-menu support
export 'features/slider_2d_navigation/models/slider_models.dart';
export 'features/slider_2d_navigation/dynamic_slider.dart';
export 'features/slider_2d_navigation/widgets/mini_buttons_overlay.dart';
export 'features/slider_2d_navigation/widgets/slider_knob.dart';
export 'features/slider_2d_navigation/widgets/vertical_carousel.dart';

// Local Auth Feature
// Biometric and PIN authentication with BLoC pattern and lockout mechanism
export 'features/local_auth/data/local_auth_repository.dart';
export 'features/local_auth/data/local_auth_migration.dart';
export 'features/local_auth/data/secure_local_auth_repository.dart';
export 'features/local_auth/presentation/bloc/login/local_auth_login_bloc.dart';
export 'features/local_auth/presentation/bloc/login/local_auth_login_event.dart';
export 'features/local_auth/presentation/bloc/login/local_auth_login_state.dart';
export 'features/local_auth/presentation/bloc/settings/local_auth_settings_bloc.dart';
export 'features/local_auth/presentation/bloc/settings/local_auth_settings_event.dart';
export 'features/local_auth/presentation/bloc/settings/local_auth_settings_state.dart';
export 'features/local_auth/presentation/pages/biometric_auth_page.dart';
export 'features/local_auth/presentation/widgets/local_auth_background_lock.dart';
export 'features/local_auth/presentation/widgets/local_auth_security_layer.dart';

// Typed text configurations
export 'core/texts/texts.dart';
