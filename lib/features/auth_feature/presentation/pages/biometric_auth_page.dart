// ignore_for_file: unused_field

import 'package:cunehat/features/auth_feature/data/datasources/biometric_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final BiometricDataSource _biometricService = BiometricDataSource();

  String _enteredPin = '';
  bool _isBiometricAvailable = false;
  bool _isPinEnabled = false;
  String? _errorText;
  int _failedAttempts = 0;
  bool _isLoading = false;
  int _lockoutLevel = 0;
  Timer? _lockoutTimer;
  int _remainingSeconds = 0;
  bool get _isLockedOut => _remainingSeconds > 0;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _checkAuthMethods();
    _checkExistingLockout();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingLockout() async {
    final endTime = await _biometricService.getLockoutEndTime();
    final level = await _biometricService.getLockoutLevel();

    if (endTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = ((endTime - now) / 1000).ceil();

      if (remaining > 0) {
        setState(() {
          _lockoutLevel = level;
          _remainingSeconds = remaining;
        });
        _startTimerOnly();
      } else {
        // Süre dolmuş ama level'ı hatırlayalım (isteğe bağlı)
        setState(() => _lockoutLevel = level);
      }
    }
  }

  Future<void> _checkAuthMethods() async {
    final bioAvailable = await _biometricService.isBiometricAvailable();
    final bioEnabled = await _biometricService.isBiometricEnabled();
    final pinSet = await _biometricService.isPinCodeSet();

    if (mounted) {
      setState(() {
        _isBiometricAvailable = bioAvailable;
        _isPinEnabled = pinSet;
      });
    }

    // ✅ Auto-trigger biometric if enabled
    if (bioAvailable && bioEnabled) {
      Future.delayed(
          const Duration(milliseconds: 300), _authenticateWithBiometric);
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isLockedOut) return;
    final success = await _biometricService.authenticateWithBiometrics();
    if (success && mounted) {
      await _resetSecurityState();
      widget.onSuccess();
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _verifyPin() async {
    if (_isLockedOut) return;
    setState(() => _isLoading = true);
    // Kısa bir gecikme hissi (UX için)
    await Future.delayed(const Duration(milliseconds: 150));

    final isCorrect = await _biometricService.verifyPinCode(_enteredPin);

    if (!mounted) return;

    if (isCorrect) {
      HapticFeedback.heavyImpact();
      await _resetSecurityState();
      widget.onSuccess();
    } else {
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0.0);
      setState(() {
        _isLoading = false;
        _enteredPin = '';
        _failedAttempts++;
      });

      if (_failedAttempts >= 3) {
        _startLockout();
      } else {
        setState(() {
          _errorText = 'Hatalı PIN. Kalan hak: ${3 - _failedAttempts}';
        });
      }
    }
  }

  Future<void> _resetSecurityState() async {
    if (mounted) {
      setState(() {
        _failedAttempts = 0;
        _lockoutLevel = 0;
        _remainingSeconds = 0;
        _errorText = null;
      });
    }
    await _biometricService.clearLockoutState();
  }

  void _startLockout() {
    int duration;
    if (_lockoutLevel == 0) {
      duration = 30; // İlk kilitlenme: 30 saniye
    } else if (_lockoutLevel == 1) {
      duration = 120; // İkinci kilitlenme: 2 dakika
    } else if (_lockoutLevel == 2) {
      duration = 300; // Sonraki kilitlenmeler: 5 dakika
    } else {
      duration = 1000; // sonraki kilitlenmeler: 16 dakika
    }

    // Kalıcı hafızaya kaydet
    final endTime = DateTime.now().millisecondsSinceEpoch + (duration * 1000);
    _biometricService.saveLockoutState(_lockoutLevel + 1, endTime);

    setState(() {
      _remainingSeconds = duration;
      _errorText = null;
      _lockoutLevel++;
    });
    _startTimerOnly();
  }

  void _startTimerOnly() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _resetLockout();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resetLockout() {
    _lockoutTimer?.cancel();
    if (mounted) {
      setState(() {
        _remainingSeconds = 0;
        _failedAttempts = 0;
        _errorText = null;
      });
    }
  }

  void _onKeyPressed(String value) {
    if (_isLockedOut) return;
    if (_enteredPin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += value;
        _errorText = null;
      });
      if (_enteredPin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_isLockedOut) return;
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
                  _isLockedOut
                      ? Text(
                          'Çok fazla hatalı deneme.\n$_remainingSeconds saniye bekleyin.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          _errorText ?? 'Devam etmek için PIN girin',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _errorText != null
                                ? theme.colorScheme.error
                                : theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.6),
                            fontWeight: _errorText != null
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
                      children: List.generate(6, (index) {
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
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var j = 1; j <= 3; j++)
                            _buildNumberButton((i * 3 + j).toString(), theme),
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
                        child: _isBiometricAvailable
                            ? InkWell(
                                onTap: _isLockedOut
                                    ? null
                                    : _authenticateWithBiometric,
                                borderRadius: BorderRadius.circular(36),
                                child: Opacity(
                                  opacity: _isLockedOut ? 0.5 : 1.0,
                                  child: Icon(
                                    Icons.fingerprint,
                                    size: 32,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      _buildNumberButton('0', theme),
                      // Delete Button
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: InkWell(
                          onTap: _isLockedOut ? null : _onDeletePressed,
                          borderRadius: BorderRadius.circular(36),
                          child: Opacity(
                            opacity: _isLockedOut ? 0.5 : 1.0,
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

  Widget _buildNumberButton(String number, ThemeData theme) {
    return InkWell(
      onTap: _isLockedOut ? null : () => _onKeyPressed(number),
      borderRadius: BorderRadius.circular(36),
      child: Opacity(
        opacity: _isLockedOut ? 0.5 : 1.0,
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
