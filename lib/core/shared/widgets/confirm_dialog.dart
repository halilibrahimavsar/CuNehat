import 'dart:async';

import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:flutter/material.dart';

/// Uygulamanın kendi görsel diline (AppSurface/AppCard, blur'suz) uyan
/// paylaşılan onay diyaloğu.
///
/// [danger] onay butonunu tehlike rengine boyar. [countdownSeconds] > 0 ise
/// onay butonu o kadar saniye devre dışı kalır ve geri sayım gösterir —
/// kritik/geri alınamaz eylemler için ikinci adım olarak kullanılır.
class ConfirmDialog {
  const ConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    String? cancelText,
    bool danger = false,
    int countdownSeconds = 0,
  }) async {
    final resolvedCancelText = cancelText ?? context.l10n.iptal;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !danger,
      builder: (_) => _ConfirmDialogView(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: resolvedCancelText,
        danger: danger,
        countdownSeconds: countdownSeconds,
      ),
    );
    return result ?? false;
  }
}

class _ConfirmDialogView extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool danger;
  final int countdownSeconds;

  const _ConfirmDialogView({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.danger,
    required this.countdownSeconds,
  });

  @override
  State<_ConfirmDialogView> createState() => _ConfirmDialogViewState();
}

class _ConfirmDialogViewState extends State<_ConfirmDialogView> {
  late int _remaining = widget.countdownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_remaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _remaining--);
        if (_remaining <= 0) t.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.danger ? scheme.error : scheme.primary;
    final confirmLabel = _remaining > 0
        ? '${widget.confirmText} ($_remaining)'
        : widget.confirmText;

    return AppDialogSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.danger) ...[
                Icon(Icons.warning_rounded, color: accent, size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.message,
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(widget.cancelText),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: widget.danger
                    ? FilledButton.styleFrom(backgroundColor: scheme.error)
                    : null,
                onPressed: _remaining > 0
                    ? null
                    : () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
