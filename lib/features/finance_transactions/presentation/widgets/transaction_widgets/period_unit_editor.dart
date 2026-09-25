import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/features/finance_transactions/domain/period_preferences.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dönem birimi düzenleyicisi: Gün · Hafta · 2 Hafta · Ay + birimin
/// başlangıç ayarı + "Bu dönem: …" önizlemesi.
///
/// Dönem sayfasında ([pickSharedPeriod]) ve Ayarlar'da aynı bileşen: bir
/// ayarın iki yerde iki farklı biçimde düzenlenmesi, hangisinin geçerli
/// olduğunu sorgulatır.
class PeriodUnitEditor extends StatelessWidget {
  final PeriodPreferences value;
  final ValueChanged<PeriodPreferences> onChanged;

  const PeriodUnitEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = AppMotion.of(context);
    final hintStyle = theme.textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.85));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledSegment<PeriodUnit>(
          selected: value.unit,
          onChanged: (u) => onChanged(value.copyWith(unit: u)),
          items: [
            SegmentItem(
                value: PeriodUnit.day,
                label: l10n.periodUnitDay,
                color: AppGradients.transactions),
            SegmentItem(
                value: PeriodUnit.week,
                label: l10n.periodUnitWeek,
                color: AppGradients.transactions),
            SegmentItem(
                value: PeriodUnit.biweek,
                label: l10n.periodUnitBiweek,
                color: AppGradients.transactions),
            SegmentItem(
                value: PeriodUnit.month,
                label: l10n.periodUnitMonth,
                color: AppGradients.transactions),
          ],
        ),
        // Birimin başlangıç ayarı yumuşakça açılır; gün biriminde yoktur.
        AnimatedSize(
          duration: motion.d(AppMotion.medium),
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: switch (value.unit) {
            PeriodUnit.day => const SizedBox(width: double.infinity),
            PeriodUnit.week => _WeekStart(value: value, onChanged: onChanged),
            PeriodUnit.biweek =>
              _BiweekAnchor(value: value, onChanged: onChanged),
            PeriodUnit.month =>
              _MonthStart(value: value, onChanged: onChanged),
          },
        ),
        const SizedBox(height: 10),
        Text(
          l10n.periodCurrentPreview(
              periodLabel(value.periodContaining(DateTime.now()), l10n)),
          key: const ValueKey('period-preview'),
          style: hintStyle?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _WeekStart extends StatelessWidget {
  final PeriodPreferences value;
  final ValueChanged<PeriodPreferences> onChanged;

  const _WeekStart({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    // 1 Ocak 2024 Pazartesi: gün adları yerelin kısa biçiminden.
    final names = DateFormat.E(locale);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.periodWeekStartLabel,
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++)
                ChoiceChip(
                  key: ValueKey('week-start-$wd'),
                  label: Text(names.format(DateTime(2024, 1, wd))),
                  selected: value.weekStart == wd,
                  onSelected: (_) => onChanged(value.copyWith(weekStart: wd)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BiweekAnchor extends StatelessWidget {
  final PeriodPreferences value;
  final ValueChanged<PeriodPreferences> onChanged;

  const _BiweekAnchor({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final anchor = value.periodContaining(DateTime.now()).start;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            key: const ValueKey('biweek-anchor'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.payments_rounded),
            title: Text(l10n.periodBiweekAnchorLabel),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value.biweekAnchor ?? anchor,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  onChanged(value.copyWith(biweekAnchor: picked));
                }
              },
              child: Text(value.biweekAnchor == null
                  ? l10n.periodChooseDate
                  : DateFormat.yMMMd(locale).format(value.biweekAnchor!)),
            ),
          ),
          Text(
            l10n.periodBiweekHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MonthStart extends StatelessWidget {
  final PeriodPreferences value;
  final ValueChanged<PeriodPreferences> onChanged;

  const _MonthStart({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.periodMonthStartLabel,
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              DropdownButton<int>(
                key: const ValueKey('month-start-day'),
                value: value.monthStartDay,
                onChanged: (d) {
                  if (d != null) onChanged(value.copyWith(monthStartDay: d));
                },
                items: [
                  for (var d = 1; d <= 28; d++)
                    DropdownMenuItem(value: d, child: Text('$d')),
                ],
              ),
            ],
          ),
          Text(
            l10n.periodMonthStartHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
