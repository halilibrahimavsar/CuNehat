import 'package:flutter/material.dart';
import '../bloc/settings/local_auth_settings_state.dart';
import '../utils/local_auth_utils.dart';
import 'local_auth_settings_components.dart';
import 'local_auth_settings_style.dart';

class LocalAuthSettingsHeader extends StatelessWidget {
  final LocalAuthSettingsState state;
  final LocalAuthSettingsStyle style;
  final Widget? header;

  const LocalAuthSettingsHeader({
    super.key,
    required this.state,
    required this.style,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (header != null) return header!;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final headerTitleStyle = style.headerTitleStyle ??
        theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700);
    final headerSubtitleStyle = style.headerSubtitleStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        );

    return Container(
      padding: style.headerPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.18),
            primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withValues(alpha: 0.25)),
                ),
                child: Icon(
                  Icons.security,
                  color: primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Security Settings', style: headerTitleStyle),
                    const SizedBox(height: 4),
                    Text('Manage your app security',
                        style: headerSubtitleStyle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              LocalAuthStatusChip(
                label: state.isPinSet ? 'PIN On' : 'PIN Off',
                enabled: state.isPinSet,
              ),
              LocalAuthStatusChip(
                label:
                    state.isBiometricEnabled ? 'Biometric On' : 'Biometric Off',
                enabled: state.isBiometricEnabled,
              ),
              LocalAuthStatusChip(
                label: state.isPrivacyGuardEnabled
                    ? 'Privacy Guard On'
                    : 'Privacy Guard Off',
                enabled: state.isPrivacyGuardEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LocalAuthPinSection extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final LocalAuthSettingsState state;
  final VoidCallback onCreatePin;
  final VoidCallback onChangePin;
  final VoidCallback onDeletePin;

  const LocalAuthPinSection({
    super.key,
    required this.style,
    required this.state,
    required this.onCreatePin,
    required this.onChangePin,
    required this.onDeletePin,
  });

  @override
  Widget build(BuildContext context) {
    return LocalAuthSectionCard(
      style: style,
      title: 'PIN Lock',
      subtitle: state.isPinSet ? 'PIN enabled' : 'PIN not set',
      icon: Icons.dialpad,
      trailing: LocalAuthStatusChip(
        label: state.isPinSet ? 'On' : 'Off',
        enabled: state.isPinSet,
      ),
      children: [
        if (!state.isPinSet)
          LocalAuthActionButton(
            style: style,
            text: 'Create PIN',
            icon: Icons.add,
            onPressed: onCreatePin,
          ),
        if (state.isPinSet) ...[
          LocalAuthActionButton(
            style: style,
            text: 'Change PIN',
            icon: Icons.edit,
            onPressed: onChangePin,
          ),
          SizedBox(height: style.buttonSpacing),
          LocalAuthActionButton(
            style: style,
            text: 'Remove PIN',
            icon: Icons.delete_outline,
            isDestructive: true,
            onPressed: onDeletePin,
          ),
        ],
      ],
    );
  }
}

class LocalAuthBiometricSection extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final LocalAuthSettingsState state;
  final ValueChanged<bool>? onToggle;

  const LocalAuthBiometricSection({
    super.key,
    required this.style,
    required this.state,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.isBiometricAvailable) {
      return LocalAuthSectionCard(
        style: style,
        title: 'Biometric Login',
        subtitle: 'Biometric authentication is not available on this device',
        icon: Icons.fingerprint,
        trailing: const LocalAuthStatusChip(
          label: 'Unsupported',
          enabled: false,
        ),
        children: const [
          LocalAuthInfoBanner(
            message: 'Biometric authentication cannot be used on this device.',
            icon: Icons.block,
          ),
        ],
      );
    }

    final canToggle = state.isPinSet || state.isBiometricEnabled;

    return LocalAuthSectionCard(
      style: style,
      title: 'Biometric Login',
      subtitle: state.isBiometricEnabled
          ? 'Biometric login enabled'
          : 'Biometric login disabled',
      icon: Icons.fingerprint,
      trailing: LocalAuthStatusChip(
        label: state.isBiometricEnabled ? 'On' : 'Off',
        enabled: state.isBiometricEnabled,
      ),
      children: [
        LocalAuthSwitchTile(
          style: style,
          title: 'Biometric Authentication',
          subtitle: state.isBiometricEnabled
              ? 'On - Sign in with fingerprint or face recognition'
              : 'Off',
          value: state.isBiometricEnabled,
          icon: Icons.fingerprint,
          onChanged: canToggle ? onToggle : null,
        ),
        if (!state.isPinSet) ...[
          SizedBox(height: style.tileSpacing),
          const LocalAuthInfoBanner(
            message: 'Create a PIN first to enable biometric login.',
          ),
        ],
      ],
    );
  }
}

class LocalAuthPrivacyGuardSection extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final LocalAuthSettingsState state;
  final ValueChanged<bool> onToggle;

  const LocalAuthPrivacyGuardSection({
    super.key,
    required this.style,
    required this.state,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LocalAuthSectionCard(
      style: style,
      title: 'Privacy Guard',
      subtitle: state.isPrivacyGuardEnabled
          ? 'Screen protection enabled'
          : 'Screen protection disabled',
      icon: Icons.privacy_tip_outlined,
      trailing: LocalAuthStatusChip(
        label: state.isPrivacyGuardEnabled ? 'On' : 'Off',
        enabled: state.isPrivacyGuardEnabled,
      ),
      children: [
        LocalAuthSwitchTile(
          style: style,
          title: 'Screen Protection',
          subtitle: state.isPrivacyGuardEnabled
              ? 'On - Hide content while app is in background'
              : 'Off',
          value: state.isPrivacyGuardEnabled,
          icon: Icons.privacy_tip_outlined,
          onChanged: onToggle,
        ),
      ],
    );
  }
}

class LocalAuthBackgroundLockSection extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final LocalAuthSettingsState state;
  final ValueChanged<int> onTimeoutSelected;

  const LocalAuthBackgroundLockSection({
    super.key,
    required this.style,
    required this.state,
    required this.onTimeoutSelected,
  });

  @override
  Widget build(BuildContext context) {
    final currentTimeout = state.backgroundLockTimeoutSeconds;
    final canEdit = state.isPinSet || state.isBiometricEnabled;

    final subtitle = currentTimeout > 0
        ? 'Locks after ${_formatDuration(currentTimeout)} (${_getAuthMethod(state)})'
        : 'Off';

    return LocalAuthSectionCard(
      style: style,
      title: 'Background Lock',
      subtitle: subtitle,
      icon: Icons.lock_outline,
      trailing: LocalAuthStatusChip(
        label: currentTimeout > 0 ? 'On' : 'Off',
        enabled: currentTimeout > 0,
      ),
      children: [
        Text(
          'Require ${_getAuthMethod(state)} when app stays in background',
          style: style.tileSubtitleStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
        ),
        if (!canEdit) ...[
          SizedBox(height: style.tileSpacing),
          const LocalAuthInfoBanner(
            message:
                'To enable background lock, set a PIN or enable biometric login.',
          ),
        ],
        SizedBox(height: style.tileSpacing),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LocalAuthChoiceChip(
              label: 'Off',
              selected: currentTimeout == 0,
              enabled: canEdit || currentTimeout == 0,
              onSelected: () => onTimeoutSelected(0),
            ),
            ...style.timeoutOptions.where((s) => s > 0).map(
                  (seconds) => LocalAuthChoiceChip(
                    label: _formatDuration(seconds),
                    selected: currentTimeout == seconds,
                    enabled: canEdit,
                    onSelected: () => onTimeoutSelected(seconds),
                  ),
                ),
          ],
        ),
        if (currentTimeout > 0) ...[
          const SizedBox(height: 10),
          Text(
            'Note: Authentication screen appears when returning to app.',
            style: style.tileSubtitleStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(int seconds) {
    return LocalAuthUtils.getRemainingTimeText(seconds);
  }

  String _getAuthMethod(LocalAuthSettingsState state) {
    if (state.isBiometricEnabled) {
      return 'biometric authentication';
    } else if (state.isPinSet) {
      return 'PIN';
    }
    return 'authentication';
  }
}
