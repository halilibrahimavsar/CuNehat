import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/motion/app_haptics.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/main_feature/utils/section_records.dart';
import 'package:cunehat/features/main_feature/utils/section_visibility.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Ayarlar > Bölümler: ana ekranda Birikim ve Borç bölümlerini aç/kapat.
///
/// Kaydı olan bölüm kapatılamaz; anahtar kilitli çizilir ve NEDENİ altında
/// yazar (sessizce gizlemek "kapatma nerede?" diye aratırdı). Gizli bir
/// bölümün kaydı görünen rakamları değiştirmeye devam ederdi: net durum,
/// çekmecedeki borç.
class HomeSectionsCard extends StatefulWidget {
  const HomeSectionsCard({super.key, this.sections, this.records});

  /// Testte verilir; uygulamada DI'daki tek örnekler kullanılır.
  final SectionVisibility? sections;
  final SectionRecords? records;

  @override
  State<HomeSectionsCard> createState() => _HomeSectionsCardState();
}

class _HomeSectionsCardState extends State<HomeSectionsCard> {
  late final SectionVisibility _sections =
      widget.sections ?? getIt<SectionVisibility>();
  late final SectionRecords _records =
      widget.records ?? getIt<SectionRecords>();

  @override
  void initState() {
    super.initState();
    _sections.addListener(_onChanged);
  }

  @override
  void dispose() {
    _sections.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle(SliderState section, bool value, bool hasRecords) async {
    AppHaptics.selection();
    if (value) {
      await _sections.enable(section);
    } else {
      await _sections.disable(section, hasRecords: hasRecords);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget row({
      required SliderState section,
      required String title,
      required String description,
      required bool hasRecords,
    }) {
      final enabled = _sections.isEnabled(section);
      final locked = enabled && hasRecords;
      return SwitchListTile(
        key: ValueKey('section-switch-${section.name}'),
        value: enabled,
        onChanged:
            locked ? null : (value) => _toggle(section, value, hasRecords),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(
          locked
              ? '$description\n${l10n.sectionLockedHasRecords}'
              : description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        isThreeLine: locked,
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.sectionsIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          row(
            section: SliderState.savedMoney,
            title: l10n.sectionSavingsTitle,
            description: l10n.sectionSavingsDesc,
            hasRecords: _records.savingsHasRecords,
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          row(
            section: SliderState.debt,
            title: l10n.sectionDebtTitle,
            description: l10n.sectionDebtDesc,
            hasRecords: _records.debtHasRecords,
          ),
        ],
      ),
    );
  }
}
