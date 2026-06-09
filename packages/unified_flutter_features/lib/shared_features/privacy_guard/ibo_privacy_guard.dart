import 'dart:ui';
import 'package:flutter/material.dart';

/// Builder function for creating custom privacy guard overlays.
///
/// [context] The build context for the overlay.
/// [style] The current overlay style configuration.
///
/// Returns a custom widget to display when privacy guard is active.
typedef PrivacyGuardOverlayBuilder = Widget Function(
  BuildContext context,
  PrivacyGuardOverlayStyle style,
);

/// Configuration for the privacy guard overlay appearance.
///
/// Defines how the privacy overlay looks when the app is backgrounded
/// or when sensitive content should be hidden.
@immutable
class PrivacyGuardOverlayStyle {
  /// Blur intensity for the background filter.
  final double blurSigma;

  /// Color overlay for the scrim (semi-transparent background).
  final Color scrimColor;

  /// Icon to display in the overlay center.
  final IconData icon;

  /// Size of the displayed icon.
  final double iconSize;

  /// Color of the displayed icon.
  final Color iconColor;

  /// Optional title text to display.
  final String? title;

  /// Optional subtitle text to display.
  final String? subtitle;

  /// Custom text style for the title.
  final TextStyle? titleStyle;

  /// Custom text style for the subtitle.
  final TextStyle? subtitleStyle;

  /// Padding around the overlay content.
  final EdgeInsets padding;

  /// Border radius for the overlay container.
  final BorderRadius borderRadius;

  const PrivacyGuardOverlayStyle({
    this.blurSigma = 18,
    this.scrimColor = const Color(0x80000000),
    this.icon = Icons.lock_outline_rounded,
    this.iconSize = 72,
    this.iconColor = const Color(0xB3FFFFFF),
    this.title = 'Hidden for privacy',
    this.subtitle = 'Return to the app to continue',
    this.titleStyle,
    this.subtitleStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });
}

/// A privacy protection widget that automatically blurs/hides sensitive content
/// when the app goes to background or specific lifecycle states.
///
/// This widget monitors app lifecycle changes and applies a privacy overlay
/// to prevent sensitive information from being visible in app switchers,
/// screenshots, or when the app is not actively in use.
///
/// Example usage:
/// ```dart
/// PrivacyGuard(
///   enabled: true,
///   blurOn: {
///     AppLifecycleState.paused,
///     AppLifecycleState.inactive,
///   },
///   style: PrivacyGuardOverlayStyle(
///     title: 'App Hidden',
///     subtitle: 'Tap to return',
///     blurSigma: 20,
///   ),
///   child: YourSensitiveContent(),
/// )
/// ```
class PrivacyGuard extends StatefulWidget {
  /// The child widget to protect with privacy guard.
  final Widget child;

  /// Whether privacy guard is enabled or disabled.
  final bool enabled;

  /// Set of app lifecycle states that trigger the privacy overlay.
  final Set<AppLifecycleState> blurOn;

  /// Styling configuration for the privacy overlay.
  final PrivacyGuardOverlayStyle style;

  /// Duration of the show/hide animation.
  final Duration animationDuration;

  /// Animation curve for transitions.
  final Curve animationCurve;

  /// Optional custom builder for the overlay content.
  final PrivacyGuardOverlayBuilder? overlayBuilder;

  const PrivacyGuard({
    super.key,
    required this.child,
    this.enabled = true,
    this.blurOn = const {
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
    },
    this.style = const PrivacyGuardOverlayStyle(),
    this.animationDuration = const Duration(milliseconds: 180),
    this.animationCurve = Curves.easeOut,
    this.overlayBuilder,
  });

  @override
  State<PrivacyGuard> createState() => _PrivacyGuardState();
}

class _PrivacyGuardState extends State<PrivacyGuard>
    with WidgetsBindingObserver {
  bool _shouldBlur = false;

  @override
  void initState() {
    super.initState();
    _syncWithLifecycle();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PrivacyGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.blurOn != widget.blurOn) {
      _syncWithLifecycle();
    }
  }

  void _syncWithLifecycle() {
    final state = WidgetsBinding.instance.lifecycleState;
    final shouldBlur =
        widget.enabled && state != null && widget.blurOn.contains(state);
    if (_shouldBlur != shouldBlur) {
      setState(() {
        _shouldBlur = shouldBlur;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;

    final shouldBlur = widget.blurOn.contains(state);
    if (mounted && _shouldBlur != shouldBlur) {
      setState(() {
        _shouldBlur = shouldBlur;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_shouldBlur,
            child: AnimatedOpacity(
              duration: _shouldBlur ? Duration.zero : widget.animationDuration,
              curve: widget.animationCurve,
              opacity: _shouldBlur ? 1.0 : 0.0,
              child: _PrivacyGuardOverlay(
                key: ValueKey<bool>(_shouldBlur),
                style: widget.style,
                builder: widget.overlayBuilder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivacyGuardOverlay extends StatelessWidget {
  final PrivacyGuardOverlayStyle style;
  final PrivacyGuardOverlayBuilder? builder;

  const _PrivacyGuardOverlay({
    super.key,
    required this.style,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = style.titleStyle ??
        theme.textTheme.titleMedium?.copyWith(
          color: style.iconColor,
          fontWeight: FontWeight.w600,
        );
    final subtitleStyle = style.subtitleStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: style.iconColor.withValues(alpha: 0.8),
        );

    return AbsorbPointer(
      absorbing: true,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: style.blurSigma,
            sigmaY: style.blurSigma,
          ),
          child: ColoredBox(
            color: style.scrimColor,
            child: Center(
              child: builder?.call(context, style) ??
                  Container(
                    padding: style.padding,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.2),
                      borderRadius: style.borderRadius,
                      border: Border.all(
                        color: style.iconColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          size: style.iconSize,
                          color: style.iconColor,
                        ),
                        if (style.title != null) ...[
                          const SizedBox(height: 12),
                          Text(style.title!, style: titleStyle),
                        ],
                        if (style.subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(style.subtitle!, style: subtitleStyle),
                        ],
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
