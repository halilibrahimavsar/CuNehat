import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/features/settings/presentation/page/pin_recovery_page.dart';
import 'package:cunehat/features/settings/presentation/widgets/security/pin_entry_page.dart';
import 'package:cunehat/features/settings/presentation/widgets/security/security_notice_text.dart';
import 'package:cunehat/features/settings/presentation/widgets/security/security_tiles.dart';
import 'package:cunehat/features/settings/presentation/widgets/settings_header.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

/// Güvenlik ayarları.
///
/// Paketin `LocalAuthSettingsWidget`'i yerine uygulama tarafında yazıldı:
/// kartlar/ambiyans uygulamanın tasarım diline ([AppCard]) oturuyor, mesajlar
/// tek snackbar sisteminden ([AppMessenger]) geçiyor ve metinlerin tamamı
/// sözlükten geliyor — pakette PIN alan etiketleri koda gömülü İngilizceydi.
class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocalAuthSettingsBloc>(
      // Bloc SAYFAYLA yaşar: uygulama ömürlü bir güvenlik bloc'u önceki turun
      // durumunu taşır (bkz. kilit ekranındaki bayat `authenticated` hatası).
      create: (_) => getIt<LocalAuthSettingsBloc>()..add(LoadSettingsEvent()),
      child: const _SecuritySettingsView(),
    );
  }
}

class _SecuritySettingsView extends StatelessWidget {
  const _SecuritySettingsView();

