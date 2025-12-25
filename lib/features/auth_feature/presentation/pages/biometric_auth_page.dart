import 'dart:ui';
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

class _ModernAuthPageState extends State<ModernAuthPage>
    with SingleTickerProviderStateMixin {
  final BiometricService _biometricService = BiometricService();
  final TextEditingController _pinController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showPinInput = false;
  bool _isBiometricAvailable = false;
  bool _isPinEnabled = false;
  bool _rememberMe = false;
  bool _useBiometric = true;
  bool _usePin = true;
  String? _errorText;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _checkAuthMethods();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkAuthMethods() async {
    final biometricAvailable = await _biometricService.isBiometricAvailable();
    final biometricEnabled = await _biometricService.isBiometricEnabled();
    final pinEnabled = await _biometricService.isPinCodeSet();

    setState(() {
      _isBiometricAvailable = biometricAvailable;
      _isPinEnabled = pinEnabled;
      _useBiometric = biometricAvailable && biometricEnabled;
    });

    // Otomatik biyometrik kimlik doğrulama
    if (_useBiometric && biometricAvailable) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _authenticateWithBiometric();
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (!_useBiometric || !_isBiometricAvailable) return;

    final authenticated = await _biometricService.authenticateWithBiometrics();
    if (authenticated && mounted) {
      _handleSuccessfulAuth();
    }
  }

  void _handleSuccessfulAuth() {
    // Başarı animasyonu
    _animationController.reverse().then((_) {
      widget.onSuccess();
    });
  }

  void _verifyPin() async {
    if (_pinController.text.isEmpty) {
      setState(() => _errorText = 'Lütfen PIN kodunuzu girin');
      return;
    }

    if (_pinController.text.length < 4) {
      setState(() => _errorText = 'PIN en az 4 haneli olmalıdır');
      return;
    }

    final isCorrect =
        await _biometricService.verifyPinCode(_pinController.text);
    if (isCorrect && mounted) {
      _handleSuccessfulAuth();
    } else {
      setState(() {
        _failedAttempts++;
        _errorText = 'Hatalı PIN (${_failedAttempts}/3 deneme)';
      });
      _pinController.clear();

      if (_failedAttempts >= 3) {
        _showLockoutDialog();
        return;
      }

      // Hata animasyonu
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _showLockoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Çok Fazla Deneme'),
          ],
        ),
        content: const Text(
          '3 başarısız deneme yaptınız. Lütfen 30 saniye bekleyin veya biyometrik ile giriş yapın.',
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

  void _toggleBiometric(bool value) async {
    if (value) {
      await _biometricService.enableBiometric();
    } else {
      await _biometricService.disableBiometric();
    }
    setState(() => _useBiometric = value);
  }

  void _togglePin(bool value) async {
    if (value) {
      // PIN ayarla dialog'u göster
      _showSetPinDialog();
    } else {
      // await _biometricService.removePinCode();
      setState(() => _usePin = value);
    }
  }

  void _showSetPinDialog() {
    showDialog(
      context: context,
      builder: (context) => PinSetupDialog(
        onPinSet: (pin) async {
          // await _biometricService.setPinCode(pin);
          setState(() => _usePin = true);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Arkaplan Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withOpacity(0.9),
                  colors.primary.withOpacity(0.7),
                  colors.secondary.withOpacity(0.8),
                  colors.secondary.withOpacity(0.6),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Arkaplan deseni
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar with Logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildLogoutButton(),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo/Icon
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.9),
                                      Colors.white.withOpacity(0.7),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Icon(
                                      Icons.lock_outlined,
                                      size: 80,
                                      color: colors.primary,
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _showPinInput
                                              ? Icons.pin_outlined
                                              : Icons.fingerprint,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Başlık
                            SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                children: [
                                  Text(
                                    _showPinInput
                                        ? 'PIN Doğrulama'
                                        : 'Güvenli Giriş',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _showPinInput
                                        ? 'PIN kodunuzu girin'
                                        : 'Hesabınıza erişmek için kimliğinizi doğrulayın',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 50),

                            // Ana İçerik
                            if (!_showPinInput) _buildMainAuthOptions(),
                            if (_showPinInput) _buildPinInput(),

                            const SizedBox(height: 30),

                            // Ayarlar Bölümü
                            _buildSettingsSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAuthOptions() {
    return Column(
      children: [
        // Biyometrik Buton
        if (_isBiometricAvailable && _useBiometric)
          _buildModernButton(
            icon: Icons.fingerprint,
            label: 'Biyometrik ile Giriş Yap',
            subtitle: 'Parmak izi veya yüz tanıma',
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
            onTap: _authenticateWithBiometric,
          ),

        if (_isBiometricAvailable && _useBiometric && _isPinEnabled)
          const SizedBox(height: 16),

        // PIN Buton
        if (_isPinEnabled)
          _buildModernButton(
            icon: Icons.pin_outlined,
            label: 'PIN ile Giriş Yap',
            subtitle: '6 haneli PIN kodu',
            gradient: LinearGradient(
              colors: [
                Colors.blueGrey.shade700,
                Colors.blueGrey.shade900,
              ],
            ),
            onTap: () => setState(() => _showPinInput = true),
          ),

        // Veya ayırıcı
        if (_isBiometricAvailable && _isPinEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'veya',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ),

        // Hızlı Ayarlar
        _buildQuickSettings(),
      ],
    );
  }

  Widget _buildPinInput() {
    return SlideTransition(
      position: _slideAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // PIN Input
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: '• • • • • •',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      letterSpacing: 12,
                      fontSize: 32,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    errorText: _errorText,
                    errorStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.redAccent,
                      fontSize: 14,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    setState(() => _errorText = null);
                    if (_pinController.text.length == 6) {
                      _verifyPin();
                    }
                  },
                ),

                const SizedBox(height: 32),

                // Numpad
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      return const SizedBox.shrink(); // Boş
                    }
                    if (index == 10) {
                      return _buildNumpadButton('0', onTap: () {
                        _pinController.text += '0';
                      });
                    }
                    if (index == 11) {
                      return _buildNumpadButton(
                        Icons.backspace_outlined,
                        onTap: () {
                          if (_pinController.text.isNotEmpty) {
                            _pinController.text = _pinController.text
                                .substring(0, _pinController.text.length - 1);
                          }
                        },
                      );
                    }
                    return _buildNumpadButton(
                      (index + 1).toString(),
                      onTap: () {
                        _pinController.text += (index + 1).toString();
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showPinInput = false;
                            _pinController.clear();
                            _errorText = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 20),
                            SizedBox(width: 8),
                            Text('Geri Dön'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _verifyPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Doğrula',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadButton(dynamic content, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Center(
            child: content is String
                ? Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  )
                : Icon(
                    content as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSettings() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı Ayarlar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Beni Hatırla
          Row(
            children: [
              Transform.scale(
                scale: 0.9,
                child: Switch.adaptive(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() => _rememberMe = value);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Beni Hatırla',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          // Hızlı Giriş Butonları
          if (_isBiometricAvailable || _isPinEnabled)
            const SizedBox(height: 12),
          if (_isBiometricAvailable || _isPinEnabled)
            Text(
              'Hızlı Giriş Yöntemleri',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_isBiometricAvailable)
                _buildQuickAuthButton(
                  icon: Icons.fingerprint,
                  active: _useBiometric,
                  onTap: () => _toggleBiometric(!_useBiometric),
                ),
              if (_isBiometricAvailable && _isPinEnabled)
                const SizedBox(width: 12),
              if (_isPinEnabled)
                _buildQuickAuthButton(
                  icon: Icons.pin,
                  active: _usePin,
                  onTap: () => _togglePin(!_usePin),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          // Güvenlik Seviyesi Göstergesi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  _failedAttempts > 0 ? Icons.security : Icons.verified_user,
                  color: _failedAttempts > 0 ? Colors.amber : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Güvenlik Durumu',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (3 - _failedAttempts) / 3,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        color: _failedAttempts == 0
                            ? Colors.green
                            : _failedAttempts < 3
                                ? Colors.amber
                                : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    String? subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAuthButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withOpacity(0.3),
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                active ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onLogout,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Çıkış Yap',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PIN Kurulum Dialog'u
class PinSetupDialog extends StatefulWidget {
  final Function(String) onPinSet;

  const PinSetupDialog({super.key, required this.onPinSet});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String _errorText = '';

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _verifyAndSet() {
    if (_pinController.text.length < 4) {
      setState(() => _errorText = 'PIN en az 4 haneli olmalıdır');
      return;
    }

    if (_pinController.text != _confirmController.text) {
      setState(() => _errorText = 'PIN kodları eşleşmiyor');
      return;
    }

    widget.onPinSet(_pinController.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pin_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'PIN Kodu Ayarla',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Yeni PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'PIN Tekrar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _errorText.isNotEmpty ? _errorText : null,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _verifyAndSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kaydet',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
