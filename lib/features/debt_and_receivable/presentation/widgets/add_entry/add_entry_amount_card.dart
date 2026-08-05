import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/repayment_breakdown_card.dart';
import 'package:flutter/material.dart';

/// Üst ana tutar giriş kartı ve (varsa) borç geri ödeme hesaplama özeti.
class AddEntryAmountCard extends StatelessWidget {
  final bool isDebt;
  final DebtType selectedDebtType;
  final TextEditingController amountController;
  final TextEditingController interestController;
  final TextEditingController termController;
  final TextEditingController installmentController;
  final bool isInstallmentAmortized;
  final bool isBankLoanMonthly;
  final bool includeBankTaxes;
  final Color accent;
  final VoidCallback onChanged;

  /// Kaydın ait olduğu cüzdanın para birimi. Aktif cüzdandan okumak yerine
  /// açıkça geçilir: kayıt her zaman KENDİ cüzdanının birimindedir ve
  /// `context.activeWalletCurrency` WalletBloc yoksa sessizce TRY'ye düşerdi.
  final String currency;

  const AddEntryAmountCard({
    super.key,
    required this.isDebt,
    required this.selectedDebtType,
    required this.amountController,
    required this.interestController,
    required this.termController,
    required this.installmentController,
    required this.isInstallmentAmortized,
    required this.isBankLoanMonthly,
    required this.includeBankTaxes,
    required this.accent,
    required this.onChanged,
    required this.currency,
  });

  String _title(BuildContext context) {
    if (!isDebt) return context.l10n.alacakTutari;
    return switch (selectedDebtType) {
      DebtType.bankLoan => context.l10n.krediTutariAnaPara,
      DebtType.installmentDebt ||
      DebtType.personalDebt =>
        context.l10n.toplamTutar,
      DebtType.otherDebt => context.l10n.borcTutariAnaPara,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title(context),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: TextField(
                  controller: amountController,
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [AmountInputFormatter()],
                  onChanged: (_) => onChanged(),
                  cursorColor: accent,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: accent.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  currencySymbol(currency),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: accent.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          if (isDebt && selectedDebtType != DebtType.personalDebt)
            RepaymentBreakdownCard(
              amountController: amountController,
              interestController: interestController,
              termController: termController,
              installmentController: installmentController,
              debtType: selectedDebtType,
              isInstallmentAmortized: isInstallmentAmortized,
              isBankLoanMonthly: isBankLoanMonthly,
              includeBankTaxes: includeBankTaxes,
              accent: accent,
              currency: currency,
            ),
        ],
      ),
    );
  }
}
