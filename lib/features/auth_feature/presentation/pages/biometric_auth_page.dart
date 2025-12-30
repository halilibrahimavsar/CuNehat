// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:cunehat/features/auth_feature/presentation/bloc/local_auth/local_auth_bloc.dart';

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

  void _handleKeyPress(String value, bool isLockedOut) {
    // Eğer kilitliyse veya zaten 4 hane girildiyse işlem yapma
    if (isLockedOut || _enteredPin.length >= 4) return;

    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin += value;
    });

    // 4. hane girildiği an doğrulama gönder
    if (_enteredPin.length == 4) {
      context.read<LocalAuthBloc>().add(VerifyPinLoginEvent(_enteredPin));
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
    final theme = Theme.of(context);

    return BlocConsumer<LocalAuthBloc, LocalAuthState>(
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
          if (state.lockoutEndTime != null) {
            _startTimer(state.lockoutEndTime!);
          }
        }

        if (state.status == SecurityStatus.success &&
            state.isBiometricAvailable &&
            state.isBiometricEnabled &&
            state.authStatus == AuthStatus.initial) {
          context.read<LocalAuthBloc>().add(BiometricAuthLoginEvent());
        }
      },
      builder: (context, state) {
        final isLockedOut = state.authStatus == AuthStatus.lockedOut;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              TextButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Çıkış Yap'),
                style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.lock_outline_rounded,
                  size: 80, color: theme.primaryColor),
              const SizedBox(height: 24),
              Text(
                'Hoş Geldiniz',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  isLockedOut
                      ? 'Çok fazla hatalı deneme. \n$_remainingSeconds saniye bekleyin.'
                      : (state.authStatus == AuthStatus.failure
                          ? 'Hatalı PIN, tekrar deneyin' // Hata durumunda özel mesaj
                          : (state.message ??
                              'Devam etmek için 4 haneli PIN girin')),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // Yazı rengi de input mantığına göre değişsin
                    color: (isLockedOut ||
                            (state.authStatus == AuthStatus.failure &&
                                _enteredPin.isEmpty))
                        ? theme.colorScheme.error
                        : theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.6),
                    fontWeight:
                        isLockedOut ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              const Spacer(),

              // PIN Noktaları (Güncellendi)
              _buildPinDots(state),

              const Spacer(),

              // Numpad
              _buildNumpad(state, isLockedOut),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinDots(LocalAuthState state) {
    // Hata Mantığı Düzeltmesi:
    // Hata rengini (kırmızı) SADECE şu durumlarda göster:
    // 1. PIN uzunluğu 4 ise (Sarsıntı anı)
    // 2. VEYA PIN boş ise (Sarsıntı bitti, kullanıcı henüz yazmadı)
    // Eğer kullanıcı yazmaya başlarsa (uzunluk 1, 2, 3) bu yeni bir denemedir, maviye dön.
    bool isError = state.authStatus == AuthStatus.failure &&
        (_enteredPin.isEmpty || _enteredPin.length == 4);

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = 24 *
            math.sin(_shakeController.value * math.pi * 4) *
            (1 - _shakeController.value);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          bool isFilled = index < _enteredPin.length;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Eğer hata varsa kırmızı, yoksa ve doluysa primary, boşsa gri
              color: isError
                  ? Colors.red
                  : (isFilled
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withValues(alpha: 0.2)),
              boxShadow: isFilled && !isError
                  ? [
                      BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2)
                    ]
                  : [],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumpad(LocalAuthState state, bool isLockedOut) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var j = 1; j <= 3; j++)
                  _buildNumberButton((i * 3 + j).toString(), isLockedOut),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                state.isBiometricAvailable && state.isBiometricEnabled
                    ? Icons.fingerprint_rounded
                    : null,
                () => context
                    .read<LocalAuthBloc>()
                    .add(BiometricAuthLoginEvent()),
                isLockedOut,
              ),
              _buildNumberButton('0', isLockedOut),
              _buildActionButton(
                Icons.backspace_outlined,
                () => _handleDelete(isLockedOut),
                isLockedOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String text, bool isLockedOut) {
    return InkWell(
      onTap: isLockedOut ? null : () => _handleKeyPress(text, isLockedOut),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 75,
        width: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).cardColor,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData? icon, VoidCallback onTap, bool isLockedOut) {
    if (icon == null) return const SizedBox(width: 75);
    return InkWell(
      onTap: isLockedOut ? null : onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        height: 75,
        width: 75,
        child: Icon(icon,
            size: 28,
            color: isLockedOut ? Colors.grey : Theme.of(context).primaryColor),
      ),
    );
  }
}
