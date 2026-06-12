import 'package:flutter/material.dart';
import 'package:unified_flutter_features/core/texts/local_auth_texts.dart';
import '../bloc/settings/local_auth_settings_state.dart';
import '../utils/local_auth_utils.dart';
import 'local_auth_settings_components.dart';
import 'local_auth_settings_style.dart';

class LocalAuthSettingsHeader extends StatelessWidget {
  final LocalAuthSettingsState state;
  final LocalAuthSettingsStyle style;
  final Widget? header;
  final LocalAuthTexts texts;

  const LocalAuthSettingsHeader({
    super.key,
    required this.state,
    required this.style,
    this.header,
    this.texts = const LocalAuthTexts(),
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

    final isEn = texts.logoutLabel == 'Logout';

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
                    Text(texts.securitySettings, style: headerTitleStyle),
                    const SizedBox(height: 4),
                    Text(texts.manageYourAppSecurity,
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
                label: state.isPinSet
                    ? '${texts.pinLockTitle} ${isEn ? 'On' : 'Açık'}'
                    : '${texts.pinLockTitle} ${isEn ? 'Off' : 'Kapalı'}',
                enabled: state.isPinSet,
              ),
              LocalAuthStatusChip(
                label: state.isBiometricEnabled
                    ? '${texts.biometricLoginTitle} ${isEn ? 'On' : 'Açık'}'
                    : '${texts.biometricLoginTitle} ${isEn ? 'Off' : 'Kapalı'}',
                enabled: state.isBiometricEnabled,
              ),
              LocalAuthStatusChip(
                label: state.isPrivacyGuardEnabled
                    ? '${texts.privacyGuardTitle} ${isEn ? 'On' : 'Açık'}'
                    : '${texts.privacyGuardTitle} ${isEn ? 'Off' : 'Kapalı'}',
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
  final LocalAuthTexts texts;

  const LocalAuthPinSection({
    super.key,
    required this.style,
    required this.state,
    required this.onCreatePin,
    required this.onChangePin,
    required this.onDeletePin,
    this.texts = const LocalAuthTexts(),
  });

  @override
  Widget build(BuildContext context) {
    final isEn = texts.logoutLabel == 'Logout';
    return LocalAuthSectionCard(
      style: style,
      title: texts.pinLockTitle,
      subtitle: state.isPinSet ? texts.pinEnabledSubtitle : texts.pinNotSetSubtitle,
      icon: Icons.dialpad,
      trailing: LocalAuthStatusChip(
        label: state.isPinSet ? (isEn ? 'On' : 'Açık') : (isEn ? 'Off' : 'Kapalı'),
        enabled: state.isPinSet,
      ),
      children: [
        if (!state.isPinSet)
          LocalAuthActionButton(
            style: style,
            text: texts.createPin,
            icon: Icons.add,
            onPressed: onCreatePin,
          ),
        if (state.isPinSet) ...[
          LocalAuthActionButton(
            style: style,
            text: texts.changePin,
            icon: Icons.edit,
            onPressed: onChangePin,
          ),
          SizedBox(height: style.buttonSpacing),
          LocalAuthActionButton(
            style: style,
            text: texts.removePin,
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
  final LocalAuthTexts texts;

  const LocalAuthBiometricSection({
    super.key,
    required this.style,
    required this.state,
    required this.onToggle,
    this.texts = const LocalAuthTexts(),
  });

  @override
  Widget build(BuildContext context) {
    final isEn = texts.logoutLabel == 'Logout';
    if (!state.isBiometricAvailable) {
      return LocalAuthSectionCard(
        style: style,
        title: texts.biometricLoginTitle,
        subtitle: texts.biometricNotAvailableSubtitle,
        icon: Icons.fingerprint,
        trailing: LocalAuthStatusChip(
          label: isEn ? 'Unsupported' : 'Desteklenmiyor',
          enabled: false,
        ),
        children: [
          LocalAuthInfoBanner(
            message: texts.msgBiometricAuthenticationCannotBe,
            icon: Icons.block,
          ),
        ],
      );
    }

    final canToggle = state.isPinSet || state.isBiometricEnabled;

    return LocalAuthSectionCard(
      style: style,
      title: texts.biometricLoginTitle,
      subtitle: state.isBiometricEnabled
          ? texts.biometricEnabledSubtitle
          : texts.biometricDisabledSubtitle,
      icon: Icons.fingerprint,
      trailing: LocalAuthStatusChip(
        label: state.isBiometricEnabled ? (isEn ? 'On' : 'Açık') : (isEn ? 'Off' : 'Kapalı'),
        enabled: state.isBiometricEnabled,
      ),
      children: [
        LocalAuthSwitchTile(
          style: style,
          title: texts.biometricAuthTileTitle,
          subtitle: state.isBiometricEnabled
              ? texts.biometricAuthTileSubtitleOn
              : texts.biometricAuthTileSubtitleOff,
          value: state.isBiometricEnabled,
          icon: Icons.fingerprint,
          onChanged: canToggle ? onToggle : null,
        ),
        if (!state.isPinSet) ...[
          SizedBox(height: style.tileSpacing),
          LocalAuthInfoBanner(
            message: texts.msgCreateAPinFirst2,
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
  final LocalAuthTexts texts;

  const LocalAuthPrivacyGuardSection({
    super.key,
    required this.style,
    required this.state,
    required this.onToggle,
    this.texts = const LocalAuthTexts(),
  });

  @override
  Widget build(BuildContext context) {
    final isEn = texts.logoutLabel == 'Logout';
    return LocalAuthSectionCard(
      style: style,
      title: texts.privacyGuardTitle,
      subtitle: state.isPrivacyGuardEnabled
          ? texts.privacyGuardEnabledSubtitle
          : texts.privacyGuardDisabledSubtitle,
      icon: Icons.privacy_tip_outlined,
      trailing: LocalAuthStatusChip(
        label: state.isPrivacyGuardEnabled ? (isEn ? 'On' : 'Açık') : (isEn ? 'Off' : 'Kapalı'),
        enabled: state.isPrivacyGuardEnabled,
      ),
      children: [
        LocalAuthSwitchTile(
          style: style,
          title: texts.screenProtectionTileTitle,
          subtitle: state.isPrivacyGuardEnabled
              ? texts.screenProtectionTileSubtitleOn
              : texts.screenProtectionTileSubtitleOff,
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
  final LocalAuthTexts texts;

  const LocalAuthBackgroundLockSection({
    super.key,
    required this.style,
    required this.state,
    required this.onTimeoutSelected,
    this.texts = const LocalAuthTexts(),
  });

  @override
  Widget build(BuildContext context) {
    final currentTimeout = state.backgroundLockTimeoutSeconds;
    final canEdit = state.isPinSet || state.isBiometricEnabled;
    final isEn = texts.logoutLabel == 'Logout';

    final subtitle = currentTimeout > 0
        ? '${texts.backgroundLockSubtitlePrefix}${_formatDuration(currentTimeout)} (${_getAuthMethod(state, texts)})'
        : (isEn ? 'Off' : 'Kapalı');

    return LocalAuthSectionCard(
      style: style,
      title: texts.backgroundLockTitle,
      subtitle: subtitle,
      icon: Icons.lock_outline,
      trailing: LocalAuthStatusChip(
        label: currentTimeout > 0 ? (isEn ? 'On' : 'Açık') : (isEn ? 'Off' : 'Kapalı'),
        enabled: currentTimeout > 0,
      ),
      children: [
        Text(
          texts.backgroundLockTileTitle,
          style: style.tileSubtitleStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
        ),
        if (!canEdit) ...[
          SizedBox(height: style.tileSpacing),
          LocalAuthInfoBanner(
            message: texts.backgroundLockTileSubtitle,
          ),
        ],
        SizedBox(height: style.tileSpacing),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LocalAuthChoiceChip(
              label: isEn ? 'Off' : 'Kapalı',
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
            texts.backgroundLockTileInfo,
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

  String _getAuthMethod(LocalAuthSettingsState state, LocalAuthTexts texts) {
    final isEn = texts.logoutLabel == 'Logout';
    if (state.isBiometricEnabled) {
      return isEn ? 'biometric authentication' : 'biyometrik kimlik doğrulama';
    } else if (state.isPinSet) {
      return 'PIN';
    }
    return isEn ? 'authentication' : 'kimlik doğrulama';
  }
}
