import 'package:flutter/material.dart';
import 'package:unified_flutter_features/core/texts/connection_texts.dart';
import 'package:unified_flutter_features/features/connection_monitor/connection_state.dart';

class ConnectionIndicatorWidget extends StatelessWidget {
  final ConnectionMonitorState connectionState;
  final Widget? child;
  final bool showIndicator;
  final Widget connectedWidget;
  final Widget disconnectedWidget;
  final Widget checkingWidget;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;
  final Duration animationDuration;

  const ConnectionIndicatorWidget({
    super.key,
    required this.connectionState,
    this.child,
    this.showIndicator = true,
    required this.connectedWidget,
    required this.disconnectedWidget,
    required this.checkingWidget,
    this.width,
    this.height,
    this.padding,
    this.decoration,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    Widget indicator;

    switch (connectionState.status) {
      case ConnectionStatus.connected:
        indicator = connectedWidget;
        break;
      case ConnectionStatus.disconnected:
        indicator = disconnectedWidget;
        break;
      case ConnectionStatus.checking:
        indicator = checkingWidget;
        break;
    }

    return AnimatedSwitcher(
      duration: animationDuration,
      child: Column(
        key: ValueKey(connectionState.status),
        children: [
          if (showIndicator)
            Container(
              width: width,
              height: height,
              padding: padding,
              decoration: decoration,
              child: indicator,
            ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class DefaultConnectionIndicator extends StatelessWidget {
  final ConnectionMonitorState connectionState;
  final bool showText;
  final Color? connectedColor;
  final Color? disconnectedColor;
  final Color? checkingColor;
  final TextStyle? textStyle;
  final ConnectionTexts texts;

  const DefaultConnectionIndicator({
    super.key,
    required this.connectionState,
    this.showText = true,
    this.connectedColor,
    this.disconnectedColor,
    this.checkingColor,
    this.textStyle,
    this.texts = const ConnectionTexts(),
  });

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    String text = texts.unknownConnectionType;
    IconData icon = Icons.help;

    switch (connectionState.status) {
      case ConnectionStatus.connected:
        color = connectedColor ?? Colors.green;
        text = connectionState.message ?? texts.connectedMessage;
        icon = Icons.wifi;
        break;
      case ConnectionStatus.disconnected:
        color = disconnectedColor ?? Colors.red;
        text = connectionState.message ?? texts.disconnectedMessage;
        icon = Icons.wifi_off;
        break;
      case ConnectionStatus.checking:
        color = checkingColor ?? Colors.orange;
        text = connectionState.message ?? texts.checkingMessage;
        icon = Icons.sync;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connectionState.status == ConnectionStatus.checking)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(icon, color: color, size: 20),
          if (showText) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: textStyle?.copyWith(color: color) ??
                    TextStyle(color: color, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ConnectionStatusBadge extends StatelessWidget {
  final ConnectionMonitorState connectionState;
  final double size;
  final Color? connectedColor;
  final Color? disconnectedColor;
  final Color? checkingColor;

  const ConnectionStatusBadge({
    super.key,
    required this.connectionState,
    this.size = 12,
    this.connectedColor,
    this.disconnectedColor,
    this.checkingColor,
  });

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;

    switch (connectionState.status) {
      case ConnectionStatus.connected:
        color = connectedColor ?? Colors.green;
        break;
      case ConnectionStatus.disconnected:
        color = disconnectedColor ?? Colors.red;
        break;
      case ConnectionStatus.checking:
        color = checkingColor ?? Colors.orange;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
