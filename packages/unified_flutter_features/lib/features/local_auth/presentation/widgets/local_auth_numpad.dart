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

  /// Kısa ekran eşiği: tam boy tuş takımı 360dp. 568dp yüksekliğindeki
  /// telefonda başlık ve noktalarla birlikte sığmıyor, "0" ve silme tuşu
  /// ilk bakışta ekranın altında kalıyordu.
  static const double compactBelowHeight = 680;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < compactBelowHeight;
    final size = compact
        ? LocalAuthConstants.numpadButtonSizeCompact
        : LocalAuthConstants.numpadButtonSize;
    final spacing = compact
        ? LocalAuthConstants.numpadSpacingCompact
        : LocalAuthConstants.numpadSpacing;
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
                    size: size,
                    isLockedOut: isLockedOut,
                    onTap: onDigit,
                  ),
              ],
            ),
            SizedBox(height: spacing),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                icon: showBiometric ? Icons.fingerprint_rounded : null,
                size: size,
                isLockedOut: isLockedOut,
                onTap: onBiometric,
              ),
              _NumberButton(
                digit: '0',
                size: size,
                isLockedOut: isLockedOut,
                onTap: onDigit,
              ),
              _ActionButton(
                icon: Icons.backspace_outlined,
                size: size,
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
  final double size;
  final bool isLockedOut;
  final ValueChanged<String> onTap;

  const _NumberButton({
    required this.size,
    required this.digit,
    required this.isLockedOut,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
  final double size;
  final bool isLockedOut;
  final VoidCallback onTap;

  const _ActionButton({
    required this.size,
    required this.icon,
    required this.isLockedOut,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(size / 2);
    final isEnabled = !isLockedOut;

    if (icon == null) return SizedBox(width: size);
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
