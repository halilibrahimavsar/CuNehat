// transaction_form_fields.dart'tan bölündü (v1 temizliği): davranış aynı.
import 'package:flutter/material.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';

// ============================================================ Date & time

class WhenRow extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;

  const WhenRow({super.key, required this.controller, required this.accent});

  Future<void> _pickDate(BuildContext context) async {
    final current = controller.dateTime.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: kEarliestEntryDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.dateTime.value = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final current = controller.dateTime.value;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked != null) {
      controller.dateTime.value = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
    }
  }

  /// Günü [daysAgo] gün önceye çeker; saat korunur.
  void _setDay(int daysAgo) {
    final current = controller.dateTime.value;
    final day = DateTime.now().subtract(Duration(days: daysAgo));
    controller.dateTime.value = DateTime(
      day.year,
      day.month,
      day.day,
      current.hour,
      current.minute,
    );
  }

  static bool _isDaysAgo(DateTime when, int daysAgo) {
    final day = DateTime.now().subtract(Duration(days: daysAgo));
    return when.year == day.year &&
        when.month == day.month &&
        when.day == day.day;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.dateTime,
      builder: (context, when, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En sık iki gün tek dokunuş: "dün" için eskiden hap → takvim →
            // gün → Tamam gerekiyordu. Seçili çip aynı zamanda formun bugüne
            // ayarlı olduğunu söyler (eski ipucu satırının işi).
            Row(
              children: [
                _DayChip(
                  key: const ValueKey('tx-day-today'),
                  label: context.l10n.bugun,
                  selected: _isDaysAgo(when, 0),
                  accent: accent,
                  onTap: () => _setDay(0),
                ),
                const SizedBox(width: 8),
                _DayChip(
                  key: const ValueKey('tx-day-yesterday'),
                  label: context.l10n.dun,
                  selected: _isDaysAgo(when, 1),
                  accent: accent,
                  onTap: () => _setDay(1),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _WhenPill(
                    icon: Icons.calendar_today_rounded,
                    label: AppFormatters.dateLong.format(when),
                    accent: accent,
                    onTap: () => _pickDate(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WhenPill(
                    icon: Icons.schedule_rounded,
                    label: AppFormatters.time.format(when),
                    accent: accent,
                    onTap: () => _pickTime(context),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// "Bugün" / "Dün" kısayolu.
class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _DayChip({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(12));
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.12)
            : cs.onSurface.withValues(alpha: 0.04),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? accent : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WhenPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _WhenPill({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
