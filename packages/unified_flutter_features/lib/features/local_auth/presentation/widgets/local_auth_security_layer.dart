import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/local_auth_repository.dart';
import 'local_auth_background_lock.dart';
import '../../../../shared_features/privacy_guard/ibo_privacy_guard.dart';

/// Controller for refreshing local auth security layer settings.
///
/// This controller allows manual refresh of security settings when
/// authentication configurations change (e.g., enabling/disabling
/// privacy guard or background lock).
///
/// Example:
/// ```dart
/// final controller = LocalAuthSecurityController();
///
/// // When settings change:
/// controller.refresh();
/// ```
class LocalAuthSecurityController extends ChangeNotifier {
  /// Notifies listeners to refresh security settings.
  void refresh() => notifyListeners();
}

/// A comprehensive security layer that combines privacy guard and background lock.
///
/// This widget provides dual protection:
/// 1. Privacy guard - Blurs content when app is backgrounded
/// 2. Background lock - Requires re-authentication when app returns from background
///
/// Use [controller] to refresh security settings after configuration changes.
///
/// Example usage:
/// ```dart
/// LocalAuthSecurityLayer(
///   repository: context.read<LocalAuthRepository>(),
///   controller: _securityController,
///   child: YourAppContent(),
/// )
///
/// // Later, refresh settings after toggles:
/// _securityController.refresh();
/// ```
class LocalAuthSecurityLayer extends StatefulWidget {
  /// Repository for authentication and security settings.
  final LocalAuthRepository repository;

  /// The child widget to protect with security layer.
  final Widget child;

  /// Optional controller to refresh security settings.
  final LocalAuthSecurityController? controller;

  /// Privacy guard overlay styling.
  final PrivacyGuardOverlayStyle privacyGuardStyle;

  /// App lifecycle states that trigger privacy guard.
  final Set<AppLifecycleState> privacyBlurOn;

  /// Animation duration for privacy guard transitions.
  final Duration privacyGuardAnimationDuration;

  /// Animation curve for privacy guard transitions.
  final Curve privacyGuardAnimationCurve;

  /// Optional custom builder for privacy guard overlay.
  final PrivacyGuardOverlayBuilder? privacyGuardOverlayBuilder;

  const LocalAuthSecurityLayer({
    super.key,
    required this.repository,
    required this.child,
    this.controller,
    this.privacyGuardStyle = const PrivacyGuardOverlayStyle(),
    this.privacyBlurOn = const {
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
    },
    this.privacyGuardAnimationDuration = const Duration(milliseconds: 180),
    this.privacyGuardAnimationCurve = Curves.easeOut,
    this.privacyGuardOverlayBuilder,
  });

  @override
  State<LocalAuthSecurityLayer> createState() => _LocalAuthSecurityLayerState();
}

class _LocalAuthSecurityLayerState extends State<LocalAuthSecurityLayer> {
  bool _privacyGuardEnabled = true;
  StreamSubscription<void>? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    _loadPrivacyGuard();
    widget.controller?.addListener(_loadPrivacyGuard);
    _listenToSettingsChanges();
  }

  @override
  void didUpdateWidget(covariant LocalAuthSecurityLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _loadPrivacyGuard();
      _cancelSettingsSubscription();
      _listenToSettingsChanges();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_loadPrivacyGuard);
      widget.controller?.addListener(_loadPrivacyGuard);
    }
  }

  @override
  void dispose() {
    _cancelSettingsSubscription();
    widget.controller?.removeListener(_loadPrivacyGuard);
    super.dispose();
  }

  void _listenToSettingsChanges() {
    _settingsSubscription = widget.repository.settingsChanges.listen((_) {
      if (mounted) {
        _loadPrivacyGuard();
      }
    });
  }

  void _cancelSettingsSubscription() {
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
  }

  Future<void> _loadPrivacyGuard() async {
    try {
      final enabled = await widget.repository.isPrivacyGuardEnabled();
      if (!mounted) return;
      if (_privacyGuardEnabled != enabled) {
        setState(() => _privacyGuardEnabled = enabled);
      }
    } catch (_) {
      // Keep previous state on error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrivacyGuard(
      enabled: _privacyGuardEnabled,
      blurOn: widget.privacyBlurOn,
      style: widget.privacyGuardStyle,
      animationDuration: widget.privacyGuardAnimationDuration,
      animationCurve: widget.privacyGuardAnimationCurve,
      overlayBuilder: widget.privacyGuardOverlayBuilder,
      child: LocalAuthBackgroundLock(
        repository: widget.repository,
        child: widget.child,
      ),
    );
  }
}
