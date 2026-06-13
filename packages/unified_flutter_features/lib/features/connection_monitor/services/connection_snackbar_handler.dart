import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/core/texts/connection_texts.dart';
import 'package:unified_flutter_features/features/connection_monitor/connection_cubit.dart';
import 'package:unified_flutter_features/features/connection_monitor/connection_state.dart';

class ConnectionSnackbarHandler extends StatefulWidget {
  final Widget child;
  final bool showSnackbar;
  final Duration? connectedDuration;
  final Duration? disconnectedDuration;
  final String? connectedMessage;
  final String? disconnectedMessage;
  final SnackBarBehavior? behavior;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final ConnectionTexts texts;

  const ConnectionSnackbarHandler({
    super.key,
    required this.child,
    this.showSnackbar = true,
    this.connectedDuration = const Duration(seconds: 2),
    this.disconnectedDuration = const Duration(seconds: 3),
    this.connectedMessage,
    this.disconnectedMessage,
    this.behavior,
    this.backgroundColor,
    this.textStyle,
    this.texts = const ConnectionTexts(),
  });

  @override
  State<ConnectionSnackbarHandler> createState() =>
      _ConnectionSnackbarHandlerState();
}

class _ConnectionSnackbarHandlerState extends State<ConnectionSnackbarHandler> {
  ConnectionMonitorState? lastState;

  String? _localizeMessage(String? msg) {
    if (msg == null) return null;
    if (msg == 'Internet connection is active') {
      return widget.texts.connectedMessage;
    }
    if (msg == 'No internet connection') {
      return widget.texts.disconnectedMessage;
    }
    if (msg == 'Checking connection...') {
      return widget.texts.checkingMessage;
    }
    if (msg.startsWith('Connection check failed')) {
      final error = msg
          .replaceFirst('Connection check failed: ', '')
          .replaceFirst('Connection check failed', '');
      return '${widget.texts.checkFailedPrefix}: $error';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectionCubit, ConnectionMonitorState>(
      listener: (context, state) {
        // The handler lives in MaterialApp.router's builder, so it can be
        // reattached/torn down on route changes. If the cubit emits while this
        // element is deactivated, looking up ScaffoldMessenger.of(context)
        // throws "Looking up a deactivated widget's ancestor is unsafe".
        if (!mounted) return;
        if (!widget.showSnackbar) return;

        if (lastState != null && lastState!.status == state.status) return;

        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;

        messenger.hideCurrentSnackBar();

        final snackbarMargin = EdgeInsets.only(
          bottom: MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom -
              140,
          left: 16,
          right: 16,
        );

        switch (state.status) {
          case ConnectionStatus.connected:
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.wifi, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.connectedMessage ??
                            _localizeMessage(state.message) ??
                            widget.texts.connectedMessage,
                        style: widget.textStyle ??
                            const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: widget.backgroundColor ?? Colors.green,
                behavior: widget.behavior ?? SnackBarBehavior.floating,
                duration:
                    widget.connectedDuration ?? const Duration(seconds: 2),
                margin: snackbarMargin,
                dismissDirection: DismissDirection.up,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
            break;

          case ConnectionStatus.disconnected:
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.disconnectedMessage ??
                            _localizeMessage(state.message) ??
                            widget.texts.disconnectedMessage,
                        style: widget.textStyle ??
                            const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: widget.backgroundColor ?? Colors.red,
                behavior: widget.behavior ?? SnackBarBehavior.floating,
                duration:
                    widget.disconnectedDuration ?? const Duration(seconds: 3),
                margin: snackbarMargin,
                dismissDirection: DismissDirection.up,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                action: SnackBarAction(
                  label: widget.texts.retryActionLabel,
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<ConnectionCubit>().manualCheck();
                  },
                ),
              ),
            );
            break;

          case ConnectionStatus.checking:
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _localizeMessage(state.message) ??
                            widget.texts.checkingMessage,
                        style: widget.textStyle ??
                            const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: widget.backgroundColor ?? Colors.orange,
                behavior: widget.behavior ?? SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                margin: snackbarMargin,
                dismissDirection: DismissDirection.up,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
            break;
        }

        lastState = state;
      },
      child: widget.child,
    );
  }
}
