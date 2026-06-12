import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../shared_features/common/ibo_glass_surface.dart';
import 'package:unified_flutter_features/core/texts/local_auth_texts.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_bloc.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_event.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_state.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/widgets/local_auth_numpad.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/widgets/local_auth_pin_dots.dart';
import '../bloc/local_auth_status.dart';
import '../constants/local_auth_constants.dart';

class BiometricAuthPage extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onLogout;
  final bool showLogoutButton;
  final LocalAuthTexts texts;

  const BiometricAuthPage({
    super.key,
    required this.onSuccess,
    this.onLogout,
    this.showLogoutButton = true,
    this.texts = const LocalAuthTexts(),
  });

  @override
  State<BiometricAuthPage> createState() => _BiometricAuthPageState();
}

class _BiometricAuthPageState extends State<BiometricAuthPage>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  Timer? _lockoutTimer;
  int _remainingSeconds = 0;
  late AnimationController _shakeController;
  bool _hasAutoTriggeredBiometric = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(
          milliseconds: LocalAuthConstants.shakeAnimationDuration),
      vsync: this,
    );
    context.read<LocalAuthLoginBloc>().add(LoadLoginPolicyEvent());
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startTimer(int endTime) {
    _lockoutTimer?.cancel();
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = ((endTime - now) / 1000).ceil();

    if (remaining <= 0) {
      context.read<LocalAuthLoginBloc>().add(CheckLockoutEvent());
      return;
    }

    setState(() => _remainingSeconds = remaining);

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
            context.read<LocalAuthLoginBloc>().add(CheckLockoutEvent());
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleKeyPress(String value, bool isLockedOut) {
    // Ignore key press while locked or after reaching PIN length.
    if (isLockedOut || _enteredPin.length >= LocalAuthConstants.pinLength) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin += value;
    });

    // Trigger verification once PIN length is reached.
    if (_enteredPin.length == LocalAuthConstants.pinLength) {
      context
          .read<LocalAuthLoginBloc>()
          .add(VerifyPinLoginEvent(pin: _enteredPin));
    }
  }

  void _handleDelete(bool isLockedOut) {
    if (isLockedOut || _enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocalAuthLoginBloc, LocalAuthLoginState>(
      listener: (context, state) {
        if (state.authStatus == AuthStatus.authenticated) {
          HapticFeedback.heavyImpact();
          widget.onSuccess();
        } else if (state.authStatus == AuthStatus.failure) {
          HapticFeedback.vibrate();
          // Önce salla, sallama bitince input'u temizle
          _shakeController
              .forward(from: 0.0)
              .then((_) => setState(() => _enteredPin = ''));
        } else if (state.authStatus == AuthStatus.lockedOut) {
          setState(() => _enteredPin = '');
          if (state.lockoutEndTime != null) {
            _startTimer(state.lockoutEndTime!);
          }
        }

        if (state.loadStatus == LoginLoadStatus.success &&
            state.isBiometricAvailable &&
            state.isBiometricEnabled &&
            state.authStatus == AuthStatus.initial &&
            !_hasAutoTriggeredBiometric) {
          _hasAutoTriggeredBiometric = true;
          context.read<LocalAuthLoginBloc>().add(BiometricAuthLoginEvent());
        }
      },
      builder: (context, state) {
        final isLockedOut = state.authStatus == AuthStatus.lockedOut;
        final theme = Theme.of(context);
        final isBiometricReady =
            state.isBiometricAvailable && state.isBiometricEnabled;
        final statusText = _statusText(state, isLockedOut);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: widget.showLogoutButton && widget.onLogout != null
                ? [
                    TextButton.icon(
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: Text(widget.texts.logoutLabel),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ]
                : null,
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: IboGlassSurface(
                    padding: const EdgeInsets.all(20),
                    style: IboGlassStyle(
                      borderRadius: BorderRadius.circular(28),
                      backgroundColor: theme.colorScheme.surface,
                      backgroundOpacity: 0.9,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.22),
                            ),
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 36,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.texts.welcomeTitle,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            statusText,
                            key: ValueKey(statusText),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: (isLockedOut ||
                                      (state.authStatus == AuthStatus.failure &&
                                          _enteredPin.isEmpty))
                                  ? theme.colorScheme.error
                                  : theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                              fontWeight: isLockedOut
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                LocalAuthPinDots(
                  length: LocalAuthConstants.pinLength,
                  filled: _enteredPin.length,
                  isError: _isPinError(state),
                  shake: _shakeController,
                  activeColor: theme.primaryColor,
                  inactiveColor: Colors.grey.withValues(alpha: 0.2),
                  errorColor: theme.colorScheme.error,
                ),
                const Spacer(),
                LocalAuthNumpad(
                  isLockedOut: isLockedOut,
                  showBiometric: isBiometricReady,
                  onDigit: (digit) => _handleKeyPress(digit, isLockedOut),
                  onBackspace: () => _handleDelete(isLockedOut),
                  onBiometric: () => context
                      .read<LocalAuthLoginBloc>()
                      .add(BiometricAuthLoginEvent()),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _localizeMessage(String? msg) {
    if (msg == null) return null;
    if (msg.startsWith('Incorrect PIN. Remaining tries:')) {
      final tries = msg.split(':').last.trim();
      return widget.texts.msgIncorrectPinRemainingTries.replaceFirst('{tries}', tries);
    }
    if (msg.startsWith('PIN verification failed')) {
      final error = msg.replaceFirst('PIN verification failed: ', '');
      return widget.texts.msgPINVerificationFailedE.replaceFirst('{error}', error);
    }
    return msg;
  }

  String _statusText(LocalAuthLoginState state, bool isLockedOut) {
    if (isLockedOut) {
      return '${widget.texts.lockedOutPromptPrefix}\n$_remainingSeconds ${widget.texts.lockedOutPromptSuffix}';
    }
    if (state.authStatus == AuthStatus.failure) {
      return _localizeMessage(state.message) ?? widget.texts.invalidPinFallback;
    }
    return _localizeMessage(state.message) ?? widget.texts.enterPinPrompt;
  }

  bool _isPinError(LocalAuthLoginState state) {
    return state.authStatus == AuthStatus.failure &&
        (_enteredPin.isEmpty ||
            _enteredPin.length == LocalAuthConstants.pinLength);
  }
}
