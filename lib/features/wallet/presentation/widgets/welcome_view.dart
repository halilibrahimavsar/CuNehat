import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/motion/app_haptics.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart'
    show AppSpacing;

/// Uygulamanın ilk ekranı: cüzdanı olmayan kullanıcıyı karşılar.
///
/// Tek soru sorar ("Şu an ne kadar paran var?"), o da boş geçilebilir. İki
/// çıkışı vardır: **Başla** (cüzdan ve hazır kategoriler kurulur, defter
/// açılır) ve **Yedeğim var** (geri yükleme). Kurulumun kendisi burada değil
/// [onStart]'ın arkasında (`FirstWalletSetup`); bu widget yalnız sorar ve
/// bekler.
///
/// Birincil düğme kaydırılan alanın DIŞINDA: tutar alanına dokunan
/// kullanıcıda klavye açıkken de görünür kalır.
class WelcomeView extends StatefulWidget {
  const WelcomeView({
    super.key,
    required this.currency,
    required this.onStart,
    required this.onRestore,
    required this.onPrivacyPolicy,
  });

  /// İlk cüzdanın para birimi (sembolü alanın sonunda gösterilir).
  final String currency;

  /// "Başla". Girilen açılış bakiyesiyle çağrılır (boşsa 0). Hata iletisi
  /// dönerse ekranda gösterilir ve kullanıcı yeniden deneyebilir; `null`
  /// başarıdır.
  final Future<String?> Function(double openingBalance) onStart;

  final VoidCallback onRestore;
  final VoidCallback onPrivacyPolicy;

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  final _balance = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _balance.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_busy) return;
    final text = _balance.text.trim();
    final amount = text.isEmpty ? 0.0 : parseMoneyInput(text);
    if (amount == null || amount.abs() > kMaxAmount) {
      setState(() => _error = context.l10n.gecerliBirSayiGirin);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onStart(amount);
    if (!mounted) return;
    if (error == null) {
      AppHaptics.confirm();
      // Başarıda bu ekran zaten ağaçtan çıkar (cüzdan oluştu); meşgul
      // durumu bilerek açık bırakılır ki arada düğme yeniden basılamasın.
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.large,
                AppSpacing.xl,
                AppSpacing.large,
                AppSpacing.medium,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Mark(),
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      l10n.firstRunTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      l10n.firstRunBody,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.firstRunBalanceLabel,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    TextField(
                      key: const ValueKey('first-run-balance'),
                      controller: _balance,
                      enabled: !_busy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _start(),
                      // Eksiye düşmüş hesap da geçerli bir başlangıçtır.
                      inputFormatters: [
                        AmountInputFormatter(allowNegative: true),
                      ],
                      style: theme.textTheme.titleLarge,
                      decoration: InputDecoration(
                        hintText: '0',
                        // `suffixText` yalnız alan odaktayken görünür
                        // (cihazda görüldü); birim soruyla birlikte, alana
                        // dokunulmadan okunmalı.
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(
                            right: AppSpacing.medium,
                          ),
                          child: Text(
                            currencySymbol(widget.currency),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        suffixIconConstraints: const BoxConstraints(),
                        helperText: l10n.firstRunBalanceHint,
                        helperMaxLines: 2,
                        errorText: _error,
                        errorMaxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.large,
            AppSpacing.small,
            AppSpacing.large,
            AppSpacing.compact,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: const ValueKey('first-run-start'),
                  onPressed: _busy ? null : _start,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: theme.textTheme.titleMedium,
                  ),
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(l10n.firstRunStart),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  key: const ValueKey('first-run-restore'),
                  onPressed: _busy ? null : widget.onRestore,
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(l10n.firstRunRestore),
                ),
                const SizedBox(height: AppSpacing.xs),
                _PrivacyNote(onTap: widget.onPrivacyPolicy),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Uygulamanın işareti: bölüm mavisinde, küçük ve sakin.
class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppGradients.pageHeader,
          borderRadius: AppRadius.cardAll,
        ),
        child: const SizedBox.square(
          dimension: 64,
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}

/// "Verilerin yalnız bu cihazda durur. Gizlilik politikası" — açılıştaki
/// kapatılamaz gizlilik diyaloğunun yerini alır. Bilgi aynı, engel yok.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.firstRunPrivacyNote,
            textAlign: TextAlign.center, style: muted),
        TextButton(
          key: const ValueKey('first-run-privacy'),
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            textStyle: theme.textTheme.labelMedium,
          ),
          child: Text(l10n.privacyPolicyTitle),
        ),
      ],
    );
  }
}
