import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

/// Tıklanabilir, modern görünümlü ve aksiyon menülü sarmalayıcı widget.
/// Herhangi bir widget'ı (child) sarmalayarak ona "sağ tık" menüsü özelliği kazandırır.
///
/// Menü kabuğu [AppSurface] token'larından boyanır — diyaloglarla
/// (`AppDialogSurface`) ve kartlarla (`AppCard`) aynı ambiansı paylaşır.
/// (Eskiden yarı saydam sabit bir mavi kullanıyordu; tema değişince ya da
/// kart üstüne düşünce ekranın geri kalanıyla ilgisiz duruyordu.)
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
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.light;

    return PopupMenuButton<T>(
      tooltip: tooltip ?? context.l10n.secenekler,
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(surface.radius.clamp(16, 24)),
        side: BorderSide(color: surface.borderColor),
      ),
      color: menuColor ?? surface.baseColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: surface.ambientShadow.isEmpty
          ? null
          : surface.ambientShadow.first.color,
      elevation: 12,
      onSelected: onSelected,
      itemBuilder: (context) => items,
      child: child,
    );
  }
}
