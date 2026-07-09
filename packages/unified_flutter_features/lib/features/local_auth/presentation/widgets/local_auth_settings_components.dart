import 'package:flutter/material.dart';
import '../../../../shared_features/common/ibo_glass_surface.dart';
import '../../../../shared_features/glass_button/ibo_glass_button.dart';
import 'local_auth_settings_style.dart';

class LocalAuthStatusChip extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color? activeColor;
  final Color? inactiveColor;

  const LocalAuthStatusChip({
    super.key,
    required this.label,
    required this.enabled,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final active = activeColor ?? primary;
    final inactive = inactiveColor ?? Colors.grey;
    final bgColor = enabled
        ? active.withValues(alpha: 0.12)
        : inactive.withValues(alpha: 0.08);
    final borderColor = enabled
        ? active.withValues(alpha: 0.45)
        : inactive.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: enabled ? active : inactive,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class LocalAuthSectionCard extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;

  const LocalAuthSectionCard({
    super.key,
    required this.style,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerStyle = style.dividerStyle;
    final titleStyle = style.sectionTitleStyle ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final subtitleStyle = style.sectionSubtitleStyle ??
        theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]);

    return IboGlassSurface(
      style: style.cardStyle,
      padding: style.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: subtitleStyle),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          SizedBox(height: dividerStyle.spacing),
          Divider(
            height: 1,
            thickness: dividerStyle.thickness,
            color: dividerStyle.color ??
                theme.colorScheme.primary.withValues(alpha: 0.12),
            indent: dividerStyle.indent,
            endIndent: dividerStyle.endIndent,
          ),
          SizedBox(height: dividerStyle.spacing),
          ...children,
        ],
      ),
    );
  }
}

class LocalAuthSwitchTile extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool>? onChanged;

  const LocalAuthSwitchTile({
    super.key,
    required this.style,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onChanged != null;
    final activeColor = style.switchActiveColor ?? theme.colorScheme.primary;
    final highlight =
        value ? activeColor.withValues(alpha: 0.08) : Colors.transparent;

    return AnimatedContainer(
      duration: style.animationDuration,
      curve: style.animationCurve,
      decoration: BoxDecoration(
        color: highlight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              value ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedOpacity(
          duration: style.animationDuration,
          curve: style.animationCurve,
          opacity: enabled ? 1 : 0.55,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: style.tileSpacing / 2),
            child: Row(
              children: [
                _IconBadge(
                  icon: icon,
                  size: 40,
                  backgroundColor:
                      activeColor.withValues(alpha: enabled ? 0.12 : 0.06),
                  iconColor: enabled
                      ? activeColor
                      : activeColor.withValues(alpha: 0.5),
                ),
                SizedBox(width: style.tileSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: style.tileTitleStyle ??
                            theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: style.tileSubtitleStyle ??
                            theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: style.switchActiveColor,
                  inactiveThumbColor: style.switchInactiveColor,
                  activeTrackColor: style.switchTrackColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LocalAuthActionButton extends StatelessWidget {
  final LocalAuthSettingsStyle style;
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDestructive;

  const LocalAuthActionButton({
    super.key,
    required this.style,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : null;
    return SizedBox(
      width: double.infinity,
      child: IboGlassButton(
        text: text,
        onPressed: onPressed,
        height: style.buttonHeight,
        padding: style.buttonPadding,
        foregroundColor: color,
        borderColor: isDestructive ? Colors.red.withValues(alpha: 0.3) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              text,
              style: style.buttonTextStyle?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class LocalAuthInfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const LocalAuthInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            resolvedColor.withValues(alpha: 0.12),
            resolvedColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: resolvedColor, size: 18),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: resolvedColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class LocalAuthChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onSelected;

  const LocalAuthChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final borderColor = selected
        ? primary.withValues(alpha: 0.6)
        : Colors.grey.withValues(alpha: 0.35);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onSelected?.call() : null,
      backgroundColor: Colors.transparent,
      selectedColor: primary.withValues(alpha: 0.15),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected ? primary : Colors.grey[600],
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const _IconBadge({
    required this.icon,
    this.size = 46,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedBackground =
        backgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.12);
    final resolvedIconColor = iconColor ?? theme.colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: resolvedIconColor.withValues(alpha: 0.25),
        ),
      ),
      child: Icon(icon, color: resolvedIconColor, size: size * 0.5),
    );
  }
}
