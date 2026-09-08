import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

/// PIN giriş akışının tek adımı.
class PinPromptStep {
  final String title;
  final String subtitle;

  /// Bir önceki adımla birebir aynı olmalı (doğrulama adımı).
  final bool confirmsPrevious;

  /// Anında doğrulama; `false` dönerse adım tekrarlanır.
  ///
  /// Mevcut PIN'i burada doğrulamak, kullanıcıya sayfa kapandıktan sonra
  /// snackbar göstermekten iyidir: hata girdiği yerde görünür.
  final Future<bool> Function(String pin)? verify;

  /// [verify] `false` döndüğünde gösterilecek metin.
  final String? verifyErrorText;

  const PinPromptStep({
    required this.title,
    required this.subtitle,
    this.confirmsPrevious = false,
    this.verify,
    this.verifyErrorText,
  });
}

/// Nokta + tuş takımı ile PIN girişi.
///
/// Kilit ekranıyla AYNI iki bileşeni kullanır ([LocalAuthPinDots],
/// [LocalAuthNumpad]); eski `PinInputDialog` küçük, gizlenmiş metin
/// kutularıydı ve etiketleri koda gömülü İngilizceydi.
class PinEntryPage extends StatefulWidget {
  final String pageTitle;
  final List<PinPromptStep> steps;

  const PinEntryPage({
    super.key,
    required this.pageTitle,
    required this.steps,
  });

  /// Adımları sırayla sorar; iptal edilirse `null` döner.
  static Future<List<String>?> show(
    BuildContext context, {
    required String pageTitle,
    required List<PinPromptStep> steps,
  }) {
    return Navigator.of(context).push<List<String>>(
      MaterialPageRoute<List<String>>(
        fullscreenDialog: true,
        builder: (_) => PinEntryPage(pageTitle: pageTitle, steps: steps),
      ),
    );
  }

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;
  final List<String> _collected = [];
  String _entered = '';
  int _step = 0;
  bool _busy = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  PinPromptStep get _current => widget.steps[_step];

  void _onDigit(String digit) {
    if (_busy || _entered.length >= LocalAuthConstants.pinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entered += digit;
      _errorText = null;
    });
    if (_entered.length == LocalAuthConstants.pinLength) {
      _submitStep();
    }
  }

  void _onBackspace() {
    if (_busy || _entered.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submitStep() async {
    final pin = _entered;
    setState(() => _busy = true);

    if (_current.confirmsPrevious && _collected.isNotEmpty) {
      if (pin != _collected.last) {
        await _fail(context.l10n.pinEntryMismatch);
        return;
      }
    }

    final verify = _current.verify;
    if (verify != null) {
      final ok = await verify(pin);
      if (!mounted) return;
      if (!ok) {
        await _fail(
            _current.verifyErrorText ?? context.l10n.invalidPinFallback);
        return;
      }
    }

    _collected.add(pin);
    if (_step == widget.steps.length - 1) {
      Navigator.of(context).pop(List<String>.unmodifiable(_collected));
      return;
    }
    setState(() {
      _step++;
      _entered = '';
      _busy = false;
    });
  }

  /// Adımı başarısız kapatır: salla, temizle, AYNI adımda kal.
  ///
  /// Doğrulama adımı düşerse bir öncekine dönülür; yoksa kullanıcı ilk PIN'i
  /// göremeden onu tekrar etmeye zorlanırdı.
  Future<void> _fail(String message) async {
    HapticFeedback.vibrate();
    await _shake.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _errorText = message;
      _entered = '';
      _busy = false;
      if (_current.confirmsPrevious && _collected.isNotEmpty) {
        _collected.removeLast();
        _step--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final step = _current;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(widget.pageTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Tuş takımı sabit 360dp; başlık + noktalar + adım göstergesiyle birlikte
      // kısa ekranlarda (ve büyük yazı ölçeğinde) sığmaz. Uzun ekranda
      // Spacer'lar dağılsın, kısa ekranda KAYSIN.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            step.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorText ?? step.subtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _errorText != null
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    LocalAuthPinDots(
                      length: LocalAuthConstants.pinLength,
                      filled: _entered.length,
                      isError: _errorText != null,
                      shake: _shake,
                      activeColor: scheme.primary,
                      inactiveColor:
                          scheme.onSurfaceVariant.withValues(alpha: 0.22),
                      errorColor: scheme.error,
                    ),
                    if (widget.steps.length > 1) ...[
                      const SizedBox(height: 20),
                      _StepDots(count: widget.steps.length, index: _step),
                    ],
                    const Spacer(),
                    LocalAuthNumpad(
                      isLockedOut: _busy,
                      showBiometric: false,
                      onDigit: _onDigit,
                      onBackspace: _onBackspace,
                      onBiometric: () {},
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Çok adımlı akışta "kaçıncı adımdayım" göstergesi.
class _StepDots extends StatelessWidget {
  final int count;
  final int index;

  const _StepDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? scheme.primary
                : scheme.onSurfaceVariant.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
