// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

/// Tıklanabilir, modern görünümlü ve aksiyon menülü sarmalayıcı widget.
/// Herhangi bir widget'ı (child) sarmalayarak ona "sağ tık" menüsü özelliği kazandırır.
class InfoActionMenu<T> extends StatelessWidget {
  final Widget child;
  final List<PopupMenuEntry<T>> items;
  final void Function(T) onSelected;
  final String? tooltip;
  final Color? menuColor;

  const InfoActionMenu({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
    this.tooltip,
    this.menuColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip ?? 'Seçenekler',
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      color: menuColor ??
          const Color.fromARGB(132, 0, 98, 255), // Modern koyu arka plan
      elevation: 16,
      onSelected: onSelected,
      itemBuilder: (context) => items,
      child: child,
    );
  }
}

/// Rozet (Badge) ve Animasyonlu Değer gösteren modern bilgi ekranı.
/// Örn: Cüzdan Adı + Bakiye, Gider Başlığı + Tutar vb.
class AnimatedInfoDisplay extends StatelessWidget {
  final String label;
  final double value;
  final String currencySymbol;
  final IconData icon;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;

  const AnimatedInfoDisplay({
    super.key,
    required this.label,
    required this.value,
    this.currencySymbol = '₺',
    this.icon = Icons.wallet,
    this.valueStyle,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Label Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: labelStyle ??
                      TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Value with Animation
        TweenAnimationBuilder<double>(
          tween: Tween(
            begin: 0,
            end: value,
          ),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutExpo,
          builder: (context, value, child) {
            return Text(
              context.l10n.valueTostringasfixedCurrencysymbol(value.toStringAsFixed(2), currencySymbol),
              style: valueStyle ??
                  const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    shadows: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
            );
          },
        ),
      ],
    );
  }
}
