// ignore_for_file: unused_field

import 'package:cunehat/features/auth_feature/presentation/bloc/local_auth/local_auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:math' as math;

class BiometricAuthPage extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onLogout;

  const BiometricAuthPage({
    super.key,
    required this.onSuccess,
    required this.onLogout,
  });

  @override
  State<BiometricAuthPage> createState() => _BiometricAuthPageState();
}

class _BiometricAuthPageState extends State<BiometricAuthPage>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  // Timer is purely for UI countdown display
  Timer? _lockoutTimer;
  int _remainingSeconds = 0;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // Trigger initial check
    context.read<LocalAuthBloc>().add(LoadSecurityEvent());
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
      context.read<LocalAuthBloc>().add(CheckLockoutEvent());
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
            context.read<LocalAuthBloc>().add(CheckLockoutEvent());
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onKeyPressed(String value, bool isLockedOut) {
    if (isLockedOut) return;
    if (_enteredPin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += value;
      });
      if (_enteredPin.length == 6) {
        context.read<LocalAuthBloc>().add(VerifyPinLoginEvent(_enteredPin));
      }
    }
  }

  void _onDeletePressed(bool isLockedOut) {
    if (isLockedOut) return;
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<LocalAuthBloc, LocalAuthState>(
      listener: (context, state) {
        if (state.authStatus == AuthStatus.authenticated) {
          HapticFeedback.heavyImpact();
          widget.onSuccess();
        } else if (state.authStatus == AuthStatus.failure) {
          HapticFeedback.vibrate();
          _shakeController.forward(from: 0.0);
          setState(() => _enteredPin = '');
        } else if (state.authStatus == AuthStatus.lockedOut) {
          if (state.lockoutEndTime != null) {
            _startTimer(state.lockoutEndTime!);
          }
        }

        // Auto-trigger biometric if available and enabled
        // We check this once when status becomes success (loaded)
        if (state.status == SecurityStatus.success &&
            state.isBiometricAvailable &&
            state.isBiometricEnabled &&
            state.authStatus == AuthStatus.initial) {
          // Prevent loop by checking authStatus
          context.read<LocalAuthBloc>().add(BiometricAuthLoginEvent());
        }
      },
      builder: (context, state) {
        final isLockedOut = state.authStatus == AuthStatus.lockedOut;
        final errorText = state.message;

        return _buildScaffold(context, theme, isLockedOut, errorText, state);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, ThemeData theme, bool isLockedOut,
      String? errorText, LocalAuthState state) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ========== TOP BAR: Logout Button ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onLogout,
                    icon: Icon(Icons.logout_rounded,
                        size: 20, color: theme.colorScheme.error),
                    label: Text('Çıkış',
                        style: TextStyle(color: theme.colorScheme.error)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      backgroundColor:
                          theme.colorScheme.error.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ========== ICON & TITLE ==========
                  Icon(
                    Icons.lock_person_rounded,
                    size: 64,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tekrar Hoşgeldiniz',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  isLockedOut
                      ? Text(
                          'Çok fazla hatalı deneme.\n$_remainingSeconds saniye bekleyin.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          errorText ?? 'Devam etmek için PIN girin',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: errorText != null
                                ? theme.colorScheme.error
                                : theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.6),
                            fontWeight: errorText != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),

                  const SizedBox(height: 48),

                  // ========== PIN DOTS ==========
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      // Shake animation math (damped sine wave)
                      final offset = 20 *
                          math.sin(_shakeController.value * math.pi * 3) *
                          (1 - _shakeController.value);
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(math.max(4, _enteredPin.length),
                          (index) {
                        final isFilled = index < _enteredPin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled
                                ? theme.primaryColor
                                : theme.dividerColor.withValues(alpha: 0.2),
                            border: isFilled
                                ? null
                                : Border.all(
                                    color: theme.dividerColor
                                        .withValues(alpha: 0.5)),
                            boxShadow: isFilled
                                ? [
                                    BoxShadow(
                                      color: theme.primaryColor
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // ========== NUMBER PAD ==========
            Container(
              padding: const EdgeInsets.only(bottom: 32, left: 32, right: 32),
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var j = 1; j <= 3; j++)
                            _buildNumberButton(
                                (i * 3 + j).toString(), theme, isLockedOut),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric Button
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: _enteredPin.length >= 4
                            ? InkWell(
                                onTap: isLockedOut
                                    ? null
                                    : () => context
                                        .read<LocalAuthBloc>()
                                        .add(VerifyPinLoginEvent(_enteredPin)),
                                borderRadius: BorderRadius.circular(36),
                                child: Opacity(
                                  opacity: isLockedOut ? 0.5 : 1.0,
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 32,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              )
                            : (state.isBiometricAvailable &&
                                    state.isBiometricEnabled
                                ? InkWell(
                                    onTap: isLockedOut
                                        ? null
                                        : () => context
                                            .read<LocalAuthBloc>()
                                            .add(BiometricAuthLoginEvent()),
                                    borderRadius: BorderRadius.circular(36),
                                    child: Opacity(
                                      opacity: isLockedOut ? 0.5 : 1.0,
                                      child: Icon(
                                        Icons.fingerprint,
                                        size: 32,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  )
                                : null),
                      ),
                      _buildNumberButton('0', theme, isLockedOut),
                      // Delete Button
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: InkWell(
                          onTap: isLockedOut
                              ? null
                              : () => _onDeletePressed(isLockedOut),
                          borderRadius: BorderRadius.circular(36),
                          child: Opacity(
                            opacity: isLockedOut ? 0.5 : 1.0,
                            child: Icon(
                              Icons.backspace_outlined,
                              size: 26,
                              color:
                                  theme.iconTheme.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number, ThemeData theme, bool isLockedOut) {
    return InkWell(
      onTap: isLockedOut ? null : () => _onKeyPressed(number, isLockedOut),
      borderRadius: BorderRadius.circular(36),
      child: Opacity(
        opacity: isLockedOut ? 0.5 : 1.0,
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
