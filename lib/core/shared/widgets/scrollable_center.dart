import 'package:flutter/material.dart';

/// Yer varsa ortada duran, yer yoksa kaydırılan içerik — sabit yükseklikli bir
/// alana konan boş durumlar için.
///
/// `Center` içinde bir `Column` kısa ekranda (568dp + büyük yazı, altta
/// kaydırıcı) sığmadığında alttan taşıyordu: boş durum kartının açıklaması
/// ve düğmesi görünmüyordu.
class ScrollableCenter extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ScrollableCenter({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? (constraints.maxHeight - padding.vertical)
                    .clamp(0, double.infinity)
                : 0,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
