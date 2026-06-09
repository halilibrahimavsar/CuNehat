/// Unified Flutter Features - A comprehensive package of reusable UI components
/// and feature modules for Flutter applications.
///
/// This package provides:
/// - Shared UI components: snackbar, dialog, glass button/surface, date picker/range picker
/// - Feature modules: internet connection monitoring, 2D slider navigation
/// - Single entry point for easy imports
///
/// Quick Start:
/// 1. Add to pubspec.yaml:
/// ```yaml
/// dependencies:
///   unified_flutter_features:
///     path: /path/to/unified_flutter_features
/// ```
///
/// 2. Import and use:
/// ```dart
/// import 'package:unified_flutter_features/unified_flutter_features.dart';
///
/// // Show a success snackbar
/// IboSnackbar.showSuccess(context, 'Operation successful!');
///
/// // Show a confirmation dialog
/// final confirmed = await IboDialog.showConfirmation(
///   context,
///   'Confirm',
///   'Do you confirm this action?',
/// );
///
/// // Use connection monitor
/// BlocProvider(
///   create: (_) => ConnectionCubit(),
///   child: ConnectionSnackbarHandler(
///     child: YourPage(),
///   ),
/// )
/// ```
library;

// Core constants and utilities
export 'core/constants/app_colors.dart';
export 'core/constants/app_spacing.dart';
export 'core/constants/app_strings.dart';
export 'core/texts/texts.dart';

// Shared Features (UI components)
export 'shared_features.dart';

// Feature-specific top-level exports
export 'amount_visibility.dart';
export 'connection_monitor.dart';
export 'local_auth.dart';
export 'slider_2d_navigation.dart';
