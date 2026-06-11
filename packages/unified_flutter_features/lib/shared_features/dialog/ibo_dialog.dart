import 'package:flutter/material.dart';
import '../../core/texts/dialog_texts.dart';
import '../common/ibo_glass_surface.dart';

class IboDialogStyle {
  final IboGlassStyle glassStyle;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry actionsPadding;
  final double actionsSpacing;
  final MainAxisAlignment actionsAlignment;
  final ButtonStyle? confirmButtonStyle;
  final ButtonStyle? cancelButtonStyle;
  final Duration transitionDuration;
  final Curve transitionCurve;

  const IboDialogStyle({
    this.glassStyle = const IboGlassStyle(
      borderRadius: BorderRadius.all(Radius.circular(24)),
      padding: EdgeInsets.all(18),
    ),
    this.titleStyle,
    this.contentStyle,
    this.contentPadding = const EdgeInsets.only(top: 8),
    this.actionsPadding = const EdgeInsets.only(top: 16),
    this.actionsSpacing = 10,
    this.actionsAlignment = MainAxisAlignment.end,
    this.confirmButtonStyle,
    this.cancelButtonStyle,
    this.transitionDuration = const Duration(milliseconds: 180),
    this.transitionCurve = Curves.easeOutCubic,
  });

  IboDialogStyle copyWith({
    IboGlassStyle? glassStyle,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? actionsPadding,
    double? actionsSpacing,
    MainAxisAlignment? actionsAlignment,
    ButtonStyle? confirmButtonStyle,
    ButtonStyle? cancelButtonStyle,
    Duration? transitionDuration,
    Curve? transitionCurve,
  }) {
    return IboDialogStyle(
      glassStyle: glassStyle ?? this.glassStyle,
      titleStyle: titleStyle ?? this.titleStyle,
      contentStyle: contentStyle ?? this.contentStyle,
      contentPadding: contentPadding ?? this.contentPadding,
      actionsPadding: actionsPadding ?? this.actionsPadding,
      actionsSpacing: actionsSpacing ?? this.actionsSpacing,
      actionsAlignment: actionsAlignment ?? this.actionsAlignment,
      confirmButtonStyle: confirmButtonStyle ?? this.confirmButtonStyle,
      cancelButtonStyle: cancelButtonStyle ?? this.cancelButtonStyle,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      transitionCurve: transitionCurve ?? this.transitionCurve,
    );
  }
}

/// A customizable dialog widget with glass effect styling and predefined dialog types.
///
/// Example usage:
/// ```dart
/// final confirmed = await IboDialog.showConfirmation(
///   context,
///   'Confirm',
///   'Do you confirm this action?',
/// );
///
/// final text = await IboDialog.showTextInput(
///   context,
///   'Note',
///   'Enter something',
/// );
///
/// await IboDialog.showInfo(context, 'Info', 'Operation completed');
/// ```
class IboDialog {
  static bool _isLoadingDialogVisible = false;
  static BuildContext? _loadingDialogContext;
  static bool _loadingDialogUsesRootNavigator = true;

