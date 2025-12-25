import 'package:cunehat/features/auth_feature/data/datasources/biometric_data_source.dart';
import 'package:flutter/material.dart';

class ModernAuthPage extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onLogout;

  const ModernAuthPage({
    super.key,
    required this.onSuccess,
    required this.onLogout,
  });

  @override
  State<ModernAuthPage> createState() => _ModernAuthPageState();
}

class _ModernAuthPageState extends State<ModernAuthPage> {
  final BiometricService _biometricService = BiometricService();
  final TextEditingController _pinController = TextEditingController();

  bool _isBiometricAvailable = false;
  bool _isPinEnabled = false;
  String? _errorText;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthMethods();
  }

  Future<void> _checkAuthMethods() async {
    final bioAvailable = await _biometricService.isBiometricAvailable();
    final bioEnabled = await _biometricService.isBiometricEnabled();
    final pinSet = await _biometricService.isPinCodeSet();

    setState(() {
      _isBiometricAvailable = bioAvailable;
      _isPinEnabled = pinSet;
    });

    // ✅ Auto-trigger biometric if enabled
    if (bioAvailable && bioEnabled) {
      Future.delayed(
          const Duration(milliseconds: 300), _authenticateWithBiometric);
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final success = await _biometricService.authenticateWithBiometrics();
    if (success && mounted) {
      widget.onSuccess();
    }
  }

  void _verifyPin() async {
    if (_pinController.text.length != 6) {
      setState(() => _errorText = 'PIN 6 haneli olmalıdır');
      return;
    }

    final isCorrect =
        await _biometricService.verifyPinCode(_pinController.text);
    if (isCorrect && mounted) {
      widget.onSuccess();
    } else {
      setState(() {
        _failedAttempts++;
        _errorText = 'Hatalı PIN (${_failedAttempts}/3)';
      });
      _pinController.clear();

      if (_failedAttempts >= 3) {
        _showLockoutDialog();
      }
    }
  }

  void _showLockoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: const Text('Çok Fazla Deneme'),
        content: const Text(
          '3 başarısız deneme yaptınız.\nLütfen 30 saniye bekleyin veya biyometrik ile giriş yapın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // ========== TOP BAR: Logout Button ==========
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Çıkış'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),

              const Spacer(),

              // ========== LOCK ICON ==========
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: theme.primaryColor,
                ),
              ),

              const SizedBox(height: 32),

              // ========== TITLE ==========
              Text(
                'Güvenli Giriş',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kimliğinizi doğrulayın',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 48),

              // ========== PIN INPUT ==========
              if (_isPinEnabled) ...[
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w300,
                  ),
                  decoration: InputDecoration(
                    hintText: '• • • • • •',
                    errorText: _errorText,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (_) {
                    setState(() => _errorText = null);
                    if (_pinController.text.length == 6) {
                      _verifyPin();
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],

              // ========== BIOMETRIC BUTTON ==========
              if (_isBiometricAvailable)
                ElevatedButton.icon(
                  onPressed: _authenticateWithBiometric,
                  icon: const Icon(Icons.fingerprint, size: 28),
                  label: const Text('Biyometrik ile Giriş'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
