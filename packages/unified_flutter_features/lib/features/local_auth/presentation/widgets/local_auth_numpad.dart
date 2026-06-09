import 'package:flutter/material.dart';
import '../../../../shared_features/common/ibo_glass_surface.dart';
import '../constants/local_auth_constants.dart';

class LocalAuthNumpad extends StatelessWidget {
  final bool isLockedOut;
  final bool showBiometric;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onBiometric;

  const LocalAuthNumpad({
    super.key,
    required this.isLockedOut,
    required this.showBiometric,
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var j = 1; j <= 3; j++)
                  _NumberButton(
                    digit: (i * 3 + j).toString(),
                    isLockedOut: isLockedOut,
                    onTap: onDigit,
                  ),
              ],
            ),
            const SizedBox(height: LocalAuthConstants.numpadSpacing),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                icon: showBiometric ? Icons.fingerprint_rounded : null,
                isLockedOut: isLockedOut,
                onTap: onBiometric,
              ),
              _NumberButton(
                digit: '0',
                isLockedOut: isLockedOut,
                onTap: onDigit,
              ),
              _ActionButton(
                icon: Icons.backspace_outlined,
                isLockedOut: isLockedOut,
                onTap: onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String digit;
  final bool isLockedOut;
  final ValueChanged<String> onTap;

  const _NumberButton({
    required this.digit,
    required this.isLockedOut,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = LocalAuthConstants.numpadButtonSize;
    final radius = BorderRadius.circular(size / 2);
    final isEnabled = !isLockedOut;

    return InkWell(
      onTap: isEnabled ? () => onTap(digit) : null,
      borderRadius: radius,
      child: SizedBox(
        height: size,
        width: size,
        child: IboGlassSurface(
          padding: EdgeInsets.zero,
          style: IboGlassStyle(
            borderRadius: radius,
            backgroundColor: theme.colorScheme.surface,
            backgroundOpacity: isEnabled ? 0.88 : 0.5,
            borderColor: theme.colorScheme.primary
                .withValues(alpha: isEnabled ? 0.18 : 0.08),
            shadows: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final bool isLockedOut;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.isLockedOut,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = LocalAuthConstants.numpadButtonSize;
    final radius = BorderRadius.circular(size / 2);
    final isEnabled = !isLockedOut;

    if (icon == null) return const SizedBox(width: size);
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: radius,
      child: SizedBox(
        height: size,
        width: size,
        child: IboGlassSurface(
          padding: EdgeInsets.zero,
          style: IboGlassStyle(
            borderRadius: radius,
            backgroundColor: theme.colorScheme.surface,
            backgroundOpacity: isEnabled ? 0.8 : 0.4,
            borderColor: theme.colorScheme.primary
                .withValues(alpha: isEnabled ? 0.2 : 0.08),
            shadows: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 26,
              color: isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
