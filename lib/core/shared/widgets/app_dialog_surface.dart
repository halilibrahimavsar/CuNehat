import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:flutter/material.dart';

/// Uygulamanın AppSurface görsel diline (blur'suz, düz yüzey) uyan paylaşılan
/// diyalog kabuğu. Onay ([ConfirmDialog]) ve bilgi diyalogları bunun üstüne
/// kurulur — böylece tüm diyaloglar aynı ambiansı paylaşır ve glassmorphism
/// (IboDialog) görünümünden ayrışır.
class AppDialogSurface extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AppDialogSurface({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.light;
    // Dar ekranda kenar boşlukları küçülür: varsayılan 40dp yatay pay +
    // 20dp iç dolgu 320dp'lik telefonda içeriğe ~200dp bırakıyordu; iki
    // düğme yan yana sığmıyor, alt alta dizilince klavyeyle birlikte metin
    // alanı eziliyordu.
    final narrow = MediaQuery.sizeOf(context).width < 360;

    return Dialog(
      insetPadding: narrow
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
          : null,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface.baseColor,
            borderRadius: BorderRadius.circular(surface.radius),
            border: Border.all(color: surface.borderColor),
            boxShadow: surface.ambientShadow,
          ),
          child: Padding(
            padding: EdgeInsets.all(narrow ? 16 : 20),
            child: child,
          ),
        ),
      ),
    );
  }
}
