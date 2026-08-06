import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:flutter/material.dart';

/// Borç/alacak ekleme sayfasının (add_entry_sheet) form parçaları. Tek
/// kullanımlık ama büyük build metotlarını sayfadan ayırıp sayfayı
/// okunabilir tutmak için buraya taşındı. Hepsi durumsuzdur; değeri ve
/// değişiklik callback'ini parametre alır. [accent] borç=rose / alacak=emerald.

/// Borç türü seçim çipleri (banka kredisi / taksitli / kişisel / diğer).
class DebtTypeChips extends StatelessWidget {
  final DebtType selected;
  final Color accent;
  final ValueChanged<DebtType> onSelected;

  const DebtTypeChips({
    super.key,
    required this.selected,
    required this.accent,
    required this.onSelected,
  });

  static const Map<DebtType, IconData> _icons = {
    DebtType.bankLoan: Icons.account_balance_rounded,
    DebtType.installmentDebt: Icons.credit_card_rounded,
    DebtType.personalDebt: Icons.handshake_rounded,
    DebtType.otherDebt: Icons.more_horiz_rounded,
  };

  String _label(BuildContext context, DebtType type) => switch (type) {
        DebtType.bankLoan => context.l10n.debtTypeBankLoan,
        DebtType.installmentDebt => context.l10n.debtTypeInstallment,
        DebtType.personalDebt => context.l10n.debtTypePersonal,
        DebtType.otherDebt => context.l10n.debtTypeOther,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DebtType.values.map((type) {
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onSelected(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.12)
                  : cs.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icons[type]!,
                    size: 17, color: isSelected ? accent : cs.onSurfaceVariant),
                const SizedBox(width: 7),
                Text(
                  _label(context, type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? accent : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// İki seçenekli segment kontrolü (sol/sağ). Banka kredisi ve taksit
/// modu seçicileri aynı yapıyı paylaşır.
class _SegmentedToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final Color accent;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _SegmentedToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.accent,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _segment(cs, leftLabel, leftSelected, onLeft),
          _segment(cs, rightLabel, !leftSelected, onRight),
        ],
      ),
    );
  }

  Widget _segment(
      ColorScheme cs, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4)
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? accent : cs.onSurfaceVariant)),
        ),
      ),
    );
  }
}

/// Banka kredisi giriş modu: "aylık taksiti biliyorum" / "faiz oranı ile".
class BankLoanModeToggle extends StatelessWidget {
  final bool isMonthly;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const BankLoanModeToggle({
    super.key,
    required this.isMonthly,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SegmentedToggle(
      leftLabel: context.l10n.aylikTaksitiBiliyorum,
      rightLabel: context.l10n.faizOraniIle,
      leftSelected: isMonthly,
      accent: accent,
      onLeft: () => onChanged(true),
      onRight: () => onChanged(false),
    );
  }
}

/// Taksitli borç hesap modu: "eşit taksit (amortisman)" / "basit vade farkı".
class InstallmentTypeToggle extends StatelessWidget {
  final bool isAmortized;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const InstallmentTypeToggle({
    super.key,
    required this.isAmortized,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SegmentedToggle(
      leftLabel: context.l10n.esitTaksitAmortisman,
      rightLabel: context.l10n.basitVadeFarki,
      leftSelected: isAmortized,
      accent: accent,
      onLeft: () => onChanged(true),
      onRight: () => onChanged(false),
    );
  }
}

/// KKDF/BSMV vergilerini faize dahil etme anahtarı (banka kredisi, faiz modu).
class BankTaxSwitch extends StatelessWidget {
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const BankTaxSwitch({
    super.key,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.kKDFVeBsmvVergilerini,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.tuketiciKredilerindeFaizeYasal,
            style: TextStyle(
                fontSize: 11.5, color: cs.onSurfaceVariant, height: 1.3),
          ),
        ],
      ),
    );
  }
}

/// Kişisel borçta OPSİYONEL vade hapı.
///
/// Kişisel borcun taksit planı yoktur; eskiden vade sorulmadan "başlangıç + 1
/// ay" atanıyor ve kullanıcı hiç istemediği bir hatırlatma alıyordu. Boş
/// bırakılırsa vade yazılmaz, bildirim de kurulmaz.
class OptionalDueDatePill extends StatelessWidget {
  final Color accent;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const OptionalDueDatePill({
    super.key,
    required this.accent,
    required this.date,
    required this.onTap,
    required this.onClear,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              Icon(Icons.event_available_rounded, size: 18, color: accent),
              const SizedBox(width: 12),
              Text(
                context.l10n.vadeOpsiyonelLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                date == null
                    ? context.l10n.vadeSecilmedi
                    : AppFormatters.dateLong.format(date!),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: date == null
                      ? cs.onSurfaceVariant.withValues(alpha: 0.7)
                      : cs.onSurface,
                ),
              ),
              if (date != null)
                IconButton(
                  onPressed: onClear,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarih seçim hapı (borç: başlangıç tarihi / alacak: vade tarihi).
class DueDatePill extends StatelessWidget {
  final bool isDebt;
  final Color accent;
  final DateTime date;
  final VoidCallback onTap;

  const DueDatePill({
    super.key,
    required this.isDebt,
    required this.accent,
    required this.date,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: accent),
              const SizedBox(width: 12),
              Text(
                isDebt ? context.l10n.baslangicLabel : context.l10n.vadeLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                AppFormatters.dateLong.format(date),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
