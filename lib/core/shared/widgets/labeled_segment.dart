import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Bir [LabeledSegment] hücresi.
@immutable
class SegmentItem<T> {
  final T value;
  final String label;

  /// Seçiliyken göstergenin rengi; verilmezse temanın birincil rengi.
  final Color? color;

  const SegmentItem({required this.value, required this.label, this.color});
}

/// Metin ETİKETLİ, kayan göstergeli segment seçici.
///
/// İkon-yalnız eski mod segmentinin (↗ ⇄ ↘) anlamı yalnız ipucu metnindeydi;
/// kullanıcı hangi ikonun neyi süzdüğünü denemeden bilemiyordu. Bu bileşen
/// etiketi hücrenin kendisine yazar. İki kullanım:
///  • İşlemler · İçgörü · Rapor sekme şeridi ([asTabs] = true: ekran okuyucu
///    "sekme, 3'ün 2'si, seçili" okur),
///  • Rapor'un kategori modu (Gider · Gelir · İkisi).
///
/// Hücre yüksekliği [height] (en az 40); dokunma alanı hücrenin tamamıdır.
/// Etiket sığmazsa KÜÇÜLÜR (`scaleDown`), satır atlamaz ve kırpılmaz.
class LabeledSegment<T> extends StatelessWidget {
  final List<SegmentItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;
  final bool asTabs;

  const LabeledSegment({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.height = 40,
    this.asTabs = false,
  }) : assert(height >= 40, 'dokunma hedefi 40dp altına inmemeli');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motion = AppMotion.of(context);
    final index = items.indexWhere((i) => i.value == selected);
    final accent = (index >= 0 ? items[index].color : null) ?? scheme.primary;

    final segment = Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / items.length;
          return Stack(
            children: [
              if (index >= 0)
                AnimatedPositioned(
                  duration: motion.d(AppMotion.medium),
                  curve: AppMotion.standard,
                  left: index * cell,
                  top: 0,
                  bottom: 0,
                  width: cell,
                  child: AnimatedContainer(
                    duration: motion.d(AppMotion.medium),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _Cell(
                        label: items[i].label,
                        selected: i == index,
                        onTap: () => onChanged(items[i].value),
                        asTab: asTabs,
                        motion: motion,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return asTabs
        ? Semantics(role: SemanticsRole.tabBar, container: true, child: segment)
        : segment;
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool asTab;
  final AppMotion motion;

  const _Cell({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.asTab,
    required this.motion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      role: asTab ? SemanticsRole.tab : null,
      button: !asTab,
      selected: selected,
      label: label,
      // Eylem burada: `excludeSemantics` alt ağacı (InkWell'in eylemi dahil)
      // dışarıda bırakır. Sekme rolü bir dokunma eylemi İSTER.
      onTap: selected ? () {} : onTap,
      excludeSemantics: true,
      child: InkWell(
        // Seçili hücre de DOKUNULABİLİR kalır (etkisiz): ekran okuyucuda
        // sekme rolü bir dokunma eylemi ister, yoksa seçili sekme "devre
        // dışı" gibi okunur (Flutter bunu assert ile yakalar).
        onTap: selected ? () {} : onTap,
        borderRadius: BorderRadius.circular(11),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: motion.d(AppMotion.short),
                style: theme.textTheme.labelLarge!.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : scheme.onSurfaceVariant,
                ),
                child: Text(label, maxLines: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
