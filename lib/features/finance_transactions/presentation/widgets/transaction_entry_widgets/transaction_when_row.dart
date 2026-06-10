// transaction_form_fields.dart'tan bölündü (v1 temizliği): davranış aynı.
import 'package:flutter/material.dart';
import 'package:cunehat/core/constants/app_constants.dart';
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
      firstDate: DateTime(2020),
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.dateTime,
      builder: (context, when, _) {
        return Row(
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
        );
      },
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 13,
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
