import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared_features/common/ibo_glass_surface.dart';
import '../../../../shared_features/glass_button/ibo_glass_button.dart';
import '../constants/local_auth_constants.dart';

/// Reusable PIN input dialog with proper controller management
class PinInputDialog extends StatefulWidget {
  final String title;
  final List<String> fieldLabels;
  final String confirmLabel;
  final String cancelLabel;

  const PinInputDialog({
    super.key,
    required this.title,
    required this.fieldLabels,
    this.confirmLabel = LocalAuthConstants.saveButtonText,
    this.cancelLabel = LocalAuthConstants.cancelButtonText2,
  });

  @override
  State<PinInputDialog> createState() => _PinInputDialogState();

  /// Show the dialog and return the entered PINs
  static Future<List<String>?> show({
    required BuildContext context,
    required String title,
    required List<String> fieldLabels,
    String? confirmLabel,
    String? cancelLabel,
  }) async {
    return showDialog<List<String>>(
      context: context,
      builder: (context) => PinInputDialog(
        title: title,
        fieldLabels: fieldLabels,
        confirmLabel: confirmLabel ?? LocalAuthConstants.saveButtonText,
        cancelLabel: cancelLabel ?? LocalAuthConstants.cancelButtonText2,
      ),
    );
  }
}

class _PinInputDialogState extends State<PinInputDialog> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.fieldLabels.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.fieldLabels.length,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      hintText: '******',
      counterText: '',
      filled: true,
      fillColor: theme.colorScheme.surface.withValues(alpha: 0.65),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 1.4,
        ),
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: IboGlassSurface(
        padding: const EdgeInsets.all(20),
        style: IboGlassStyle(
          borderRadius: BorderRadius.circular(24),
          backgroundColor: theme.colorScheme.surface,
          backgroundOpacity: 0.9,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < widget.fieldLabels.length; i++) ...[
                TextFormField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  maxLength: 6,
                  textInputAction: i < widget.fieldLabels.length - 1
                      ? TextInputAction.next
                      : TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: inputDecoration.copyWith(
                    labelText: widget.fieldLabels[i],
                  ),
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return LocalAuthConstants.pinValidationError;
                    }
                    // Only compare the last field with the previous one (for change PIN: new vs confirm)
                    if (i > 0 &&
                        i == widget.fieldLabels.length - 1 &&
                        value != _controllers[i - 1].text) {
                      return LocalAuthConstants.pinMatchError;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (i < widget.fieldLabels.length - 1) {
                      FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                    } else {
                      _submit();
                    }
                  },
                ),
                if (i < widget.fieldLabels.length - 1)
                  const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: IboGlassButton(
                      text: widget.cancelLabel,
                      height: 44,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IboGlassButton(
                      text: widget.confirmLabel,
                      height: 44,
                      onPressed: _submit,
                      foregroundColor: theme.colorScheme.primary,
                      borderColor:
                          theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(
        context,
        _controllers.map((c) => c.text).toList(),
      );
    }
  }
}
