import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/local_auth_repository.dart';
import '../bloc/login/local_auth_login_bloc.dart';
import '../pages/biometric_auth_page.dart';

/// Background lock widget that shows BiometricAuthPage when locked.
///
/// Simple usage:
/// ```dart
/// LocalAuthBackgroundLock(
///   repository: repo,
///   child: YourContent(),
/// )
/// ```
class LocalAuthBackgroundLock extends StatefulWidget {
  final Widget child;
  final LocalAuthRepository repository;

  const LocalAuthBackgroundLock({
    super.key,
    required this.child,
    required this.repository,
  });

  @override
  State<LocalAuthBackgroundLock> createState() =>
      _LocalAuthBackgroundLockState();
}

class _LocalAuthBackgroundLockState extends State<LocalAuthBackgroundLock>
    with WidgetsBindingObserver {
  bool _shouldShowLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _recordBackgroundTime();
    } else if (state == AppLifecycleState.resumed) {
      _checkLock();
    }
  }

  Future<void> _recordBackgroundTime() async {
    final timeout = await widget.repository.getBackgroundLockTimeoutSeconds();
    if (timeout <= 0) return;

    // Only record if not already recorded
    final existing = await widget.repository.getLastBackgroundTime();
    if (existing != null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await widget.repository.setLastBackgroundTime(now);
  }

  Future<void> _checkLock() async {
    final timeout = await widget.repository.getBackgroundLockTimeoutSeconds();
    if (timeout <= 0) {
      await widget.repository.clearLastBackgroundTime();
      return;
    }

    final lastTime = await widget.repository.getLastBackgroundTime();
    if (lastTime == null) return;

    final elapsed = (DateTime.now().millisecondsSinceEpoch - lastTime) ~/ 1000;
    if (elapsed < timeout) {
      await widget.repository.clearLastBackgroundTime();
      return;
    }

    // Check if any auth method available
    final hasPin = await widget.repository.isPinSet();
    final hasBio = await widget.repository.isBiometricEnabled();
    if (!hasPin && !hasBio) {
      await widget.repository.clearLastBackgroundTime();
      return;
    }

    if (!mounted) return;
    setState(() => _shouldShowLock = true);
  }

  Future<void> _onAuthSuccess() async {
    await widget.repository.clearLastBackgroundTime();
    if (!mounted) return;
    setState(() => _shouldShowLock = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldShowLock) {
      return BlocProvider(
        create: (_) => LocalAuthLoginBloc(repository: widget.repository),
        child: BiometricAuthPage(
          onSuccess: () {
            unawaited(_onAuthSuccess());
          },
          showLogoutButton: false,
        ),
      );
    }
    return widget.child;
  }
}