  static const List<int> _timeoutOptions = [0, 5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: BlocConsumer<LocalAuthSettingsBloc, LocalAuthSettingsState>(
        listenWhen: (prev, curr) => prev.notice != curr.notice,
        listener: (context, state) {
          final text = localAuthNoticeText(l10n, state.notice, state.message);
          if (text == null) return;
          if (state.status == SettingsStatus.error) {
            AppMessenger.error(text);
          } else {
            AppMessenger.success(text);
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: scheme.primary,
                leading: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    l10n.securityTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primary, scheme.secondary],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32)
                    .plusSystemBottom(context),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatusHeader(state: state),
                    const SizedBox(height: 24),
                    SettingsHeader(title: l10n.securityLockSection),
                    _PinTile(state: state),
                    const SizedBox(height: 8),
                    _BiometricTile(state: state),
                    const SizedBox(height: 24),
                    SettingsHeader(title: l10n.securityPrivacySection),
                    _PrivacyGuardTile(state: state),
                    const SizedBox(height: 8),
                    _BackgroundLockTile(
                      state: state,
                      options: _timeoutOptions,
                    ),
                    const SizedBox(height: 24),
                    SettingsHeader(title: l10n.securityRecoverySection),
                    const _RecoveryTile(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final LocalAuthSettingsState state;

  const _StatusHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locked = state.isPinSet || state.isBiometricEnabled;
    final color = locked ? scheme.primary : scheme.error;

    return AppCard(
      accent: color,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.24)),
            ),
            child: Icon(
              locked ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locked
                      ? l10n.securityStatusOnTitle
                      : l10n.securityStatusOffTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  locked
                      ? l10n.securityStatusOnSubtitle
                      : l10n.securityStatusOffSubtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTile extends StatelessWidget {
  final LocalAuthSettingsState state;

  const _PinTile({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<LocalAuthSettingsBloc>();

    return SecurityTile(
      icon: Icons.pin_rounded,
      title: l10n.pinCardTitle,
      subtitle:
          state.isPinSet ? l10n.pinCardOnSubtitle : l10n.pinCardOffSubtitle,
      trailing: SecurityStatusPill(
        label: state.isPinSet ? l10n.stateOnLabel : l10n.stateOffLabel,
        on: state.isPinSet,
      ),
      footer: Row(
        children: [
          if (!state.isPinSet)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _createPin(context, bloc),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.createPin),
              ),
            )
          else ...[
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _changePin(context, bloc),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(l10n.changePin),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _removePin(context, bloc),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(l10n.removePin),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createPin(
      BuildContext context, LocalAuthSettingsBloc bloc) async {
    final l10n = context.l10n;
    final pins = await PinEntryPage.show(
      context,
      pageTitle: l10n.createPinTitle,
      steps: [
        PinPromptStep(
          title: l10n.pinEntryNewTitle,
          subtitle: l10n.pinEntryNewSubtitle,
        ),
        PinPromptStep(
          title: l10n.pinEntryRepeatTitle,
          subtitle: l10n.pinEntryRepeatSubtitle,
          confirmsPrevious: true,
        ),
      ],
    );
    if (pins == null || pins.length != 2) return;
    bloc.add(SavePinEvent(pin: pins[0], confirmPin: pins[1]));
  }

  Future<void> _changePin(
      BuildContext context, LocalAuthSettingsBloc bloc) async {
    final l10n = context.l10n;
    final repository = getIt<LocalAuthRepository>();
    final pins = await PinEntryPage.show(
      context,
      pageTitle: l10n.changePinTitle,
      steps: [
        PinPromptStep(
          title: l10n.pinEntryCurrentTitle,
          subtitle: l10n.pinEntryCurrentSubtitle,
          verify: repository.verifyPin,
          verifyErrorText: l10n.msgCurrentPinIsIncorrect,
        ),
        PinPromptStep(
          title: l10n.pinEntryNewTitle,
          subtitle: l10n.pinEntryNewSubtitle,
        ),
        PinPromptStep(
          title: l10n.pinEntryRepeatTitle,
          subtitle: l10n.pinEntryRepeatSubtitle,
          confirmsPrevious: true,
        ),
      ],
    );
    if (pins == null || pins.length != 3) return;
    bloc.add(ChangePinEvent(
      currentPin: pins[0],
      newPin: pins[1],
      confirmPin: pins[2],
    ));
  }

  Future<void> _removePin(
      BuildContext context, LocalAuthSettingsBloc bloc) async {
    final l10n = context.l10n;
    final repository = getIt<LocalAuthRepository>();
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.deletePinTitle,
      message: l10n.deletePinConfirmMessage,
      confirmText: l10n.removePin,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;

    final pins = await PinEntryPage.show(
      context,
      pageTitle: l10n.verifyPinTitle,
      steps: [
        PinPromptStep(
          title: l10n.pinEntryCurrentTitle,
          subtitle: l10n.pinEntryCurrentSubtitle,
          verify: repository.verifyPin,
          verifyErrorText: l10n.msgCurrentPinIsIncorrect,
        ),
      ],
    );
    if (pins == null || pins.isEmpty) return;
    bloc.add(DeletePinEvent(currentPin: pins[0]));
  }
}

class _BiometricTile extends StatelessWidget {
  final LocalAuthSettingsState state;

  const _BiometricTile({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final available = state.isBiometricAvailable;
    final canToggle = available && state.isPinSet;

    final subtitle = !available
        ? l10n.biometricCardSubtitleUnavailable
        : !state.isPinSet
            ? l10n.msgCreateAPinFirst2
            : state.isBiometricEnabled
                ? l10n.biometricEnabledSubtitle
                : l10n.biometricDisabledSubtitle;

    return SecurityTile(
      icon: Icons.fingerprint_rounded,
      title: l10n.biometricLoginTitle,
      subtitle: subtitle,
      enabled: canToggle,
      trailing: Switch.adaptive(
        value: state.isBiometricEnabled,
        onChanged: canToggle
            ? (value) => context.read<LocalAuthSettingsBloc>().add(
                  ToggleBiometricEvent(
                    enable: value,
                    reason: l10n.biometricReason,
                    signInTitle: l10n.biometricLoginTitle,
                    cancelButton: l10n.cancelLabel,
                  ),
                )
            : null,
      ),
    );
  }
}

class _PrivacyGuardTile extends StatelessWidget {
  final LocalAuthSettingsState state;

  const _PrivacyGuardTile({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SecurityTile(
      icon: Icons.blur_on_rounded,
      title: l10n.privacyGuardCardTitle,
      subtitle: l10n.privacyGuardCardSubtitle,
      trailing: Switch.adaptive(
        value: state.isPrivacyGuardEnabled,
        onChanged: (value) => context
            .read<LocalAuthSettingsBloc>()
            .add(TogglePrivacyGuardEvent(enable: value)),
      ),
    );
  }
}

class _BackgroundLockTile extends StatelessWidget {
  final LocalAuthSettingsState state;
  final List<int> options;

  const _BackgroundLockTile({required this.state, required this.options});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = state.backgroundLockTimeoutSeconds;
    var selected = options.indexOf(current);
    if (selected < 0) selected = 0;

    return SecurityTile(
      icon: Icons.timer_outlined,
      title: l10n.backgroundLockTitle,
      subtitle: l10n.backgroundLockCardSubtitle,
      trailing: SecurityStatusPill(
        label: current > 0
            ? formatLockDuration(l10n, current)
            : l10n.stateOffLabel,
        on: current > 0,
      ),
      footer: SecurityChoiceChips(
        labels: [
          for (final seconds in options)
            seconds == 0
                ? l10n.backgroundLockSubtitleOff
                : formatLockDuration(l10n, seconds),
        ],
        selectedIndex: selected,
        enabled: state.isPinSet || state.isBiometricEnabled,
        onSelected: (index) => context
            .read<LocalAuthSettingsBloc>()
            .add(UpdateBackgroundLockTimeoutEvent(seconds: options[index])),
      ),
    );
  }
}

class _RecoveryTile extends StatelessWidget {
  const _RecoveryTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SecurityTile(
      icon: Icons.help_outline_rounded,
      title: l10n.recoveryCardTitle,
      subtitle: l10n.recoveryCardSubtitle,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: () async {
        final bloc = context.read<LocalAuthSettingsBloc>();
        final reset = await PinRecoveryPage.show(context);
        if (reset == true) bloc.add(LoadSettingsEvent());
      },
    );
  }
}
