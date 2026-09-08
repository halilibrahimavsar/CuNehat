import 'dart:async';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/settings/presentation/bloc/pin_recovery/pin_recovery_cubit.dart';
import 'package:cunehat/features/settings/presentation/widgets/security/pin_entry_page.dart';
import 'package:cunehat/features/settings/presentation/widgets/security/security_notice_text.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

/// "PIN'imi unuttum" akışı.
///
/// Rota DEĞİL, imperatif olarak açılır: kilit ekranından da açılması gerekiyor
/// ve router kilitliyken TÜM konumları `/lock`'a yönlendirdiği için bir
/// GoRouter rotası anında geri atılırdı.
class PinRecoveryPage extends StatelessWidget {
  const PinRecoveryPage({super.key});

  /// Açar; PIN sıfırlandıysa `true` döner.
  static Future<bool?> show(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const PinRecoveryPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PinRecoveryCubit>(
      create: (_) =>
          PinRecoveryCubit(repository: getIt<LocalAuthRepository>())..load(),
      child: const _PinRecoveryView(),
    );
  }
}

class _PinRecoveryView extends StatefulWidget {
  const _PinRecoveryView();

  @override
  State<_PinRecoveryView> createState() => _PinRecoveryViewState();
}

class _PinRecoveryViewState extends State<_PinRecoveryView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Sayaç dakika hassasiyetinde gösteriliyor; saniyede bir uyandırmaya gerek
    // yok.
    _ticker = Timer.periodic(
      const Duration(seconds: 20),
      (_) => context.read<PinRecoveryCubit>().refreshRemaining(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: Text(l10n.pinRecoveryTitle)),
      body: BlocConsumer<PinRecoveryCubit, PinRecoveryState>(
        listenWhen: (prev, curr) => prev.notice != curr.notice,
        listener: (context, state) {
          final text = pinRecoveryNoticeText(l10n, state.notice);
          if (text == null) return;
          switch (state.notice) {
            case PinRecoveryNotice.pinReset:
            case PinRecoveryNotice.timedResetStarted:
            case PinRecoveryNotice.timedResetCancelled:
              AppMessenger.success(text);
            default:
              AppMessenger.error(text);
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32)
                .plusSystemBottom(context),
            children: [
              Text(
                l10n.pinRecoveryIntro,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _DeviceCredentialCard(state: state),
              const SizedBox(height: 12),
              _TimedResetCard(state: state),
              if (state.canResetNow) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _setNewPin(context),
                  icon: const Icon(Icons.lock_reset_rounded),
                  label: Text(l10n.recoveryResetAction),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _setNewPin(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<PinRecoveryCubit>();
    final navigator = Navigator.of(context);

    final pins = await PinEntryPage.show(
      context,
      pageTitle: l10n.recoveryResetAction,
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

    final ok = await cubit.resetPin(pins[0]);
    if (ok) navigator.pop(true);
  }
}

class _DeviceCredentialCard extends StatelessWidget {
  final PinRecoveryState state;

  const _DeviceCredentialCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final available = state.deviceCredentialAvailable;

    return AppCard(
      accent: available ? scheme.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.phonelink_lock_rounded,
            title: l10n.recoveryDeviceTitle,
            done: state.deviceVerified,
          ),
          const SizedBox(height: 10),
          Text(
            available
                ? l10n.recoveryDeviceBody
                : l10n.recoveryDeviceUnavailable,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (available && !state.deviceVerified) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: () =>
                  context.read<PinRecoveryCubit>().verifyWithDeviceCredential(
                        reason: l10n.recoveryDeviceReason,
                        signInTitle: l10n.pinRecoveryTitle,
                        cancelButton: l10n.cancelLabel,
                      ),
              child: Text(l10n.recoveryDeviceAction),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimedResetCard extends StatelessWidget {
  final PinRecoveryState state;

  const _TimedResetCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pending = state.hasPendingTimedReset;
    final ready = state.resetRequestedAt != null && !pending;

    return AppCard(
      accent: pending ? scheme.tertiary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.hourglass_bottom_rounded,
            title: l10n.recoveryTimedTitle,
            done: ready,
          ),
          const SizedBox(height: 10),
          Text(
            ready
                ? l10n.recoveryTimedReady
                : pending
                    ? l10n.recoveryTimedPending(
                        _formatRemaining(context, state.remaining!))
                    : l10n.recoveryTimedBody(
                        PinRecoveryCubit.timedResetDelay.inHours),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (pending) ...[
            const SizedBox(height: 10),
            Text(
              l10n.recoveryTimedWarning,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: 14),
          if (state.resetRequestedAt == null)
            FilledButton.tonal(
              onPressed: () =>
                  context.read<PinRecoveryCubit>().startTimedReset(),
              child: Text(l10n.recoveryTimedStart),
            )
          else
            OutlinedButton(
              onPressed: () =>
                  context.read<PinRecoveryCubit>().cancelTimedReset(),
              child: Text(l10n.recoveryTimedCancel),
            ),
        ],
      ),
    );
  }

  String _formatRemaining(BuildContext context, Duration remaining) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return context.l10n.remainingHoursMinutes(hours, minutes);
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool done;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (done)
          Icon(Icons.check_circle_rounded, size: 20, color: scheme.primary),
      ],
    );
  }
}