  /// Shows a confirmation dialog with OK and Cancel buttons.
  ///
  /// [context] The build context to show the dialog in.
  /// [title] The dialog title.
  /// [message] The confirmation message.
  /// [confirmText] Text for the confirm button (default: 'Confirm').
  /// [cancelText] Text for the cancel button (default: 'Cancel').
  /// [barrierDismissible] Whether dialog can be dismissed by tapping outside.
  /// [style] Custom styling options.
  /// [icon] Optional icon to display in the dialog.
  ///
  /// Returns true if confirmed, false if cancelled, null if dismissed.
  static Future<bool?> showConfirmation(
    BuildContext context,
    String title,
    String message, {
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
    IboDialogStyle? style,
    Widget? icon,
    DialogTexts texts = const DialogTexts(),
  }) async {
    final resolvedStyle = style ?? const IboDialogStyle();
    return _showGlassDialog<bool>(
      context,
      barrierDismissible: barrierDismissible,
      style: resolvedStyle,
      child: Builder(
        builder: (context) => _buildDialogBody(
          context: context,
          title: title,
          content: Text(
            message,
            style: resolvedStyle.contentStyle ??
                TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.9),
                  fontSize: 14,
                ),
          ),
          icon: icon,
          actions: [
            TextButton(
              style: resolvedStyle.cancelButtonStyle,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText ?? texts.cancelText),
            ),
            TextButton(
              style: resolvedStyle.confirmButtonStyle,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText ?? texts.confirmText),
            ),
          ],
          style: resolvedStyle,
        ),
      ),
    );
  }

  /// Shows an info dialog with a single close button.
  ///
  /// [context] The build context to show the dialog in.
  /// [title] The dialog title.
  /// [message] The info message to display.
  /// [closeText] Text for the close button (default: 'OK').
  /// [barrierDismissible] Whether dialog can be dismissed by tapping outside.
  /// [style] Custom styling options.
  /// [icon] Optional icon to display in the dialog.
  static Future<void> showInfo(
    BuildContext context,
    String title,
    String message, {
    String? closeText,
    bool barrierDismissible = true,
    IboDialogStyle? style,
    Widget? icon,
    DialogTexts texts = const DialogTexts(),
  }) async {
    final resolvedStyle = style ?? const IboDialogStyle();
    await _showGlassDialog<void>(
      context,
      barrierDismissible: barrierDismissible,
      style: resolvedStyle,
      child: Builder(
        builder: (context) => _buildDialogBody(
          context: context,
          title: title,
          content: Text(
            message,
            style: resolvedStyle.contentStyle ??
                TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.9),
                  fontSize: 14,
                ),
          ),
          icon: icon,
          actions: [
            TextButton(
              style: resolvedStyle.confirmButtonStyle,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(closeText ?? texts.okText),
            ),
          ],
          style: resolvedStyle,
        ),
      ),
    );
  }

  /// Shows a text input dialog with a text field and confirm/cancel buttons.
  ///
  /// [context] The build context to show the dialog in.
  /// [title] The dialog title.
  /// [hintText] Hint text for the input field.
  /// [initialValue] Initial value for the text field.
  /// [confirmText] Text for the confirm button (default: 'Confirm').
  /// [cancelText] Text for the cancel button (default: 'Cancel').
  /// [keyboardType] Keyboard type for the text field.
  /// [maxLines] Maximum lines for the text field.
  /// [obscureText] Whether to obscure the text (for passwords).
  /// [style] Custom styling options.
  /// [icon] Optional icon to display in the dialog.
  ///
  /// Returns the entered text or null if cancelled.
  static Future<String?> showTextInput(
    BuildContext context,
    String title,
    String hintText, {
    String? initialValue,
    String? confirmText,
    String? cancelText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool obscureText = false,
    IboDialogStyle? style,
    Widget? icon,
    DialogTexts texts = const DialogTexts(),
  }) async {
    final controller = TextEditingController(text: initialValue);
    final resolvedStyle = style ?? const IboDialogStyle();
    try {
      return await _showGlassDialog<String>(
        context,
        barrierDismissible: true,
        style: resolvedStyle,
        child: Builder(
          builder: (context) => _buildDialogBody(
            context: context,
            title: title,
            icon: icon,
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              keyboardType: keyboardType,
              maxLines: maxLines,
              obscureText: obscureText,
              autofocus: true,
            ),
            actions: [
              TextButton(
                style: resolvedStyle.cancelButtonStyle,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(cancelText ?? texts.cancelText),
              ),
              TextButton(
                style: resolvedStyle.confirmButtonStyle,
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: Text(confirmText ?? texts.confirmText),
              ),
            ],
            style: resolvedStyle,
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  static Future<T?> showCustomDialog<T>(
    BuildContext context, {
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    IboDialogStyle? style,
    String? title,
    Widget? icon,
  }) async {
    final resolvedStyle = style ?? const IboDialogStyle();
    return await _showGlassDialog<T>(
      context,
      barrierDismissible: barrierDismissible,
      style: resolvedStyle,
      child: Builder(
        builder: (context) => _buildDialogBody(
          context: context,
          title: title,
          icon: icon,
          content: content,
          actions: actions ?? const [],
          style: resolvedStyle,
        ),
      ),
    );
  }

  /// Shows a loading dialog with a progress indicator and message.
  ///
  /// [context] The build context to show the dialog in.
  /// [message] The loading message to display (default: 'Loading...').
  /// [barrierDismissible] Whether dialog can be dismissed (default: false).
  /// [style] Custom styling options.
  static Future<void> showLoadingDialog(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
    bool useRootNavigator = true,
    IboDialogStyle? style,
    DialogTexts texts = const DialogTexts(),
  }) async {
    if (_isLoadingDialogVisible) return;
    final resolvedStyle = style ?? const IboDialogStyle();
    _isLoadingDialogVisible = true;
    _loadingDialogUsesRootNavigator = useRootNavigator;
    try {
      await _showGlassDialog<void>(
        context,
        barrierDismissible: barrierDismissible,
        useRootNavigator: useRootNavigator,
        onDialogContext: (dialogContext) {
          _loadingDialogContext = dialogContext;
        },
        style: resolvedStyle,
        child: Builder(
          builder: (context) => _buildDialogBody(
            context: context,
            title: null,
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message ?? texts.loadingMessage,
                    style: resolvedStyle.contentStyle ??
                        TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                  ),
                ),
              ],
            ),
            actions: const [],
            style: resolvedStyle,
          ),
        ),
      );
    } finally {
      _isLoadingDialogVisible = false;
      _loadingDialogContext = null;
    }
  }

  /// Dismisses the currently shown loading dialog.
  ///
  /// [context] The build context containing the loading dialog.
  static void dismissLoadingDialog(
    BuildContext context, {
    bool rootNavigator = true,
  }) {
    if (!_isLoadingDialogVisible) return;
    final loadingContext = _loadingDialogContext;
    if (loadingContext != null) {
      final loadingNavigator = Navigator.of(
        loadingContext,
        rootNavigator: _loadingDialogUsesRootNavigator,
      );
      if (loadingNavigator.canPop()) {
        loadingNavigator.pop();
      }
      return;
    }

    final fallbackNavigator =
        Navigator.of(context, rootNavigator: rootNavigator);
    if (fallbackNavigator.canPop()) {
      fallbackNavigator.pop();
    }
  }

  static Future<T?> _showGlassDialog<T>(
    BuildContext context, {
    required Widget child,
    required IboDialogStyle style,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    ValueChanged<BuildContext>? onDialogContext,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: style.transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        onDialogContext?.call(context);
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: IboGlassSurface(
                  style: style.glassStyle,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: style.transitionCurve,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  static Widget _buildDialogBody({
    required BuildContext context,
    required Widget content,
    required List<Widget> actions,
    required IboDialogStyle style,
    String? title,
    Widget? icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null || icon != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: icon,
                ),
              if (title != null)
                Expanded(
                  child: Text(
                    title,
                    style: style.titleStyle ??
                        TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
            ],
          ),
        Padding(
          padding: style.contentPadding,
          child: DefaultTextStyle(
            style: style.contentStyle ??
                TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.9),
                  fontSize: 14,
                ),
            child: content,
          ),
        ),
        if (actions.isNotEmpty)
          Padding(
            padding: style.actionsPadding,
            child: Row(
              mainAxisAlignment: style.actionsAlignment,
              children: _withSpacing(actions, style.actionsSpacing),
            ),
          ),
      ],
    );
  }

  static List<Widget> _withSpacing(List<Widget> children, double spacing) {
    if (children.length <= 1) return children;
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i != children.length - 1) {
        spaced.add(SizedBox(width: spacing));
      }
    }
    return spaced;
  }
}
