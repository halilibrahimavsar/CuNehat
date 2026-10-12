import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/amount_visibility.dart';

/// "Tutarları gizle / göster" göz düğmesi — tutarın HEMEN YANINDA durur.
///
/// Eskiden üst çubuğun sağ köşesinde, tutardan ayrı bir kutudaydı: neyi
/// gizlediği ancak dokununca anlaşılıyordu ve sağ köşeyi tek başına
/// tutuyordu (kullanıcı isteği, 12 Eki 2026). Paketin `AmountVisibilityButton`'ı
/// kullanılmıyor: ipucu metni İngilizce sabit ve boyutu ayarlanamıyor.
///
/// Görünürlük cubit'i sağlanmamış ağaçta (yalıtılmış testler) yer tutar ama
/// düğme çizmez — gizlilik hiçbir akışı kırmamalı.
class AmountEyeButton extends StatelessWidget {
  const AmountEyeButton({
    super.key,
    this.extent = 36,
    this.iconSize = 20,
    this.color = Colors.white,
  });

  /// Dokunma hedefinin kenarı.
  final double extent;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AmountVisibilityCubit cubit;
    try {
      cubit = context.watch<AmountVisibilityCubit>();
    } on ProviderNotFoundException {
      return SizedBox(width: extent, height: extent);
    }
    final visible = cubit.state;
    return SizedBox(
      width: extent,
      height: extent,
      child: IconButton(
        key: const ValueKey('amount-eye'),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: extent, height: extent),
        iconSize: iconSize,
        color: color.withValues(alpha: visible ? 0.9 : 0.65),
        tooltip: visible
            ? context.l10n.tutarlariGizle
            : context.l10n.tutarlariGoster,
        onPressed: cubit.toggleVisibility,
        icon: Icon(
          visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
        ),
      ),
    );
  }
}
