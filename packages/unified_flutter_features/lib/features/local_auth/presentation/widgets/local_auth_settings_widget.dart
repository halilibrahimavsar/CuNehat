import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/core/texts/local_auth_texts.dart';
import '../../../../shared_features/dialog/ibo_dialog.dart';
import '../../../../shared_features/snackbar/ibo_snackbar.dart';
import '../../data/local_auth_repository.dart';
import '../bloc/local_auth_status.dart';
import '../bloc/settings/local_auth_settings_bloc.dart';
import '../bloc/settings/local_auth_settings_event.dart';
import '../bloc/settings/local_auth_notice.dart';
import '../bloc/settings/local_auth_settings_state.dart';
import 'local_auth_settings_sections.dart';
import 'local_auth_settings_style.dart';
import 'pin_input_dialog.dart';

/// A customizable settings widget for local authentication.
///
/// This widget provides a complete interface for managing:
/// - PIN creation, change, and deletion
/// - Biometric authentication toggle
/// - Privacy Guard settings
/// - Background lock timeout configuration
///
/// Example usage:
/// ```dart
/// LocalAuthSettingsWidget(
///   repository: myRepository,
///   style: LocalAuthSettingsStyle(
///     sectionTitleStyle: TextStyle(fontSize: 18),
///   ),
///   onPinChanged: () => print('PIN changed'),
/// )
/// ```
class LocalAuthSettingsWidget extends StatefulWidget {
  final LocalAuthRepository repository;
  final LocalAuthSettingsStyle style;
  final VoidCallback? onPinChanged;
  final VoidCallback? onBiometricToggled;
  final VoidCallback? onPrivacyGuardToggled;
  final VoidCallback? onBackgroundLockChanged;
  final Widget? header;
  final bool showHeader;
  final bool showPinSection;
  final bool showBiometricSection;
  final bool showPrivacyGuardSection;
  final bool showBackgroundLockSection;
  final LocalAuthTexts texts;

  const LocalAuthSettingsWidget({
    super.key,
    required this.repository,
    this.style = const LocalAuthSettingsStyle(),
    this.onPinChanged,
    this.onBiometricToggled,
    this.onPrivacyGuardToggled,
    this.onBackgroundLockChanged,
    this.header,
    this.showHeader = true,
    this.showPinSection = true,
    this.showBiometricSection = true,
    this.showPrivacyGuardSection = true,
    this.showBackgroundLockSection = true,
    this.texts = const LocalAuthTexts(),
  });

  @override
  State<LocalAuthSettingsWidget> createState() =>
      _LocalAuthSettingsWidgetState();
}

class _LocalAuthSettingsWidgetState extends State<LocalAuthSettingsWidget> {
  late final LocalAuthSettingsBloc _bloc;
  LocalAuthSettingsState? _previousState;

