import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/debt_repayment_calculator.dart';
import 'package:flutter/material.dart';

/// Canlı faiz, taksit ve toplam geri ödeme tutarlarını listeleyen özet kartı.
class RepaymentBreakdownCard extends StatelessWidget {
  static const _calc = DebtRepaymentCalculator();

  final TextEditingController amountController;
  final TextEditingController interestController;
  final TextEditingController termController;
  final TextEditingController installmentController;
  final DebtType debtType;
  final bool isInstallmentAmortized;
  final bool isBankLoanMonthly;
  final bool includeBankTaxes;
  final Color accent;

  /// Kaydın ait olduğu cüzdanın para birimi; hesaplama birimden bağımsızdır,
  /// yalnız gösterim bunu kullanır.
  final String currency;

  const RepaymentBreakdownCard({
    super.key,
    required this.amountController,
    required this.interestController,
    required this.termController,
    required this.installmentController,
    required this.debtType,
    required this.isInstallmentAmortized,
    required this.isBankLoanMonthly,
    required this.includeBankTaxes,
    required this.accent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([
        amountController,
        interestController,
        termController,
        installmentController,
      ]),
      builder: (context, _) {
        final principal = parseMoneyInput(amountController.text) ?? 0;
        final term = int.tryParse(termController.text.trim()) ?? 0;
        final hasData = principal > 0;

        final breakdown = _calc.compute(
          type: debtType,
          principal: principal,
          termMonths: term,
          interestRate: parseAmountInput(interestController.text) ?? 0,
          monthlyInstallment: parseMoneyInput(installmentController.text) ?? 0,
          isInstallmentAmortized: isInstallmentAmortized,
          isBankLoanMonthly: isBankLoanMonthly,
          includeBankTaxes: includeBankTaxes,
        );
        final total = breakdown.expectedTotal;
        final monthly = breakdown.monthlyPayment;
        final totalInterest = breakdown.totalInterest;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: accent.withValues(alpha: 0.20)),
            ),
            _SummaryRow(
              label: debtType == DebtType.installmentDebt &&
                      !isInstallmentAmortized
                  ? context.l10n.vadeFarkiLabel
                  : context.l10n.toplamFaizLabel,
              value: hasData
                  ? '+ ${formatMoney(totalInterest, currency: currency)}'
                  : '—',
            ),
            if (term > 0) ...[
              const SizedBox(height: 8),
              _SummaryRow(
                label: context.l10n.aylikTaksitLabel,
                value: hasData ? formatMoney(monthly, currency: currency) : '—',
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  context.l10n.toplamGeriOdeme,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  hasData ? formatMoney(total, currency: currency) : '—',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: accent,
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
