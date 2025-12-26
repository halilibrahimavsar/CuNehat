import 'dart:ui';
import 'package:flutter/material.dart';

class PrivacyGuard extends StatefulWidget {
  final Widget child;
  final bool enabled; // Güvenlik açık mı kontrolü

  const PrivacyGuard({
    super.key,
    required this.child,
    this.enabled = true,
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Eğer güvenlik kapalıysa işlem yapma
    if (!widget.enabled) return;

    // Uygulama aktif değilse (inactive veya paused) bulanıklaştır
    final shouldBlur = state != AppLifecycleState.resumed;

    if (_shouldBlur != shouldBlur) {
      setState(() {
        _shouldBlur = shouldBlur;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Güvenlik kapalıysa direkt içeriği göster
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        if (_shouldBlur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Theme.of(context)
                    .scaffoldBackgroundColor
                    .withValues(alpha: 0.5),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 80,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