  @override
  void initState() {
    super.initState();
    _bloc = LocalAuthSettingsBloc(repository: widget.repository);
    _bloc.add(LoadSettingsEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<LocalAuthSettingsBloc, LocalAuthSettingsState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          final sections = <Widget>[];
          void addSection(Widget section) {
            if (sections.isNotEmpty) {
              sections.add(SizedBox(height: widget.style.sectionSpacing));
            }
            sections.add(section);
          }

          if (widget.showHeader) {
            addSection(LocalAuthSettingsHeader(
              state: state,
              style: widget.style,
              header: widget.header,
              texts: widget.texts,
            ));
          }
          if (widget.showPinSection) {
            addSection(LocalAuthPinSection(
              style: widget.style,
              state: state,
              onCreatePin: _showCreatePinDialog,
              onChangePin: _showChangePinDialog,
              onDeletePin: _showDeletePinDialog,
              texts: widget.texts,
            ));
          }
          if (widget.showBiometricSection) {
            addSection(LocalAuthBiometricSection(
              style: widget.style,
              state: state,
              onToggle: (value) => _bloc.add(ToggleBiometricEvent(
                enable: value,
                reason: widget.texts.biometricReason,
                signInTitle: widget.texts.biometricLoginTitle,
                cancelButton: widget.texts.cancelLabel,
              )),
              texts: widget.texts,
            ));
          }
          if (widget.showPrivacyGuardSection) {
            addSection(LocalAuthPrivacyGuardSection(
              style: widget.style,
              state: state,
              onToggle: (value) =>
                  _bloc.add(TogglePrivacyGuardEvent(enable: value)),
              texts: widget.texts,
            ));
          }
          if (widget.showBackgroundLockSection) {
            addSection(LocalAuthBackgroundLockSection(
              style: widget.style,
              state: state,
              onTimeoutSelected: (seconds) =>
                  _bloc.add(UpdateBackgroundLockTimeoutEvent(seconds: seconds)),
              texts: widget.texts,
            ));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: widget.style.sectionPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections,
            ),
          );
        },
      ),
    );
  }

  /// Bloc'un tipli sonucunu bu katmanın diline çevirir. Eskiden burada
  /// İngilizce dize eşleştirmesi vardı; eşleşmeyen mesaj (ör. gizlilik
  /// perdesi) kullanıcıya İngilizce çıkıyordu.
  String? _noticeText(LocalAuthSettingsState state) {
    final texts = widget.texts;
    switch (state.notice) {
      case null:
        return null;
      case LocalAuthNotice.pinCreated:
        return texts.msgPINSavedSuccessfully;
      case LocalAuthNotice.pinUpdated:
        return texts.msgPINUpdatedSuccessfully;
      case LocalAuthNotice.pinRemoved:
        return texts.msgPINRemoved;
      case LocalAuthNotice.pinAlreadyExists:
        return texts.msgPINAlreadyExistsUse;
      case LocalAuthNotice.pinsDoNotMatch:
        return texts.msgPINsDoNotMatch;
      case LocalAuthNotice.newPinsDoNotMatch:
        return texts.msgNewPinValuesDo;
      case LocalAuthNotice.currentPinIncorrect:
        return texts.msgCurrentPinIsIncorrect;
      case LocalAuthNotice.createPinFirst:
        return texts.msgCreateAPinFirst;
      case LocalAuthNotice.biometricNotSupported:
        return texts.msgBiometricAuthenticationIsNot;
      case LocalAuthNotice.biometricFailed:
        return texts.msgBiometricAuthenticationFailed;
      case LocalAuthNotice.biometricEnabled:
        return texts.msgBiometricLoginEnabled;
      case LocalAuthNotice.biometricDisabled:
        return texts.msgBiometricLoginDisabled;
      case LocalAuthNotice.privacyGuardEnabled:
        return '${texts.privacyGuardTitle} ${texts.stateOnLabel}';
      case LocalAuthNotice.privacyGuardDisabled:
        return '${texts.privacyGuardTitle} ${texts.stateOffLabel}';
      case LocalAuthNotice.backgroundLockNeedsAuth:
        return texts.msgPINOrBiometricLogin;
      case LocalAuthNotice.backgroundLockWithPrivacyGuard:
        return texts.msgBackgroundLockAndPrivacy;
      case LocalAuthNotice.backgroundLockUpdated:
        return '${texts.backgroundLockTitle} ${texts.stateOnLabel}';
      case LocalAuthNotice.backgroundLockDisabled:
        return '${texts.backgroundLockTitle} ${texts.stateOffLabel}';
      case LocalAuthNotice.unexpectedError:
        return state.message;
    }
  }

  void _handleStateChanges(BuildContext context, LocalAuthSettingsState state) {
    final noticeText = _noticeText(state);
    if (noticeText != null) {
      if (state.status == SettingsStatus.error) {
        IboSnackbar.showError(context, noticeText);
      } else if (state.status == SettingsStatus.success) {
        IboSnackbar.showSuccess(context, noticeText);
      }
    }

    if (state.status == SettingsStatus.success) {
      final previous = _previousState;
      const pinNotices = {
        LocalAuthNotice.pinCreated,
        LocalAuthNotice.pinUpdated,
        LocalAuthNotice.pinRemoved,
      };
      if (previous != null &&
          (previous.isPinSet != state.isPinSet ||
              pinNotices.contains(state.notice))) {
        widget.onPinChanged?.call();
      }
      if (previous != null &&
          previous.isBiometricEnabled != state.isBiometricEnabled) {
        widget.onBiometricToggled?.call();
      }
      if (previous != null &&
          previous.isPrivacyGuardEnabled != state.isPrivacyGuardEnabled) {
        widget.onPrivacyGuardToggled?.call();
      }
      if (previous != null &&
          previous.backgroundLockTimeoutSeconds !=
              state.backgroundLockTimeoutSeconds) {
        widget.onBackgroundLockChanged?.call();
      }
    }

    _previousState = state;
  }

  Future<void> _showCreatePinDialog() async {
    final currentContext = context;
    final pins = await PinInputDialog.show(
      context: currentContext,
      title: widget.texts.createPinTitle,
      fieldLabels: [
        widget.texts.pinFieldLabel,
        widget.texts.confirmPinFieldLabel,
      ],
      confirmLabel: widget.texts.saveLabel,
      cancelLabel: widget.texts.cancelLabel,
      validationMessage: widget.texts.pinValidationMessage,
      mismatchMessage: widget.texts.pinMismatchMessage,
    );

    if (pins != null && pins.length == 2) {
      _bloc.add(SavePinEvent(
        pin: pins[0],
        confirmPin: pins[1],
      ));
    }
  }

  Future<void> _showChangePinDialog() async {
    final currentContext = context;
    final pins = await PinInputDialog.show(
      context: currentContext,
      title: widget.texts.changePinTitle,
      fieldLabels: [
        widget.texts.currentPinFieldLabel,
        widget.texts.newPinFieldLabel,
        widget.texts.confirmNewPinFieldLabel,
      ],
      confirmLabel: widget.texts.changeLabel,
      cancelLabel: widget.texts.cancelLabel,
      validationMessage: widget.texts.pinValidationMessage,
      mismatchMessage: widget.texts.pinMismatchMessage,
    );

    if (pins != null && pins.length == 3) {
      _bloc.add(ChangePinEvent(
        currentPin: pins[0],
        newPin: pins[1],
        confirmPin: pins[2],
      ));
    }
  }

  Future<void> _showDeletePinDialog() async {
    final currentContext = context;
    final confirmed = await IboDialog.showConfirmation(
      currentContext,
      widget.texts.deletePinTitle,
      widget.texts.deletePinConfirmMessage,
      confirmText: widget.texts.removeLabel,
      cancelText: widget.texts.cancelLabel,
    );
    if (!mounted) return;

    if (confirmed == true) {
      final pins = await PinInputDialog.show(
        context: context,
        title: widget.texts.verifyPinTitle,
        fieldLabels: [widget.texts.currentPinFieldLabel],
        confirmLabel: widget.texts.verifyLabel,
        cancelLabel: widget.texts.cancelLabel,
        validationMessage: widget.texts.pinValidationMessage,
        mismatchMessage: widget.texts.pinMismatchMessage,
      );
      if (!mounted) return;

      if (pins != null && pins.isNotEmpty) {
        _bloc.add(DeletePinEvent(currentPin: pins[0]));
      }
    }
  }
}
